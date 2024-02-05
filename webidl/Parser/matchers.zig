const std = @import("std");
const ptk = @import("parser-toolkit");
const Symbol = @import("productions/Symbol.zig");

pub fn basicIdentifier(input: []const u8) usize {
    const first_char = "-_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
    const all_chars = first_char ++ "0123456789";
    for (input, 0..) |c, i| {
        if (std.mem.indexOfScalar(u8, if (i > 0 and input[0] != '-') all_chars else first_char, c) == null) {
            return i;
        }
    }
    return input.len;
}

pub const float = ptk.matchers.sequenceOf(.{ ptk.matchers.decimalNumber, ptk.matchers.literal("."), ptk.matchers.decimalNumber });

pub fn int(input: []const u8) ?usize {
    if (std.ascii.startsWithIgnoreCase(input, "0x")) {
        if (ptk.matchers.hexadecimalNumber(input[2..])) |i| {
            return i + 2;
        }
        return null;
    }

    const i = ptk.matchers.decimalNumber(input) orelse 0;
    return if (i > 0) i else null;
}

pub fn symbol(input: []const u8) ?usize {
    const i = basicIdentifier(input);
    return if (std.meta.stringToEnum(Symbol.Type, input[0..i])) |_| i else null;
}

pub fn string(input: []const u8) ?usize {
    if (input[0] == '"') {
        if (std.mem.indexOf(u8, input[1..], "\"")) |i| {
            return i + 2;
        }
    }
    return null;
}

pub fn identifier(input: []const u8) ?usize {
    if (int(input)) |_| return null;

    const i = basicIdentifier(input);
    if (input[0] == '-') {
        var digits: usize = 0;
        for (input[1..i]) |ch| {
            if (std.ascii.isDigit(ch)) {
                digits += 1;
            }
        }
        if (digits == (i - 1)) return null;
    }
    return if (std.meta.stringToEnum(Symbol.Type, input[0..i])) |_| null else i;
}

test "Matching hexadecimals" {
    try std.testing.expectEqual(6, int("0xFFFF"));
    try std.testing.expectEqual(null, identifier("0xFFFF"));
}
