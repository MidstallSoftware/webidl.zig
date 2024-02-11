const std = @import("std");
const ptk = @import("parser-toolkit");
const Parser = @import("../../Parser.zig");
const ConstValue = @import("ConstValue.zig");
const String = @import("String.zig");
const Default = @This();

pub const Value = union(enum) {
    @"const": ConstValue,
    string: String,
    array: void,
    object: void,
};

location: ptk.Location,
value: Value,

pub fn peek(parser: *Parser, messages: *std.ArrayList(Parser.Message)) Parser.Error!?Default {
    var ctx = parser.getContext(messages);
    defer parser.restoreContext(ctx);

    const eql = try ctx.expectTokenPeek(.@"=") orelse return null;
    _ = try ctx.expectTokenAccept(.@"=");

    var value: Value = undefined;

    if (try ConstValue.peek(parser, messages)) |constValue| {
        _ = try ConstValue.accept(parser, messages);
        value = .{ .@"const" = constValue };
    } else if (try String.peek(parser, messages)) |string| {
        _ = try String.accept(parser, messages);
        value = .{ .string = string };
    } else if (try ctx.expectTokenPeek(.@"[")) |_| {
        _ = try ctx.expectTokenAccept(.@"[");
        _ = try ctx.expectTokenAccept(.@"]");

        value = .array;
    } else if (try ctx.expectTokenPeek(.@"{")) |_| {
        _ = try ctx.expectTokenAccept(.@"{");
        _ = try ctx.expectTokenAccept(.@"}");

        value = .object;
    } else return null;

    return .{
        .location = eql.location,
        .value = value,
    };
}

pub fn accept(parser: *Parser, messages: *std.ArrayList(Parser.Message)) Parser.Error!Default {
    var ctx = parser.getContext(messages);
    defer parser.restoreContext(ctx);

    const eql = try ctx.expectTokenAccept(.@"=");

    var value: Value = undefined;

    if (try ConstValue.peek(parser, messages)) |constValue| {
        _ = try ConstValue.accept(parser, messages);
        value = .{ .@"const" = constValue };
    } else if (try String.peek(parser, messages)) |string| {
        _ = try String.accept(parser, messages);
        value = .{ .string = string };
    } else if (try ctx.expectTokenPeek(.@"[")) |_| {
        _ = try ctx.expectTokenAccept(.@"[");
        _ = try ctx.expectTokenAccept(.@"]");

        value = .array;
    } else if (try ctx.expectTokenPeek(.@"{")) |_| {
        _ = try ctx.expectTokenAccept(.@"{");
        _ = try ctx.expectTokenAccept(.@"}");

        value = .object;
    } else {
        defer ctx.reset();
        ctx.expected = .{ .tokens = &.{ .@"[", .@"{", .symbol, .float, .int } };
        ctx.got = if (try ctx.peek()) |token| .{ .token = token.type } else null;
        try ctx.pushError(error.UnexpectedSymbol);
        return error.UnexpectedSymbol;
    }

    return .{
        .location = eql.location,
        .value = value,
    };
}
