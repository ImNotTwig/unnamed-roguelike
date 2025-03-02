const Self = @This();

const std = @import("std");
const rl = @import("raylib");

const game = @import("../game/Game.zig");
const body_parts = @import("../body/body_part_constants.zig");
const labels = @import("../body/body_part_labels.zig").labels;
const config = @import("../main.zig").config;

const BodyPart = @import("../body/BodyPart.zig");
const Effect = @import("./Effect.zig");
const TransitionLock = @import("../game/TransitionLock.zig");

// if any body part in this list is not present on this entity, the entity should be killed asap
required_body_parts: ?[]const []const u8,

root_body_part: *BodyPart,

// for statuses that affect the whole body
status_effects: []Effect,

// occupied_tile is the tile in which the entity resides on the level grid
occupied_tile: rl.Vector2,
lock: TransitionLock,

pub const PartWithSize = struct {
    bp: *BodyPart,
    size: struct {
        x: f32,
        width: f32,
    },
    children: ?[]PartWithSize = null,
};

fn getChildrenSizes(bp: *BodyPart, parent_x: ?f32, parent_w: ?f32, allocator: std.mem.Allocator) ![]PartWithSize {
    var list = std.ArrayList(PartWithSize).init(allocator);
    defer list.deinit();

    const px = if (parent_x) |px| px else 0;
    const pw = if (parent_w) |pw| pw else if (bp.size) |bs| bs else 1;

    if (bp.children) |children| {
        var dist: f32 = px;
        for (children.items) |child| {
            const width = if (child.size) |cs| cs * pw else pw;

            var part = PartWithSize{
                .bp = child,
                .size = .{
                    .width = width,
                    .x = dist,
                },
            };
            dist += width;
            part.children = try getChildrenSizes(child, dist, width, allocator);
            try list.append(part);
        }
    }
    return try list.toOwnedSlice();
}

pub fn getBodyPartSizes(self: Self, allocator: std.mem.Allocator) ![]PartWithSize {
    return getChildrenSizes(self.root_body_part, null, null, allocator);
}
