package playdate

import "core:c"

Api :: struct {
	system:      ^Api_System_Procs,
	file:        ^Api_File_Procs,
	graphics:    ^Api_Graphics_Procs,
	sprite:      ^Api_Sprite_Procs,
	display:     ^Api_Display_Procs,
	sound:       ^Api_Sound_Procs,
	lua:         ^Api_Lua_Procs,
	json:        ^Api_Json_Procs,
	scoreboards: ^Api_Scoreboards_Procs,
	network:     ^Api_Network_Procs,
}

LCD_COLUMNS: i32 : 400
LCD_ROWS: i32 : 240
LCD_ROWSIZE: i32 : 52
LCD_SCREEN_RECT :: Rect{0, 0, LCD_COLUMNS, LCD_ROWS}

Rect :: struct {
	left:   i32,
	right:  i32,
	top:    i32,
	bottom: i32,
}

Bitmap_Flip :: enum {
	Unflipped,
	Flipped_X,
	Flipped_Y,
	Flipped_XY,
}

Bitmap_Draw_Mode :: enum {
	Copy,
	White_Transparent,
	Black_Transparent,
	Fill_White,
	Fill_Black,
	XOR,
	NXOR,
	Inverted,
}

System_Event :: enum c.int {
	Init,
	Init_Lua,
	Lock,
	Unlock,
	Pause,
	Resume,
	Terminate,
	Key_Pressed,
	Key_Released,
	Low_Power,
	Mirror_Started,
	Mirror_Ended,
}

Opaque_Struct :: distinct struct{}

Bitmap :: distinct Opaque_Struct
Sprite :: distinct Opaque_Struct
HTTP_Connection :: distinct Opaque_Struct
TCP_Connection :: distinct Opaque_Struct

// Float-based rectangle used by sprites and tilemaps
PDRect :: struct {
	x:      f32,
	y:      f32,
	width:  f32,
	height: f32,
}

Package_ID :: enum {
	system,
	file,
	graphics,
	sprite,
	display,
	sound,
	lua,
	json,
	scoreboards,
	network,
}

