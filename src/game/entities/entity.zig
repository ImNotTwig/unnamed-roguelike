const std = @import("std");
const game = @import("../game.zig");
const rl = @import("raylib");

const BodyPart = @import("./bodypart.zig");

// the keys of body_parts should be well defined, as to not end up with
// "arm_left", "left_arm", "left arm", etc
// keys should be formatted as such:
// x_y, where x is the position, and y is the body part type
body_parts: std.StringHashMap(std.ArrayList(BodyPart)),

// occupied_tile is the tile in which the entity resides on the level grid
occupied_tile: rl.Vector2,
lock: game.TransitionLock
