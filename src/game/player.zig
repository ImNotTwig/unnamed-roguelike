const game = @import("./game.zig");
const rl = @import("raylib");

lock: game.TransitionLock,
//visual_location and actual_location are similar to visual_location and
//target_location as specified in TransitionLock
visual_location: rl.Vector2,
actual_location: rl.Vector2,

// occupied_tile is the tile in which the player resides on the level grid
occupied_tile: rl.Vector2,
