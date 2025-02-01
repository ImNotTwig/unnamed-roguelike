const Self = @This();
const stats = @import("../stats.zig");
const Effect = @import("../effect.zig");

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

pub const labels = .{
    .torso = "torso",
    .head = "head",
    .brain = "brain",

    .jaw = "jaw",
    .tongue = "tongue",
    .teeth = "teeth",

    .ear = "ear",
    .nose = "nose",
    .eye = "eye",

    .spine = "spine",

    .skin = "skin",

    .liver = "liver",
    .lung = "lung",
    .stomach = "stomach",
    .kidney = "kidney",
    .heart = "heart",

    .arm = "arm",
    .hand = "hand",

    .leg = "leg",
    .foot = "foot",
};

meta: Meta,

// this field refers to how much of a chance this part will get hit, when its parent gets hit.
// a part with no parents has a size of 100% == 1, and most of the time the biggest part will be the torso
// NOTE: when size == 0, then this body part cannot be hit, and must rely on
// other body parts to exist, in which case this body part gets hit when its parent
// gets hit
size: f32,

health: stats.Health = .{},
defense: stats.DamageTypeValues = .{},

// for body part specific statuses
status_effects: []Effect = &.{},

// occupied_slots determines how many slots this body part will take up
// when placed on an entity
// NOTE: this can be negative, in case you want to actually have a body part that *makes* slots
occupied_slots: f32 = 1,
