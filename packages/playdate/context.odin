package playdate

import "base:intrinsics"
import "base:runtime"

NO_PLAYDATE_TEMP_ALLOCATOR :: #config(NO_PLAYDATE_TEMP_ALLOCATOR, false)

MAX_PLAYDATE_ALIGN :: 8

playdate_context_create :: proc "contextless" (api: ^Api) -> runtime.Context {
	ctx: runtime.Context

	when !ODIN_DISABLE_ASSERT {
		ctx.assertion_failure_proc = playdate_assertion_failure_proc
	}

	ctx.allocator = playdate_allocator(api)
	ctx.temp_allocator.procedure = playdate_temp_allocator_proc

	when !NO_PLAYDATE_TEMP_ALLOCATOR {
		context = ctx

		temp_alloc := new(Playdate_Temp_Allocator)
		if temp_alloc != nil {
			init_err := playdate_temp_allocator_init(
				temp_alloc,
				runtime.DEFAULT_TEMP_ALLOCATOR_BACKING_SIZE,
				ctx.allocator,
			)
			if init_err == .None {
				ctx.temp_allocator.data = temp_alloc
			} else {
				free(temp_alloc)
			}
		}
	}

	ctx.logger = playdate_logger(api)

	return ctx
}

playdate_context_destroy :: proc "contextless" (ctx: ^runtime.Context) {
	when !NO_PLAYDATE_TEMP_ALLOCATOR {
		context = ctx^
		temp_alloc := (^Playdate_Temp_Allocator)(ctx.temp_allocator.data)
		if temp_alloc != nil {
			runtime.arena_destroy(&temp_alloc.arena)
			free(temp_alloc)
			ctx.temp_allocator.data = nil
		}
	}
}

playdate_allocator :: proc "contextless" (api: ^Api) -> runtime.Allocator {
	return runtime.Allocator {
		procedure = playdate_allocator_proc,
		data = rawptr(api.system.realloc),
	}
}

Playdate_Temp_Allocator :: struct {
	arena: runtime.Arena,
}

playdate_temp_allocator_init :: proc(
	s: ^Playdate_Temp_Allocator,
	size: int,
	backing_allocator := context.allocator,
) -> runtime.Allocator_Error {
	return runtime.arena_init(&s.arena, uint(size), backing_allocator)
}

playdate_temp_allocator_destroy :: proc(s: ^Playdate_Temp_Allocator) {
	if s != nil {
		runtime.arena_destroy(&s.arena)
		s^ = {}
	}
}

playdate_temp_allocator_proc :: proc(
	allocator_data: rawptr,
	mode: runtime.Allocator_Mode,
	size, alignment: int,
	old_memory: rawptr,
	old_size: int,
	loc := #caller_location,
) -> (
	data: []byte,
	err: runtime.Allocator_Error,
) {
	s := (^Playdate_Temp_Allocator)(allocator_data)
	return runtime.arena_allocator_proc(&s.arena, mode, size, alignment, old_memory, old_size, loc)
}

@(require_results)
playdate_temp_allocator_temp_begin :: proc(
	allocator := context.temp_allocator,
	loc := #caller_location,
) -> (
	temp: runtime.Arena_Temp,
) {
	temp_alloc := (^Playdate_Temp_Allocator)(allocator.data)
	temp = runtime.arena_temp_begin(&temp_alloc.arena, loc)
	return
}

playdate_temp_allocator_temp_end :: proc(temp: runtime.Arena_Temp, loc := #caller_location) {
	runtime.arena_temp_end(temp, loc)
}

playdate_temp_allocator :: proc "contextless" (
	allocator: ^Playdate_Temp_Allocator,
) -> runtime.Allocator {
	return runtime.Allocator{procedure = playdate_temp_allocator_proc, data = allocator}
}

playdate_logger :: proc "contextless" (api: ^Api) -> runtime.Logger {
	return runtime.Logger {
		procedure = playdate_logger_proc,
		data = rawptr(api.system),
		lowest_level = .Debug,
		options = {.Level},
	}
}

@(private)
align_forward :: proc "contextless" (ptr: rawptr, align: uintptr) -> rawptr {
	p := uintptr(ptr)
	mod := p % align
	if mod != 0 {
		p += align - mod
	}
	return rawptr(p)
}

