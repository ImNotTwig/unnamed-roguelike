const rl = @import("raylib");
const colors = @import("../main.zig").config.colors;
const level = @import("./level.zig");

pub const floor_0: level.Tile = .{ .floor = .{
    .hidden = true,
    .color = colors.ff_gray02,
} };

pub const wall_0: level.Tile = .{ .wall = .{
    .hidden = true,
    .color = colors.ff_bg,
} };

pub const stair_0: level.Tile = .{ .stair = .{
    .hidden = true,
    .color = colors.ff_gray04,
} };

pub const checking_tile: level.Tile = .{ .other = .{
    .hidden = true,
    .color = rl.Color.pink,
} };

pub const wall_0_border = colors.ff_gray05;
