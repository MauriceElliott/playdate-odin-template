package game

import pd "../packages/playdate"
import "base:runtime"
import "core:fmt"
import "core:math"
import str "core:strings"
import "core:time"

pd_api: ^pd.Api
global_ctx: runtime.Context
logo: ^pd.Sprite
logo_w :: 105
logo_h :: 31
logo_x: f32 = 200
logo_y: f32 = 70
start_time: time.Time

@(export)
eventHandler :: proc "c" (api: ^pd.Api, event: pd.System_Event, arg: u32) -> i32 {
	#partial switch event {
	case .Init:
		pd_api = api
		global_ctx = pd.playdate_context_create(api)
		context = global_ctx
		game_init()
		api.system.set_update_callback(update_callback, api)
	}
	return 0
}

update_callback :: proc "c" (userdata: rawptr) -> pd.Update_Result {
	context = global_ctx
	game_update()
	return .Update_Display
}

game_init :: proc() {
	start_time = time.now()
	logo = pd_api.sprite.new_sprite()
	bounds_x := logo_x - (logo_w / 2)
	bounds_y := logo_y - (logo_h / 2)

	pd_api.sprite.set_bounds(logo, pd.PDRect{bounds_x, bounds_y, logo_w, logo_h})
	out_err: cstring
	image := pd_api.graphics.load_bitmap("assets/bitmaps/logov2.png", &out_err)
	pd_api.sprite.set_image(logo, image, .Unflipped)
	pd_api.sprite.add_sprite(logo)
}

game_update :: proc() {
	sin_time := f32(time.duration_seconds(time.since(start_time)) * 4)
	log := fmt.aprintf("%f", sin_time)

	pd_api.system.log_to_console(str.clone_to_cstring(log))
	pd_api.sprite.move_by(logo, 0, (math.sin(sin_time) * 4))
	pd_api.sprite.update_and_draw_sprites()
}

