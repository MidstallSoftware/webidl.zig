const std = @import("std");
const ptk = @import("parser-toolkit");
const Parser = @import("../../Parser.zig");
const Identifier = @This();

name: []const u8,
location: ptk.Location,

pub fn peek(parser: *Parser, messages: *std.ArrayList(Parser.Message)) Parser.Error!?Identifier {
    var ctx = parser.getContext(messages);
    defer parser.restoreContext(ctx);

    const token = try ctx.expectTokenPeek(.identifier) orelse return null;
    return .{
        .location = token.location,
        .name = token.text,
    };
}

pub fn accept(parser: *Parser, messages: *std.ArrayList(Parser.Message)) Parser.Error!Identifier {
    var ctx = parser.getContext(messages);
    errdefer parser.restoreContext(ctx);

    const token = try ctx.expectTokenAccept(.identifier) orelse return null;
    return .{
        .location = token.location,
        .name = token.text,
    };
}
