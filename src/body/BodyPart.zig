const Self = @This();

const std = @import("std");

const stats = @import("../entities/stats.zig");
const Effect = @import("../entities/Effect.zig");

const config = @import("../main.zig").config;

pub const Meta = struct {
    // this label signifies where on the body it should go, no matter what the
    // actual name of the part is, all legs will always go in the leg slot
    label: []const u8,

    // the positions this body part take up in its respective group
    position: ?[]const []const u8 = null,

    // some parts need another part to exist, ie: ears require the head to exist, this
    // is where you will put that label
    parent: ?[]const u8 = null,
};

pub const errors = error{
    BodyPartPositionTaken,
    BodyPartDoesntExist,
    BodyPartDoesntExistAtPosition,
    BodyPartInvalidParent,
    BodyPartHasNoChildren,
};

meta: Meta,

// this field refers to how much of a chance this part will get hit, when its parent gets hit.
// a part with no parents has a size of 100% == 1, and most of the time the biggest part will be the torso
// NOTE: when size == null, then this body part takes damage when it's parent does.
size: ?f32,

health: stats.Health = .{},
defense: stats.DamageTypeValues = .{},

// for body part specific statuses
status_effects: []Effect = &.{},

children: ?std.ArrayList(*Self) = null,

pub fn init(self: *Self, allocator: std.mem.Allocator) !void {
    self.children = std.ArrayList(*Self).init(allocator);
}

pub fn getPositionalPartErr(self: Self, label: []const u8, position: []const u8) !Self {
    if (self.children) |children| for (children.items) |child| {
        if (child.meta.position) |child_positions| for (child_positions) |child_position| {
            if (std.mem.eql(u8, child.meta.label, label) and std.mem.eql(u8, child_position, position)) return child.*;
        };
    };
    if (comptime @intFromEnum(config.debug.log_level) >= 1) {
        std.log.err(
            "Could not find positional BodyPart: {s}:{s} in {s}",
            .{ position, label, self.meta.label },
        );
    }
    return errors.BodyPartDoesntExistAtPosition;
}
pub fn getPositionalPartOpt(self: Self, label: []const u8, position: []const u8) ?Self {
    if (self.children) |children| for (children.items) |child| {
        if (child.meta.position) |child_positions| for (child_positions) |child_position| {
            if (std.mem.eql(u8, child.meta.label, label) and std.mem.eql(u8, child_position, position)) return child.*;
        };
    };
    return null;
}

pub fn addPartErr(self: *Self, child: *Self) !void {
    if (self.children) |children| {
        for (children.items) |existing_child| {
            if (existing_child.addPartErr(child)) {
                return;
            } else |_| {}
        }
    } else {
        // the children field should be initialized before adding parts
        if (comptime @intFromEnum(config.debug.log_level) >= 1) {
            std.log.err(
                "Tried inserting children into BodyPart: {s} who's children are null\n",
                .{self.meta.label},
            );
        }

        return errors.BodyPartHasNoChildren;
    }

    if (child.meta.parent) |parent| if (!std.mem.eql(u8, self.meta.label, parent)) {
        if (comptime @intFromEnum(config.debug.log_level) >= 1) {
            std.log.err(
                "BodyPart: {s} with parent: {s} tried inserting into BodyPart: {s}\n",
                .{ child.meta.label, child.meta.parent.?, self.meta.label },
            );
        }
        return errors.BodyPartInvalidParent;
    };
    if (child.meta.position) |positions| for (positions) |position| if (self.getPositionalPartOpt(child.meta.label, position)) |_| {
        if (comptime @intFromEnum(config.debug.log_level) >= 1) {
            std.log.err(
                "Tried inserting BodyPart: {s} in BodyPart {s} at position: {s}, but it was already taken\n",
                .{ child.meta.label, self.meta.label, position },
            );
        }
        return errors.BodyPartPositionTaken;
    };

    try self.children.?.append(child);
}

pub fn addPartBool(self: *Self, child: *Self) bool {
    if (self.children == null) return false;

    if (child.meta.parent) |parent| if (!std.mem.eql(u8, self.meta.label, parent)) {
        return false;
    };
    if (child.meta.position) |positions| for (positions) |position| if (self.getPositionalPartOpt(child.meta.label, position)) |_| {
        return false;
    };

    // NOTE: I'm not really sure if i should keep this returning false, or make this function
    // return an error? because this function should ideally not return an error, because
    // thats the point of addPartErr
    self.children.?.append(child) catch {
        return false;
    };
    return true;
}
