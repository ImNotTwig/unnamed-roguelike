//TODO: Actually implement logging thresholds in main code
// []: non-lethal errors
// []: warnings
// []: verbose
// []: very_verbose

const std = @import("std");

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
}
