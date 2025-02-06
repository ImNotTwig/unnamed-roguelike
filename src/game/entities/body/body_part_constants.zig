const BodyPart = @import("./BodyPart.zig");
const labels = @import("./body_part_labels.zig").labels;

////// Baseline bodyparts

pub const baseline = .{
    // Head

    .brain = BodyPart{
        .size = 0.8,
        .meta = .{
            .label = labels.brain,
            .parent = labels.head,
        },
    },

    .head = BodyPart{
        .size = 0.07,
        .meta = .{
            .label = labels.head,
            .parent = labels.torso,
        },
    },

    .left_ear = BodyPart{
        .size = 0.07,
        .meta = .{
            .label = labels.ear,
            .position = &.{"left"},
            .parent = labels.head,
        },
    },

    .right_ear = BodyPart{
        .size = 0.07,
        .meta = .{
            .label = labels.ear,
            .position = &.{"right"},
            .parent = labels.head,
        },
    },

    .jaw = BodyPart{
        .size = 0.15,
        .meta = .{
            .label = labels.jaw,
            .parent = labels.head,
        },
    },

    .tongue = BodyPart{
        .size = 0.01,
        .meta = .{
            .label = labels.tongue,
            .parent = labels.jaw,
        },
    },

    .teeth = BodyPart{
        .size = 0,
        .meta = .{
            .label = labels.teeth,
            .parent = labels.jaw,
        },
    },

    .nose = BodyPart{
        .size = 0.10,
        .meta = .{
            .label = labels.nose,
            .parent = labels.head,
        },
    },

    .left_eye = BodyPart{
        .size = 0.07,
        .meta = .{
            .label = labels.eye,
            .position = &.{"left"},
            .parent = labels.head,
        },
    },

    .right_eye = BodyPart{
        .size = 0.07,
        .meta = .{
            .label = labels.eye,
            .position = &.{"right"},
            .parent = labels.head,
        },
    },

    // Torso

    .torso = BodyPart{
        .size = 1,
        .meta = .{
            .label = labels.torso,
        },
    },

    .spine = BodyPart{
        .size = 0.025,
        .meta = .{
            .label = labels.spine,
            .parent = labels.torso,
        },
    },

    .skin = BodyPart{
        .size = 0,
        .meta = .{
            .label = labels.skin,
            .parent = labels.torso,
        },
    },

    .liver = BodyPart{
        .size = 0.025,
        .meta = .{
            .label = labels.liver,
            .parent = labels.torso,
        },
    },

    .left_lung = BodyPart{
        .size = 0.025,
        .meta = .{
            .label = labels.lung,
            .position = &.{"left"},
            .parent = labels.torso,
        },
    },

    .right_lung = BodyPart{
        .size = 0.025,
        .meta = .{
            .label = labels.lung,
            .position = &.{"right"},
            .parent = labels.torso,
        },
    },

    .heart = BodyPart{
        .size = 0.020,
        .meta = .{
            .label = labels.heart,
            .parent = labels.torso,
        },
    },

    .stomach = BodyPart{
        .size = 0.025,
        .meta = .{
            .label = labels.stomach,
            .parent = labels.torso,
        },
    },

    .left_kidney = BodyPart{
        .size = 0.017,
        .meta = .{
            .label = labels.kidney,
            .position = &.{"left"},
            .parent = labels.torso,
        },
    },

    .right_kidney = BodyPart{
        .size = 0.017,
        .meta = .{
            .label = labels.kidney,
            .position = &.{"right"},
            .parent = labels.torso,
        },
    },

    // Extremeties

    .right_arm = BodyPart{
        .size = 0.77,
        .meta = .{
            .label = labels.arm,
            .position = &.{"right"},
            .parent = labels.torso,
        },
    },

    .left_arm = BodyPart{
        .size = 0.77,
        .meta = .{
            .label = labels.arm,
            .position = &.{"left"},
            .parent = labels.torso,
        },
    },

    .right_leg = BodyPart{
        .size = 0.14,
        .meta = .{
            .label = labels.leg,
            .position = &.{"right"},
            .parent = labels.torso,
        },
    },

    .left_leg = BodyPart{
        .size = 0.14,
        .meta = .{
            .label = labels.leg,
            .position = &.{"left"},
            .parent = labels.torso,
        },
    },

    .left_foot = BodyPart{
        .size = 0.10,
        .meta = .{
            .label = labels.foot,
            .position = &.{"left"},
            .parent = labels.leg,
        },
    },

    .right_foot = BodyPart{
        .size = 0.10,
        .meta = .{
            .label = labels.foot,
            .position = &.{"right"},
            .parent = labels.leg,
        },
    },

    .left_hand = BodyPart{
        .size = 0.14,
        .meta = .{
            .label = labels.hand,
            .position = &.{"left"},
            .parent = labels.arm,
        },
    },

    .right_hand = BodyPart{
        .size = 0.14,
        .meta = .{
            .label = labels.hand,
            .position = &.{"right"},
            .parent = labels.arm,
        },
    },
};
