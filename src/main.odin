package game

import pd "../packages/playdate-api"
import "base:runtime"
import "core:fmt"
import "core:math"
import str "core:strings"

pd_api: ^pd.Api
global_ctx: runtime.Context
logo: ^pd.Sprite
logo_w :: 105
logo_h :: 31
logo_x: f32 = 195
logo_y: f32 = 120

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
	pd_api.graphics.set_background_color(.Black)

	logo = pd_api.sprite.new_sprite()
	bounds_x := logo_x - (logo_w / 2)
	bounds_y := logo_y - (logo_h / 2)

	pd_api.sprite.set_bounds(logo, pd.PDRect{bounds_x, bounds_y, logo_w, logo_h})
	out_err: cstring
	image := pd_api.graphics.load_bitmap("assets/bitmaps/logo.png", &out_err)
	if out_err != nil {
		message := str.clone_to_cstring(fmt.tprintf("error: %s", out_err))
		pd_api.system.log_to_console(message)
	}

	pd_api.sprite.set_image(logo, image, .Unflipped)
	pd_api.sprite.add_sprite(logo)
}

game_update :: proc() {
	pd_api.graphics.clear(pd.color_solid(pd.Solid_Color.Black))

	t := pd_api.system.get_elapsed_time()
	offset := math.sin(t * 2.0) * 60.0
	pd_api.sprite.move_to(logo, logo_x, logo_y + offset)
	pd_api.sprite.update_and_draw_sprites()
}

