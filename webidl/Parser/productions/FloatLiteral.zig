const std = @import("std");
const ptk = @import("parser-toolkit");
const Parser = @import("../../Parser.zig");
const FloatLiteral = @This();

value: f64,
location: ptk.Location,

pub fn peek(parser: *Parser, messages: *std.ArrayList(Parser.Message)) Parser.Error!?FloatLiteral {
    var ctx = parser.getContext(messages);
    defer parser.restoreContext(ctx);

    if (try ctx.expectSymbolPeek(.Infinity)) |token| {
        return .{
            .value = std.math.inf(f64),
            .location = token.location,
        };
    }

    if (try ctx.expectSymbolPeek(.@"-Infinity")) |token| {
        return .{
            .value = std.math.inf(f64) * -1,
            .location = token.location,
        };
    }

    if (try ctx.expectSymbolPeek(.NaN)) |token| {
        return .{
            .value = std.math.nan(f64),
            .location = token.location,
        };
    }

    _ = try ctx.expectTokenPeek(.float) orelse return null;
    const token = try ctx.expectTokenAccept(.float);

    return .{
        .value = try std.fmt.parseFloat(f64, token.text),
        .location = token.location,
    };
}

pub fn accept(parser: *Parser, messages: *std.ArrayList(Parser.Message)) Parser.Error!FloatLiteral {
    var ctx = parser.getContext(messages);
    errdefer parser.restoreContext(ctx);

    if (try ctx.expectSymbolPeek(.Infinity)) |token| {
        _ = try ctx.expectSymbolAccept(.Infinity);
        return .{
            .value = std.math.inf(f64),
            .location = token.location,
        };
    }

    if (try ctx.expectSymbolPeek(.@"-Infinity")) |token| {
        _ = try ctx.expectSymbolAccept(.@"-Infinity");
        return .{
            .value = std.math.inf(f64) * -1,
            .location = token.location,
        };
    }

    if (try ctx.expectSymbolPeek(.NaN)) |token| {
        _ = try ctx.expectSymbolAccept(.NaN);
        return .{
            .value = std.math.nan(f64),
            .location = token.location,
        };
    }

    const token = try ctx.expectTokenAccept(.float);

    return .{
        .value = try std.fmt.parseFloat(f64, token.text),
        .location = token.location,
    };
}

pub fn isInfinity(self: FloatLiteral) bool {
    return self.value == std.math.inf(f64);
}

pub fn isNegativeInfinity(self: FloatLiteral) bool {
    return self.value == (std.math.inf(f64) * -1);
}

pub fn isNaN(self: FloatLiteral) bool {
    return std.math.isNan(self.value);
}

test "Parse float literal" {
    const alloc = std.testing.allocator;

    var messages = std.ArrayList(Parser.Message).init(alloc);
    defer Parser.Message.deinit(&messages);

    var parser = try Parser.init(alloc,
        \\12345.67890
    );
    defer parser.deinit();

    const value = accept(&parser, &messages) catch |err| {
        for (messages.items) |item| std.debug.print("{}\n", .{item});
        return err;
    };

    try std.testing.expectEqual(ptk.Location{
        .column = 1,
        .line = 1,
    }, value.location);
    try std.testing.expectEqual(12345.6789, value.value);
    try std.testing.expectEqual(false, value.isInfinity());
    try std.testing.expectEqual(false, value.isNegativeInfinity());
    try std.testing.expectEqual(false, value.isNaN());
}

test "Parse float literal infinity" {
    const alloc = std.testing.allocator;

    var messages = std.ArrayList(Parser.Message).init(alloc);
    defer Parser.Message.deinit(&messages);

    var parser = try Parser.init(alloc,
        \\Infinity
    );
    defer parser.deinit();

    const value = accept(&parser, &messages) catch |err| {
        for (messages.items) |item| std.debug.print("{}\n", .{item});
        return err;
    };

    try std.testing.expectEqual(ptk.Location{
        .column = 1,
        .line = 1,
    }, value.location);
    try std.testing.expectEqual(std.math.inf(f64), value.value);
    try std.testing.expectEqual(true, value.isInfinity());
    try std.testing.expectEqual(false, value.isNegativeInfinity());
    try std.testing.expectEqual(false, value.isNaN());
}

test "Parse float literal negative infinity" {
    const alloc = std.testing.allocator;

    var messages = std.ArrayList(Parser.Message).init(alloc);
    defer Parser.Message.deinit(&messages);

    var parser = try Parser.init(alloc,
        \\-Infinity
    );
    defer parser.deinit();

    const value = accept(&parser, &messages) catch |err| {
        for (messages.items) |item| std.debug.print("{}\n", .{item});
        return err;
    };

    try std.testing.expectEqual(ptk.Location{
        .column = 1,
        .line = 1,
    }, value.location);
    try std.testing.expectEqual(std.math.inf(f64) * -1, value.value);
    try std.testing.expectEqual(false, value.isInfinity());
    try std.testing.expectEqual(true, value.isNegativeInfinity());
    try std.testing.expectEqual(false, value.isNaN());
}

test "Parse float literal nan" {
    const alloc = std.testing.allocator;

    var messages = std.ArrayList(Parser.Message).init(alloc);
    defer Parser.Message.deinit(&messages);

    var parser = try Parser.init(alloc,
        \\NaN
    );
    defer parser.deinit();

    const value = accept(&parser, &messages) catch |err| {
        for (messages.items) |item| std.debug.print("{}\n", .{item});
        return err;
    };

    try std.testing.expectEqual(ptk.Location{
        .column = 1,
        .line = 1,
    }, value.location);
    try std.testing.expectEqual(false, value.isInfinity());
    try std.testing.expectEqual(false, value.isNegativeInfinity());
    try std.testing.expectEqual(true, value.isNaN());
}
