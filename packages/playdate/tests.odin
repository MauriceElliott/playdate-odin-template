#+build !freestanding
package playdate

import "core:math"
import "core:testing"

// These tests validate that every Odin binding struct has the correct size
// matching the C ABI of Playdate SDK 3.0.3. Struct sizes were computed by
// compiling the SDK C headers with gcc on x86_64 (8-byte pointers).
// This catches missing/extra fields, wrong ordering, and type size mismatches.

PTR_SIZE :: size_of(rawptr)

// =========================================================================
// Top-level API struct
// =========================================================================

@(test)
test_api_size :: proc(t: ^testing.T) {
	testing.expect_value(t, size_of(Api), 10 * PTR_SIZE)
}

// =========================================================================
// System API
// =========================================================================

@(test)
test_api_system_procs_size :: proc(t: ^testing.T) {
	testing.expect_value(t, size_of(Api_System_Procs), 50 * PTR_SIZE)
}

@(test)
test_date_time_size :: proc(t: ^testing.T) {
	testing.expect_value(t, size_of(Date_Time), 8)
}

@(test)
test_pdinfo_size :: proc(t: ^testing.T) {
	testing.expect_value(t, size_of(PDInfo), 8)
}

// =========================================================================
// Display API
// =========================================================================

@(test)
test_api_display_procs_size :: proc(t: ^testing.T) {
	testing.expect_value(t, size_of(Api_Display_Procs), 10 * PTR_SIZE)
}

// =========================================================================
// File API
// =========================================================================

@(test)
test_api_file_procs_size :: proc(t: ^testing.T) {
	testing.expect_value(t, size_of(Api_File_Procs), 13 * PTR_SIZE)
}

@(test)
test_file_stat_size :: proc(t: ^testing.T) {
	testing.expect_value(t, size_of(Stat), 32)
}

// =========================================================================
// Graphics API
// =========================================================================

@(test)
test_api_graphics_procs_size :: proc(t: ^testing.T) {
	testing.expect_value(t, size_of(Api_Graphics_Procs), 69 * PTR_SIZE)
}

@(test)
test_api_video_procs_size :: proc(t: ^testing.T) {
	testing.expect_value(t, size_of(Api_Video_Procs), 8 * PTR_SIZE)
}

@(test)
test_api_tilemap_procs_size :: proc(t: ^testing.T) {
	testing.expect_value(t, size_of(Api_Tilemap_Procs), 11 * PTR_SIZE)
}

@(test)
test_api_video_stream_procs_size :: proc(t: ^testing.T) {
	testing.expect_value(t, size_of(Api_Video_Stream_Procs), 11 * PTR_SIZE)
}

@(test)
test_rect_size :: proc(t: ^testing.T) {
	testing.expect_value(t, size_of(Rect), 16)
}

@(test)
test_pdrect_size :: proc(t: ^testing.T) {
	testing.expect_value(t, size_of(PDRect), 16)
}

// =========================================================================
// Sprite API
// =========================================================================

@(test)
test_api_sprite_procs_size :: proc(t: ^testing.T) {
	testing.expect_value(t, size_of(Api_Sprite_Procs), 65 * PTR_SIZE)
}

@(test)
test_sprite_collision_info_size :: proc(t: ^testing.T) {
	testing.expect_value(t, size_of(Sprite_Collision_Info), 88)
}

@(test)
test_sprite_query_info_size :: proc(t: ^testing.T) {
	testing.expect_value(t, size_of(Sprite_Query_Info), 32)
}

// =========================================================================
// Lua API
// =========================================================================

@(test)
test_api_lua_procs_size :: proc(t: ^testing.T) {
	testing.expect_value(t, size_of(Api_Lua_Procs), 32 * PTR_SIZE)
}

// =========================================================================
// JSON API
// =========================================================================

@(test)
test_api_json_procs_size :: proc(t: ^testing.T) {
	testing.expect_value(t, size_of(Api_Json_Procs), 3 * PTR_SIZE)
}

