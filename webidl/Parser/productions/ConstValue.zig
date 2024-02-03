const std = @import("std");
const ptk = @import("parser-toolkit");
const Parser = @import("../../Parser.zig");
const FloatLiteral = @import("FloatLiteral.zig");
const Integer = @import("Integer.zig");
const ConstValue = @This();

pub const Value = union(enum) {
    float: FloatLiteral,
    int: Integer,
    boolean: bool,
    null: void,
};

value: Value,
location: ptk.Location,

pub fn peek(parser: *Parser, messages: *std.ArrayList(Parser.Message)) Parser.Error!?ConstValue {
    var ctx = parser.getContext(messages);
    defer parser.restoreContext(ctx);

    if (try FloatLiteral.peek(parser, messages)) |float| {
        return .{
            .value = .{ .float = float },
            .location = float.location,
        };
    }

    if (try Integer.peek(parser, messages)) |int| {
        return .{
            .value = .{ .int = int },
            .location = int.location,
        };
    }

    if (try ctx.expectSymbolsPeek(&.{ .true, .false })) |sym| {
        return .{
            .value = .{ .boolean = std.mem.eql(u8, sym.text, "true") },
            .location = sym.location,
        };
    }

    if (try ctx.expectSymbolPeek(.null)) |sym| {
        return .{
            .value = .null,
            .location = sym.location,
        };
    }
    return null;
}

pub fn accept(parser: *Parser, messages: *std.ArrayList(Parser.Message)) Parser.Error!ConstValue {
    var ctx = parser.getContext(messages);
    errdefer parser.restoreContext(ctx);

    if (try FloatLiteral.peek(parser, messages)) |float| {
        _ = try FloatLiteral.accept(parser, messages);
        return .{
            .value = .{ .float = float },
            .location = float.location,
        };
    }

    if (try Integer.peek(parser, messages)) |int| {
        _ = try Integer.accept(parser, messages);
        return .{
            .value = .{ .int = int },
            .location = int.location,
        };
    }

    if (try ctx.expectSymbolsPeek(&.{ .true, .false })) |sym| {
        _ = try ctx.expectSymbolsAccept(&.{ .true, .false });
        return .{
            .value = .{ .boolean = std.mem.eql(u8, sym.text, "true") },
            .location = sym.location,
        };
    }

    if (try ctx.expectSymbolPeek(.null)) |sym| {
        _ = try ctx.expectSymbolAccept(.null);
        return .{
            .value = .null,
            .location = sym.location,
        };
    }

    defer ctx.reset();
    ctx.expected = .{ .tokens = &.{ .symbol, .float, .int } };
    ctx.got = if (try ctx.peek()) |token| .{ .token = token.type } else null;
    try ctx.pushError(error.UnexpectedToken);
    return error.UnexpectedToken;
}

test "Parse const value float" {
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
    try std.testing.expectEqual(Value.float, std.meta.activeTag(value.value));
    try std.testing.expectEqual(@as(f64, 12345.67890), value.value.float.value);
}

test "Parse const value int" {
    const alloc = std.testing.allocator;

    var messages = std.ArrayList(Parser.Message).init(alloc);
    defer Parser.Message.deinit(&messages);

    var parser = try Parser.init(alloc,
        \\1234567890
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
    try std.testing.expectEqual(Value.int, std.meta.activeTag(value.value));
    try std.testing.expectEqual(@as(u64, 1234567890), value.value.int.value.unsigned);
}

test "Parse const value true" {
    const alloc = std.testing.allocator;

    var messages = std.ArrayList(Parser.Message).init(alloc);
    defer Parser.Message.deinit(&messages);

    var parser = try Parser.init(alloc,
        \\true
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
    try std.testing.expectEqual(Value.boolean, std.meta.activeTag(value.value));
    try std.testing.expectEqual(true, value.value.boolean);
}

test "Parse const value false" {
    const alloc = std.testing.allocator;

    var messages = std.ArrayList(Parser.Message).init(alloc);
    defer Parser.Message.deinit(&messages);

    var parser = try Parser.init(alloc,
        \\false
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
    try std.testing.expectEqual(Value.boolean, std.meta.activeTag(value.value));
    try std.testing.expectEqual(false, value.value.boolean);
}

test "Parse const value null" {
    const alloc = std.testing.allocator;

    var messages = std.ArrayList(Parser.Message).init(alloc);
    defer Parser.Message.deinit(&messages);

    var parser = try Parser.init(alloc,
        \\null
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
    try std.testing.expectEqual(Value.null, std.meta.activeTag(value.value));
}
