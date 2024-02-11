const std = @import("std");
const ptk = @import("parser-toolkit");
const Parser = @import("../../Parser.zig");
const TypeSuffix = @import("TypeSuffix.zig");
const TypeSuffixStartingWithArray = @This();

location: ptk.Location,
suffix: ?TypeSuffix,

pub fn peek(parser: *Parser, messages: *std.ArrayList(Parser.Message)) Parser.Error!?TypeSuffixStartingWithArray {
    var ctx = parser.getContext(messages);
    defer parser.restoreContext(ctx);

    const token = try ctx.expectTokenPeek(.@"[") orelse return null;
    _ = try ctx.expectTokenAccept(.@"[");
    _ = try ctx.expectTokenAccept(.@"]");

    const suffix: ?TypeSuffix = try TypeSuffix.peek(parser, messages);
    if (suffix != null) _ = try TypeSuffix.accept(parser, messages);

    return .{
        .location = token.location,
        .suffix = suffix,
    };
}

pub fn accept(parser: *Parser, messages: *std.ArrayList(Parser.Message)) Parser.Error!TypeSuffixStartingWithArray {
    var ctx = parser.getContext(messages);
    defer parser.restoreContext(ctx);

    const token = try ctx.expectTokenAccept(.@"[");
    _ = try ctx.expectTokenAccept(.@"]");

    const suffix: ?TypeSuffix = try TypeSuffix.peek(parser, messages);
    if (suffix != null) _ = try TypeSuffix.accept(parser, messages);

    return .{
        .location = token.location,
        .suffix = suffix,
    };
}

pub fn deinit(self: *const TypeSuffixStartingWithArray, parser: *Parser) void {
    if (self.suffix) |suffix| suffix.deinit(parser);
}