// =========================================================================
// Scoreboards API
// =========================================================================

@(test)
test_api_scoreboards_procs_size :: proc(t: ^testing.T) {
	testing.expect_value(t, size_of(Api_Scoreboards_Procs), 7 * PTR_SIZE)
}

@(test)
test_score_size :: proc(t: ^testing.T) {
	testing.expect_value(t, size_of(Score), 16)
}

@(test)
test_scores_list_size :: proc(t: ^testing.T) {
	testing.expect_value(t, size_of(Scores_List), 32)
}

@(test)
test_board_size :: proc(t: ^testing.T) {
	testing.expect_value(t, size_of(Board), 16)
}

@(test)
test_boards_list_size :: proc(t: ^testing.T) {
	testing.expect_value(t, size_of(Boards_List), 16)
}

// =========================================================================
// Network API
// =========================================================================

@(test)
test_api_network_procs_size :: proc(t: ^testing.T) {
	testing.expect_value(t, size_of(Api_Network_Procs), 7 * PTR_SIZE)
}

@(test)
test_api_http_procs_size :: proc(t: ^testing.T) {
	testing.expect_value(t, size_of(Api_HTTP_Procs), 25 * PTR_SIZE)
}

@(test)
test_api_tcp_procs_size :: proc(t: ^testing.T) {
	testing.expect_value(t, size_of(Api_TCP_Procs), 16 * PTR_SIZE)
}

// =========================================================================
// Sound API — main struct and all sub-structs
// =========================================================================

@(test)
test_api_sound_procs_size :: proc(t: ^testing.T) {
	testing.expect_value(t, size_of(Api_Sound_Procs), 24 * PTR_SIZE)
}

@(test)
test_api_sound_source_procs_size :: proc(t: ^testing.T) {
	testing.expect_value(t, size_of(Api_Sound_Source_Procs), 4 * PTR_SIZE)
}

@(test)
test_api_sound_file_player_procs_size :: proc(t: ^testing.T) {
	testing.expect_value(t, size_of(Api_Sound_File_Player_Procs), 22 * PTR_SIZE)
}

@(test)
test_api_sound_sample_procs_size :: proc(t: ^testing.T) {
	testing.expect_value(t, size_of(Api_Sound_Sample_Procs), 8 * PTR_SIZE)
}

@(test)
test_api_sound_sample_player_procs_size :: proc(t: ^testing.T) {
	testing.expect_value(t, size_of(Api_Sound_Sample_Player_Procs), 17 * PTR_SIZE)
}

@(test)
test_api_sound_synth_procs_size :: proc(t: ^testing.T) {
	testing.expect_value(t, size_of(Api_Sound_Synth_Procs), 30 * PTR_SIZE)
}

@(test)
test_api_sound_sequence_procs_size :: proc(t: ^testing.T) {
	testing.expect_value(t, size_of(Api_Sound_Sequence_Procs), 20 * PTR_SIZE)
}

@(test)
test_api_sound_track_procs_size :: proc(t: ^testing.T) {
	testing.expect_value(t, size_of(Api_Sound_Track_Procs), 17 * PTR_SIZE)
}

@(test)
test_api_sound_instrument_procs_size :: proc(t: ^testing.T) {
	testing.expect_value(t, size_of(Api_Sound_Instrument_Procs), 13 * PTR_SIZE)
}

@(test)
test_api_sound_effect_procs_size :: proc(t: ^testing.T) {
	testing.expect_value(t, size_of(Api_Sound_Effect_Procs), 13 * PTR_SIZE)
}

@(test)
test_api_sound_lfo_procs_size :: proc(t: ^testing.T) {
	testing.expect_value(t, size_of(Api_Sound_LFO_Procs), 14 * PTR_SIZE)
}

@(test)
test_api_sound_envelope_procs_size :: proc(t: ^testing.T) {
	testing.expect_value(t, size_of(Api_Sound_Envelope_Procs), 12 * PTR_SIZE)
}

