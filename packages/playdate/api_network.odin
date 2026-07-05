package playdate

import "core:c"

PDNet_Err :: enum c.int {
	OK                  = 0,
	No_Device           = -1,
	Busy                = -2,
	Write_Error         = -3,
	Write_Busy          = -4,
	Write_Timeout       = -5,
	Read_Error          = -6,
	Read_Busy           = -7,
	Read_Timeout        = -8,
	Read_Overflow       = -9,
	Frame_Error         = -10,
	Bad_Response        = -11,
	Error_Response      = -12,
	Reset_Timeout       = -13,
	Buffer_Too_Small    = -14,
	Unexpected_Response = -15,
	Not_Connected_To_AP = -16,
	Not_Implemented     = -17,
	Connection_Closed   = -18,
}

Wifi_Status :: enum {
	Not_Connected = 0,
	Connected,
	Not_Available,
}

HTTP_Connection_Callback :: #type proc "c" (connection: ^HTTP_Connection)
HTTP_Header_Callback :: #type proc "c" (conn: ^HTTP_Connection, key, value: cstring)

TCP_Connection_Callback :: #type proc "c" (connection: ^TCP_Connection, err: PDNet_Err)
TCP_Open_Callback :: #type proc "c" (conn: ^TCP_Connection, err: PDNet_Err, ud: rawptr)

// =================================================================

Api_HTTP_Procs :: struct {
	request_access:                 proc "c" (
		server: cstring,
		port: c.int,
		usessl: b32,
		purpose: cstring,
		request_callback: Access_Request_Callback,
		userdata: rawptr,
	) -> Access_Reply,
	new_connection:                 proc "c" (
		server: cstring,
		port: c.int,
		usessl: b32,
	) -> ^HTTP_Connection,
	retain:                         proc "c" (http: ^HTTP_Connection) -> ^HTTP_Connection,
	release:                        proc "c" (http: ^HTTP_Connection),
	set_connect_timeout:            proc "c" (connection: ^HTTP_Connection, ms: c.int),
	set_keep_alive:                 proc "c" (connection: ^HTTP_Connection, keepalive: b32),
	set_byte_range:                 proc "c" (connection: ^HTTP_Connection, start, end: c.int),
	set_userdata:                   proc "c" (connection: ^HTTP_Connection, userdata: rawptr),
	get_userdata:                   proc "c" (connection: ^HTTP_Connection) -> rawptr,
	get:                            proc "c" (
		conn: ^HTTP_Connection,
		path, headers: cstring,
		headerlen: c.size_t,
	) -> PDNet_Err,
	post:                           proc "c" (
		conn: ^HTTP_Connection,
		path, headers: cstring,
		headerlen: c.size_t,
		body: cstring,
		bodylen: c.size_t,
	) -> PDNet_Err,
	query:                          proc "c" (
		conn: ^HTTP_Connection,
		method, path, headers: cstring,
		headerlen: c.size_t,
		body: cstring,
		bodylen: c.size_t,
	) -> PDNet_Err,
	get_error:                      proc "c" (connection: ^HTTP_Connection) -> PDNet_Err,
	get_progress:                   proc "c" (conn: ^HTTP_Connection, read, total: ^c.int),
	get_response_status:            proc "c" (connection: ^HTTP_Connection) -> c.int,
	get_bytes_available:            proc "c" (conn: ^HTTP_Connection) -> c.size_t,
	set_read_timeout:               proc "c" (conn: ^HTTP_Connection, ms: c.int),
	set_read_buffer_size:           proc "c" (conn: ^HTTP_Connection, bytes: c.int),
	read:                           proc "c" (
		conn: ^HTTP_Connection,
		buf: rawptr,
		buflen: c.uint,
	) -> c.int,
	close:                          proc "c" (connection: ^HTTP_Connection),
	set_header_received_callback:   proc "c" (
		connection: ^HTTP_Connection,
		headercb: HTTP_Header_Callback,
	),
	set_headers_read_callback:      proc "c" (
		connection: ^HTTP_Connection,
		callback: HTTP_Connection_Callback,
	),
	set_response_callback:          proc "c" (
		connection: ^HTTP_Connection,
		callback: HTTP_Connection_Callback,
	),
	set_request_complete_callback:  proc "c" (
		connection: ^HTTP_Connection,
		callback: HTTP_Connection_Callback,
	),
	set_connection_closed_callback: proc "c" (
		connection: ^HTTP_Connection,
		callback: HTTP_Connection_Callback,
	),
}

// =================================================================

Api_TCP_Procs :: struct {
	request_access:                 proc "c" (
		server: cstring,
		port: c.int,
		usessl: b32,
		purpose: cstring,
		request_callback: Access_Request_Callback,
		userdata: rawptr,
	) -> Access_Reply,
	new_connection:                 proc "c" (
		server: cstring,
		port: c.int,
		usessl: b32,
	) -> ^TCP_Connection,
	retain:                         proc "c" (http: ^TCP_Connection) -> ^TCP_Connection,
	release:                        proc "c" (http: ^TCP_Connection),
	get_error:                      proc "c" (connection: ^TCP_Connection) -> PDNet_Err,
	set_connect_timeout:            proc "c" (connection: ^TCP_Connection, ms: c.int),
	set_userdata:                   proc "c" (connection: ^TCP_Connection, userdata: rawptr),
	get_userdata:                   proc "c" (connection: ^TCP_Connection) -> rawptr,
	open:                           proc "c" (
		conn: ^TCP_Connection,
		cb: TCP_Open_Callback,
		ud: rawptr,
	) -> PDNet_Err,
	close:                          proc "c" (conn: ^TCP_Connection) -> PDNet_Err,
	set_connection_closed_callback: proc "c" (
		conn: ^TCP_Connection,
		callback: TCP_Connection_Callback,
	),
	set_read_timeout:               proc "c" (conn: ^TCP_Connection, ms: c.int),
	set_read_buffer_size:           proc "c" (conn: ^TCP_Connection, bytes: c.int),
	get_bytes_available:            proc "c" (conn: ^TCP_Connection) -> c.size_t,
	read:                           proc "c" (
		conn: ^TCP_Connection,
		buffer: rawptr,
		length: c.size_t,
	) -> c.int,
	write:                          proc "c" (
		conn: ^TCP_Connection,
		buffer: rawptr,
		length: c.size_t,
	) -> c.int,
}

// =================================================================

Api_Network_Procs :: struct {
	http:        ^Api_HTTP_Procs,
	tcp:         ^Api_TCP_Procs,
	get_status:  proc "c" () -> Wifi_Status,
	set_enabled: proc "c" (flag: b32, callback: proc "c" (err: PDNet_Err)),
	reserved:    [3]uintptr,
}

// =================================================================