playdate_allocator_proc :: proc(
	allocator_data: rawptr,
	mode: runtime.Allocator_Mode,
	size, alignment: int,
	old_memory: rawptr,
	old_size: int,
	loc := #caller_location,
) -> (
	data: []byte,
	err: runtime.Allocator_Error,
) {
	realloc_proc :: #type proc "c" (ptr: rawptr, size: u32) -> [^]byte
	realloc := realloc_proc(allocator_data)

	switch mode {
	case .Alloc, .Alloc_Non_Zeroed:
		if size == 0 {
			return nil, .None
		}

		if alignment > MAX_PLAYDATE_ALIGN {
			extra := alignment + size_of(rawptr)
			ptr := realloc(nil, u32(size + extra))
			if ptr == nil {
				return nil, .Out_Of_Memory
			}
			aligned := align_forward(rawptr(uintptr(ptr) + size_of(rawptr)), uintptr(alignment))
			(^^rawptr)(uintptr(aligned) - size_of(rawptr))^ = (^rawptr)(ptr)
			data = ([^]byte)(aligned)[:size]
		} else {
			ptr := realloc(nil, u32(size))
			if ptr == nil {
				return nil, .Out_Of_Memory
			}
			data = ptr[:size]
		}

		if mode == .Alloc {
			intrinsics.mem_zero(raw_data(data), size)
		}

	case .Free:
		if old_memory == nil {
			return nil, .None
		}
		if alignment > MAX_PLAYDATE_ALIGN {
			raw := (^^rawptr)(uintptr(old_memory) - size_of(rawptr))^
			_ = realloc(raw, 0)
		} else {
			_ = realloc(old_memory, 0)
		}
		return nil, .None

	case .Free_All:
		return nil, .Mode_Not_Implemented

	case .Resize, .Resize_Non_Zeroed:
		if size == 0 {
			if old_memory != nil {
				if alignment > MAX_PLAYDATE_ALIGN {
					raw := (^^rawptr)(uintptr(old_memory) - size_of(rawptr))^
					_ = realloc(raw, 0)
				} else {
					_ = realloc(old_memory, 0)
				}
			}
			return nil, .None
		}

		if alignment > MAX_PLAYDATE_ALIGN {
			extra := alignment + size_of(rawptr)
			ptr := realloc(nil, u32(size + extra))
			if ptr == nil {
				return nil, .Out_Of_Memory
			}
			aligned := align_forward(rawptr(uintptr(ptr) + size_of(rawptr)), uintptr(alignment))
			(^^rawptr)(uintptr(aligned) - size_of(rawptr))^ = (^rawptr)(ptr)
			data = ([^]byte)(aligned)[:size]

			copy_size := min(size, old_size)
			if copy_size > 0 && old_memory != nil {
				intrinsics.mem_copy(raw_data(data), old_memory, copy_size)
			}
			if mode == .Resize && size > old_size {
				intrinsics.mem_zero(raw_data(data[old_size:]), size - old_size)
			}

			if old_memory != nil {
				raw := (^^rawptr)(uintptr(old_memory) - size_of(rawptr))^
				_ = realloc(raw, 0)
			}
		} else {
			ptr := realloc(old_memory, u32(size))
			if ptr == nil {
				return nil, .Out_Of_Memory
			}
			data = ptr[:size]
			if mode == .Resize && size > old_size {
				intrinsics.mem_zero(raw_data(data[old_size:]), size - old_size)
			}
		}

	case .Query_Features:
		set := (^runtime.Allocator_Mode_Set)(old_memory)
		if set != nil {
			set^ = {.Alloc, .Alloc_Non_Zeroed, .Free, .Resize, .Resize_Non_Zeroed, .Query_Features}
		}
		return nil, .None

	case .Query_Info:
		return nil, .Mode_Not_Implemented

	case:
		return nil, .Mode_Not_Implemented
	}

	return
}

playdate_logger_proc :: proc(
	logger_data: rawptr,
	level: runtime.Logger_Level,
	text: string,
	options: runtime.Logger_Options,
	location := #caller_location,
) {
	system := (^Api_System_Procs)(logger_data)

	level_str: string
	switch level {
	case .Debug:
		level_str = "DEBUG"
	case .Info:
		level_str = "INFO"
	case .Warning:
		level_str = "WARNING"
	case .Error:
		level_str = "ERROR"
	case .Fatal:
		level_str = "FATAL"
	}

	buf: [1024]byte
	n := 0
	if .Level in options {
		n += copy(buf[n:], "[")
		n += copy(buf[n:], level_str)
		n += copy(buf[n:], "] ")
	}
	n += copy(buf[n:], text)
	buf[n] = 0
	output_cstr := cstring(&buf[0])

	switch level {
	case .Debug, .Info, .Warning:
		system.log_to_console(output_cstr)
	case .Error, .Fatal:
		system.error(output_cstr)
	}
}

playdate_assertion_failure_proc :: proc(
	prefix, message: string,
	loc: runtime.Source_Code_Location,
) -> ! {
	system := (^Api_System_Procs)(context.logger.data)
	if system != nil {
		buf: [1024]byte
		n := 0
		if len(prefix) > 0 {
			n += copy(buf[n:], prefix)
			n += copy(buf[n:], ": ")
		}
		n += copy(buf[n:], message)
		buf[n] = 0
		system.error(cstring(&buf[0]))
	}
	runtime.trap()
}