@(test)
test_api_sound_signal_procs_size :: proc(t: ^testing.T) {
	testing.expect_value(t, size_of(Api_Sound_Signal_Procs), 6 * PTR_SIZE)
}

@(test)
test_api_sound_control_signal_procs_size :: proc(t: ^testing.T) {
	testing.expect_value(t, size_of(Api_Sound_Control_Signal_Procs), 6 * PTR_SIZE)
}

@(test)
test_api_sound_channel_procs_size :: proc(t: ^testing.T) {
	testing.expect_value(t, size_of(Api_Sound_Channel_Procs), 16 * PTR_SIZE) // Was 16 in C
}

@(test)
test_api_sound_effect_two_pole_filter_procs_size :: proc(t: ^testing.T) {
	testing.expect_value(t, size_of(Api_Sound_Effect_Two_Pole_Filter_Procs), 10 * PTR_SIZE)
}

@(test)
test_api_sound_effect_one_pole_filter_procs_size :: proc(t: ^testing.T) {
	testing.expect_value(t, size_of(Api_Sound_Effect_One_Pole_Filter_Procs), 5 * PTR_SIZE)
}

@(test)
test_api_sound_effect_bit_crusher_procs_size :: proc(t: ^testing.T) {
	testing.expect_value(t, size_of(Api_Sound_Effect_Bit_Crusher_Procs), 8 * PTR_SIZE)
}

@(test)
test_api_sound_effect_ring_modulator_procs_size :: proc(t: ^testing.T) {
	testing.expect_value(t, size_of(Api_Sound_Effect_Ring_Modulator_Procs), 5 * PTR_SIZE)
}

@(test)
test_api_sound_effect_delay_line_procs_size :: proc(t: ^testing.T) {
	testing.expect_value(t, size_of(Api_Sound_Effect_Delay_Line_Procs), 10 * PTR_SIZE)
}

@(test)
test_api_sound_effect_overdrive_procs_size :: proc(t: ^testing.T) {
	testing.expect_value(t, size_of(Api_Sound_Effect_Overdrive_Procs), 9 * PTR_SIZE)
}

// =========================================================================
// Utility function tests
// =========================================================================

@(test)
test_note_to_frequency :: proc(t: ^testing.T) {
	// A4 = MIDI note 69 = 440 Hz
	freq := note_to_frequency(MIDI_Note(69))
	testing.expect(t, math.abs(freq - 440.0) < 0.01, "A4 (MIDI 69) should be 440 Hz")
}

@(test)
test_frequency_to_note :: proc(t: ^testing.T) {
	// 440 Hz = MIDI note 69
	note := frequency_to_note(440.0)
	testing.expect(t, math.abs(f32(note) - 69.0) < 0.01, "440 Hz should be MIDI note 69")
}

@(test)
test_sound_format_is_stereo :: proc(t: ^testing.T) {
	testing.expect(
		t,
		!bool(sound_format_is_stereo(.Mono_8_Bit)),
		"Mono_8_Bit should not be stereo",
	)
	testing.expect(t, bool(sound_format_is_stereo(.Stereo_8_Bit)), "Stereo_8_Bit should be stereo")
	testing.expect(
		t,
		!bool(sound_format_is_stereo(.Mono_16_Bit)),
		"Mono_16_Bit should not be stereo",
	)
	testing.expect(
		t,
		bool(sound_format_is_stereo(.Stereo_16_Bit)),
		"Stereo_16_Bit should be stereo",
	)
}

@(test)
test_sound_format_bytes_per_frame :: proc(t: ^testing.T) {
	testing.expect_value(t, sound_format_bytes_per_frame(.Mono_8_Bit), 1)
	testing.expect_value(t, sound_format_bytes_per_frame(.Stereo_8_Bit), 2)
	testing.expect_value(t, sound_format_bytes_per_frame(.Mono_16_Bit), 2)
	testing.expect_value(t, sound_format_bytes_per_frame(.Stereo_16_Bit), 4)
}

