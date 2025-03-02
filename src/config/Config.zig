//TODO: Actually implement logging thresholds in main code
// []: non-lethal errors
// []: warnings
// []: verbose
// []: very_verbose

const std = @import("std");
const rl = @import("raylib");

debug: struct {
    enable_debug_tools: bool,
    log_level: enum(u8) {
        // no logs at all
        none = 0,
        // log errors
        errors = 1,
        // log warnings, errors
        default = 2,
        // log previous things, plus major events
        verbose = 3,
        // log previous things, and every single event
        very_verbose = 4,
    } = .default,
},

keybinds: struct {
    debug_show_all_tiles: rl.KeyboardKey = .p,

    show_player_stats: rl.KeyboardKey = .t,

    move_up: rl.KeyboardKey = .w,
    move_down: rl.KeyboardKey = .s,
    move_left: rl.KeyboardKey = .a,
    move_right: rl.KeyboardKey = .d,

    commit_attack: rl.KeyboardKey = .z,
} = .{},

colors: struct {
    ff_red: rl.Color = .{ .r = 248, .g = 200, .b = 220, .a = 255 },

    ff_magenta: rl.Color = .{ .r = 244, .g = 154, .b = 194, .a = 255 },
    ff_b_magenta: rl.Color = .{ .r = 241, .g = 159, .b = 192, .a = 255 },

    ff_orange: rl.Color = .{ .r = 252, .g = 165, .b = 165, .a = 255 },

    ff_yellow: rl.Color = .{ .r = 245, .g = 187, .b = 161, .a = 255 },

    ff_green: rl.Color = .{ .r = 191, .g = 215, .b = 181, .a = 255 },
    ff_b_green: rl.Color = .{ .r = 190, .g = 231, .b = 197, .a = 255 },

    ff_blue: rl.Color = .{ .r = 142, .g = 182, .b = 245, .a = 255 },
    ff_b_blue: rl.Color = .{ .r = 142, .g = 196, .b = 229, .a = 255 },

    ff_cyan: rl.Color = .{ .r = 193, .g = 231, .b = 227, .a = 255 },

    ff_purple: rl.Color = .{ .r = 195, .g = 177, .b = 225, .a = 255 },

    ff_bg: rl.Color = .{ .r = 15, .g = 16, .b = 16, .a = 255 },
    ff_fg: rl.Color = .{ .r = 201, .g = 199, .b = 205, .a = 255 },

    ff_white: rl.Color = .{ .r = 225, .g = 219, .b = 235, .a = 255 },
    ff_beige: rl.Color = .{ .r = 128, .g = 128, .b = 128, .a = 255 },

    ff_gray01: rl.Color = .{ .r = 27, .g = 27, .b = 27, .a = 255 },
    ff_gray02: rl.Color = .{ .r = 42, .g = 42, .b = 42, .a = 255 },
    ff_gray03: rl.Color = .{ .r = 62, .g = 62, .b = 62, .a = 255 },
    ff_gray04: rl.Color = .{ .r = 87, .g = 87, .b = 95, .a = 255 },
    ff_gray05: rl.Color = .{ .r = 153, .g = 152, .b = 168, .a = 255 },
} = .{},
