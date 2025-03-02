const std = @import("std");

const Entity = @import("./Entity.zig");
const BodyPart = @import("../body/BodyPart.zig");
const Game = @import("../game/Game.zig");
const TransitionLock = @import("../game/TransitionLock.zig");

const labels = @import("../body/body_part_labels.zig").labels;
const body_parts = @import("../body/body_part_constants.zig");

fn getParentPart(root_part: *BodyPart, child: BodyPart) ?*BodyPart {
    if (child.meta.parent == null) return null;
    if (std.mem.eql(u8, root_part.meta.label, child.meta.parent.?)) {
        return root_part;
    }
    if (root_part.children) |children| for (children.items) |root_child| {
        const potential_parent = getParentPart(root_child, child);
        if (potential_parent) |p| {
            if (std.mem.eql(u8, p.meta.label, child.meta.parent.?)) return potential_parent;
        }
    };
    return null;
}

pub fn baseliner(allocator: std.mem.Allocator) !Entity {
    var bl = Entity{
        .root_body_part = undefined,
        .status_effects = &.{},
        .occupied_tile = .{ .x = 0, .y = 0 },
        .lock = TransitionLock{
            .transition = false,
            .animation_time = 0.150,
            .delta = 0,
            .visual_location = .{ .x = 0, .y = 0 },
            .target_location = .{ .x = 0, .y = 0 },
        },
        .required_body_parts = &.{
            labels.heart,
            labels.brain,
            labels.head,
            labels.lung,
            labels.liver,
            labels.kidney,
        },
    };

    var part_list: [std.meta.fields(@TypeOf(body_parts.baseline)).len]?BodyPart = undefined;

    inline for (0.., std.meta.fields(@TypeOf(body_parts.baseline))) |i, body_part| {
        part_list[i] = @field(body_parts.baseline, body_part.name);
    }
    for (part_list) |part| {
        if (part == null) {
            std.log.err("Found null BodyPart in part_list before inserting into baseliner when creating.\nThis should not be possible.\n", .{});
            std.process.exit(1);
        }
    }

    var valid_insertions: usize = 0;
    inline for (0.., part_list) |part_list_idx, optpart| if (optpart) |part| {
        if (part.meta.parent == null) {
            const new_part = try allocator.create(BodyPart);
            new_part.* = part;
            bl.root_body_part = new_part;
            try bl.root_body_part.init(allocator);

            part_list[part_list_idx] = null;
            valid_insertions += 1;
        }
    };

    if (valid_insertions < 1) {
        std.log.err("No valid root_body_part found for baseliner when creating.\n", .{});
        std.process.exit(1);
    }

    while (valid_insertions < part_list.len) {
        inline for (0.., part_list) |part_list_idx, optpart| if (optpart) |part| {
            var new_part = try allocator.create(BodyPart);
            new_part.* = part;
            try new_part.init(allocator);

            if (getParentPart(bl.root_body_part, new_part.*)) |parent| {
                if (parent.addPartBool(new_part)) {
                    part_list[part_list_idx] = null;
                    valid_insertions += 1;
                }
            }
        };
    }

    return bl;
}
