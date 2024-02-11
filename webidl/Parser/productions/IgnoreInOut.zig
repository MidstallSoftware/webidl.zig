const std = @import("std");
const ptk = @import("parser-toolkit");
const Parser = @import("../../Parser.zig");
const Symbol = @import("Symbol.zig");
const IgnoreInOut = @This();

pub const Type = enum {
    in,
    out,
};

type: Type,
location: ptk.Location,

pub fn peek(parser: *Parser, messages: *std.ArrayList(Parser.Message)) Parser.Error!?IgnoreInOut {
    var ctx = parser.getContext(messages);
    defer parser.restoreContext(ctx);

    const token = try ctx.expectTokenPeek(.identifier) orelse return null;
    return .{
        .location = token.location,
        .type = std.meta.stringToEnum(Type, token.text) orelse return null,
    };
}

pub fn accept(parser: *Parser, messages: *std.ArrayList(Parser.Message)) Parser.Error!IgnoreInOut {
    var ctx = parser.getContext(messages);
    errdefer parser.restoreContext(ctx);

    const token = try ctx.expectTokenAccept(.identifier);
    return .{
        .location = token.location,
        .type = std.meta.stringToEnum(Type, token.text) orelse return error.UnexpectedToken,
    };
}
