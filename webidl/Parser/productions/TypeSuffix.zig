const std = @import("std");
const ptk = @import("parser-toolkit");
const Parser = @import("../../Parser.zig");
const TypeSuffixStartingWithArray = @import("TypeSuffixStartingWithArray.zig");
const TypeSuffix = @This();

pub const Value = union(enum) {
    default: *TypeSuffix,
    withArray: *TypeSuffixStartingWithArray,
};

location: ptk.Location,
value: ?Value,
isNullable: bool,
isArray: bool,

pub fn peek(parser: *Parser, messages: *std.ArrayList(Parser.Message)) Parser.Error!?TypeSuffix {
    var ctx = parser.getContext(messages);
    defer parser.restoreContext(ctx);

    if (try ctx.expectTokenPeek(.@"[")) |token| {
        _ = try ctx.expectTokenAccept(.@"[");

        _ = try ctx.expectTokenPeek(.@"]") orelse return null;
        _ = try ctx.expectTokenAccept(.@"]");

        var value: ?Value = null;

        if (try peek(parser, messages)) |peekDefault| {
            _ = try accept(parser, messages);

            const def = try parser.allocator.create(TypeSuffix);
            errdefer parser.allocator.destroy(def);
            def.* = peekDefault;

            value = .{ .default = def };
        }

        return .{
            .location = token.location,
            .value = value,
            .isArray = true,
            .isNullable = false,
        };
    } else if (try ctx.expectTokenPeek(.@"?")) |token| {
        _ = try ctx.expectTokenAccept(.@"?");

        var value: ?Value = null;

        if (try TypeSuffixStartingWithArray.peek(parser, messages)) |peekWithArray| {
            _ = try TypeSuffixStartingWithArray.accept(parser, messages);

            const withArray = try parser.allocator.create(TypeSuffixStartingWithArray);
            errdefer parser.allocator.destroy(withArray);
            withArray.* = peekWithArray;

            value = .{ .withArray = withArray };
        }

        return .{
            .location = token.location,
            .value = value,
            .isArray = false,
            .isNullable = true,
        };
    }
    return null;
}

pub fn accept(parser: *Parser, messages: *std.ArrayList(Parser.Message)) Parser.Error!TypeSuffix {
    var ctx = parser.getContext(messages);
    errdefer parser.restoreContext(ctx);

    if (try ctx.expectTokenPeek(.@"[")) |token| {
        _ = try ctx.expectTokenAccept(.@"[");
        _ = try ctx.expectTokenAccept(.@"]");

        var value: ?Value = null;

        if (try peek(parser, messages)) |peekDefault| {
            _ = try accept(parser, messages);

            const def = try parser.allocator.create(TypeSuffix);
            errdefer parser.allocator.destroy(def);
            def.* = peekDefault;

            value = .{ .default = def };
        }

        return .{
            .location = token.location,
            .value = value,
            .isArray = true,
            .isNullable = false,
        };
    } else if (try ctx.expectTokenPeek(.@"?")) |token| {
        _ = try ctx.expectTokenAccept(.@"?");

        var value: ?Value = null;

        if (try TypeSuffixStartingWithArray.peek(parser, messages)) |peekWithArray| {
            _ = try TypeSuffixStartingWithArray.accept(parser, messages);

            const withArray = try parser.allocator.create(TypeSuffixStartingWithArray);
            errdefer parser.allocator.destroy(withArray);
            withArray.* = peekWithArray;

            value = .{ .withArray = withArray };
        }

        return .{
            .location = token.location,
            .value = value,
            .isArray = false,
            .isNullable = true,
        };
    }

    defer ctx.reset();
    ctx.expected = .{ .tokens = &.{ .@"?", .@"[" } };
    ctx.got = if (try ctx.peek()) |token| .{ .token = token.type } else null;
    try ctx.pushError(error.UnexpectedSymbol);
    return error.UnexpectedSymbol;
}

pub fn deinit(self: *const TypeSuffix, parser: *Parser) void {
    if (self.value) |value| {
        switch (value) {
            .default => |def| {
                def.deinit(parser);
                parser.allocator.destroy(def);
            },
            .withArray => |withArray| {
                withArray.deinit(parser);
                parser.allocator.destroy(withArray);
            },
        }
    }
}

test "Parse type suffix with array" {
    const alloc = std.testing.allocator;

    var messages = std.ArrayList(Parser.Message).init(alloc);
    defer Parser.Message.deinit(&messages);

    var parser = try Parser.init(alloc,
        \\[]
    );
    defer parser.deinit();

    const value = accept(&parser, &messages) catch |err| {
        for (messages.items) |item| std.debug.print("{}\n", .{item});
        return err;
    };
    defer value.deinit(&parser);

    try std.testing.expectEqual(ptk.Location{
        .column = 1,
        .line = 1,
    }, value.location);
    try std.testing.expectEqual(@as(?Value, null), value.value);
    try std.testing.expectEqual(true, value.isArray);
    try std.testing.expectEqual(false, value.isNullable);
}

test "Parse type suffix with nullable" {
    const alloc = std.testing.allocator;

    var messages = std.ArrayList(Parser.Message).init(alloc);
    defer Parser.Message.deinit(&messages);

    var parser = try Parser.init(alloc,
        \\?
    );
    defer parser.deinit();

    const value = accept(&parser, &messages) catch |err| {
        for (messages.items) |item| std.debug.print("{}\n", .{item});
        return err;
    };
    defer value.deinit(&parser);

    try std.testing.expectEqual(ptk.Location{
        .column = 1,
        .line = 1,
    }, value.location);
    try std.testing.expectEqual(@as(?Value, null), value.value);
    try std.testing.expectEqual(false, value.isArray);
    try std.testing.expectEqual(true, value.isNullable);
}

test "Parse type suffix with nullable array" {
    const alloc = std.testing.allocator;

    var messages = std.ArrayList(Parser.Message).init(alloc);
    defer Parser.Message.deinit(&messages);

    var parser = try Parser.init(alloc,
        \\?[]
    );
    defer parser.deinit();

    const value = accept(&parser, &messages) catch |err| {
        for (messages.items) |item| std.debug.print("{}\n", .{item});
        return err;
    };
    defer value.deinit(&parser);

    try std.testing.expectEqual(ptk.Location{
        .column = 1,
        .line = 1,
    }, value.location);
    try std.testing.expect(value.value != null);
    try std.testing.expectEqual(Value.withArray, std.meta.activeTag(value.value.?));
    try std.testing.expectEqual(false, value.isArray);
    try std.testing.expectEqual(true, value.isNullable);
}
