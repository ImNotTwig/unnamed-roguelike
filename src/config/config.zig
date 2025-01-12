//TODO: Actually implement logging thresholds in main code
// []: non-lethal errors
// []: warnings
// []: verbose
// []: very_verbose

const std = @import("std");

debug: struct {
    log_level: enum {
        // no logs at all
        none,
        // log non-lethal errors
        almost_but_not_lethal,
        // log warnings, and non-lethal errors
        default,
        // log previous things, plus major events
        verbose,
        // log previous things, and every single event
        very_verbose,
    } = .default,
}
