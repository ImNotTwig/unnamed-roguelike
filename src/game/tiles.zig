const rl = @import("raylib");
const colors = @import("../colors.zig");
const level = @import("./level.zig");

pub const floor_0: level.Tile = .{ .floor = .{
    .hidden = true,
    .color = colors.FF_GRAY02,
} };

pub const wall_0: level.Tile = .{ .wall = .{
    .hidden = true,
    .color = colors.FF_BG,
} };

pub const stair_0: level.Tile = .{ .stair = .{
    .hidden = true,
    .color = colors.FF_WHITE,
} };

pub const checking_tile: level.Tile = .{ .other = .{
    .hidden = true,
    .color = rl.Color.pink,
} };

pub const wall_0_border = colors.FF_GRAY05;
