const std = @import("std");
const ptk = @import("parser-toolkit");
const Parser = @import("../../Parser.zig");
const UnsignedIntegerType = @import("UnsignedIntegerType.zig");
const UnrestrictedFloatType = @import("UnrestrictedFloatType.zig");
const IntegerType = @import("IntegerType.zig");
const Symbol = @import("Symbol.zig");
const PrimitiveType = @This();

pub const Type = union(enum) {
    unsignedIntegerType: UnsignedIntegerType,
    unrestrictedFloatType: UnrestrictedFloatType,
    undefined: void,
    boolean: void,
    byte: void,
    octet: void,
    bigint: void,
};

type: Type,
location: ptk.Location,

pub fn peek(parser: *Parser, messages: *std.ArrayList(Parser.Message)) Parser.Error!?PrimitiveType {
    var ctx = parser.getContext(messages);
    defer parser.restoreContext(ctx);

    if (try UnsignedIntegerType.peek(parser, messages)) |unsignedIntegerType| {
        _ = try UnsignedIntegerType.accept(parser, messages);
        return .{
            .type = .{ .unsignedIntegerType = unsignedIntegerType },
            .location = unsignedIntegerType.location,
        };
    }

    if (try UnrestrictedFloatType.peek(parser, messages)) |unrestrictedFloatType| {
        _ = try UnrestrictedFloatType.accept(parser, messages);
        return .{
            .type = .{ .unrestrictedFloatType = unrestrictedFloatType },
            .location = unrestrictedFloatType.location,
        };
    }

    if (try ctx.expectSymbolsPeek(&.{ .undefined, .boolean, .byte, .octet, .bigint })) |symbol| {
        _ = try ctx.expectSymbolsAccept(&.{ .undefined, .boolean, .byte, .octet, .bigint });
        return .{
            .type = switch (std.meta.stringToEnum(Symbol.Type, symbol.text).?) {
                .undefined => .undefined,
                .boolean => .boolean,
                .byte => .byte,
                .octet => .octet,
                .bigint => .bigint,
                else => unreachable,
            },
            .location = symbol.location,
        };
    }
    return null;
}

pub fn accept(parser: *Parser, messages: *std.ArrayList(Parser.Message)) Parser.Error!PrimitiveType {
    var ctx = parser.getContext(messages);
    errdefer parser.restoreContext(ctx);

    if (try UnsignedIntegerType.peek(parser, messages)) |unsignedIntegerType| {
        _ = try UnsignedIntegerType.accept(parser, messages);
        return .{
            .type = .{ .unsignedIntegerType = unsignedIntegerType },
            .location = unsignedIntegerType.location,
        };
    }

    if (try UnrestrictedFloatType.peek(parser, messages)) |unrestrictedFloatType| {
        _ = try UnrestrictedFloatType.accept(parser, messages);
        return .{
            .type = .{ .unrestrictedFloatType = unrestrictedFloatType },
            .location = unrestrictedFloatType.location,
        };
    }

    if (try ctx.expectSymbolsPeek(&.{ .undefined, .boolean, .byte, .octet, .bigint })) |symbol| {
        _ = try ctx.expectSymbolsAccept(&.{ .undefined, .boolean, .byte, .octet, .bigint });
        return .{
            .type = switch (std.meta.stringToEnum(Symbol.Type, symbol.text).?) {
                .undefined => .undefined,
                .boolean => .boolean,
                .byte => .byte,
                .octet => .octet,
                .bigint => .bigint,
                else => unreachable,
            },
            .location = symbol.location,
        };
    }

    defer ctx.reset();
    ctx.expected = .{ .symbols = &.{ .undefined, .boolean, .byte, .octet, .bigint, .float, .double, .unrestricted, .unsigned } };
    ctx.got = if (try ctx.peek()) |token| .{ .token = token.type } else null;
    try ctx.pushError(error.UnexpectedSymbol);
    return error.UnexpectedSymbol;
}

test "Parse primitive type long long" {
    const alloc = std.testing.allocator;

    var messages = std.ArrayList(Parser.Message).init(alloc);
    defer Parser.Message.deinit(&messages);

    var parser = try Parser.init(alloc,
        \\long long
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
    try std.testing.expectEqual(Type.unsignedIntegerType, std.meta.activeTag(value.type));
    try std.testing.expectEqual(false, value.type.unsignedIntegerType.isUnsigned);
    try std.testing.expectEqual(IntegerType.Type.longLong, value.type.unsignedIntegerType.type.type);
}

test "Parse primitive type long" {
    const alloc = std.testing.allocator;

    var messages = std.ArrayList(Parser.Message).init(alloc);
    defer Parser.Message.deinit(&messages);

    var parser = try Parser.init(alloc,
        \\long
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
    try std.testing.expectEqual(Type.unsignedIntegerType, std.meta.activeTag(value.type));
    try std.testing.expectEqual(false, value.type.unsignedIntegerType.isUnsigned);
    try std.testing.expectEqual(IntegerType.Type.long, value.type.unsignedIntegerType.type.type);
}

test "Parse primitive type short" {
    const alloc = std.testing.allocator;

    var messages = std.ArrayList(Parser.Message).init(alloc);
    defer Parser.Message.deinit(&messages);

    var parser = try Parser.init(alloc,
        \\short
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
    try std.testing.expectEqual(Type.unsignedIntegerType, std.meta.activeTag(value.type));
    try std.testing.expectEqual(false, value.type.unsignedIntegerType.isUnsigned);
    try std.testing.expectEqual(IntegerType.Type.short, value.type.unsignedIntegerType.type.type);
}

test "Parse primitive type unsigned long long" {
    const alloc = std.testing.allocator;

    var messages = std.ArrayList(Parser.Message).init(alloc);
    defer Parser.Message.deinit(&messages);

    var parser = try Parser.init(alloc,
        \\unsigned long long
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
    try std.testing.expectEqual(Type.unsignedIntegerType, std.meta.activeTag(value.type));
    try std.testing.expectEqual(true, value.type.unsignedIntegerType.isUnsigned);
    try std.testing.expectEqual(IntegerType.Type.longLong, value.type.unsignedIntegerType.type.type);
}

test "Parse primitive type unsigned long" {
    const alloc = std.testing.allocator;

    var messages = std.ArrayList(Parser.Message).init(alloc);
    defer Parser.Message.deinit(&messages);

    var parser = try Parser.init(alloc,
        \\unsigned long
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
    try std.testing.expectEqual(Type.unsignedIntegerType, std.meta.activeTag(value.type));
    try std.testing.expectEqual(true, value.type.unsignedIntegerType.isUnsigned);
    try std.testing.expectEqual(IntegerType.Type.long, value.type.unsignedIntegerType.type.type);
}

test "Parse primitive type unsigned short" {
    const alloc = std.testing.allocator;

    var messages = std.ArrayList(Parser.Message).init(alloc);
    defer Parser.Message.deinit(&messages);

    var parser = try Parser.init(alloc,
        \\unsigned short
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
    try std.testing.expectEqual(Type.unsignedIntegerType, std.meta.activeTag(value.type));
    try std.testing.expectEqual(true, value.type.unsignedIntegerType.isUnsigned);
    try std.testing.expectEqual(IntegerType.Type.short, value.type.unsignedIntegerType.type.type);
}

test "Parse primitive type undefined" {
    const alloc = std.testing.allocator;

    var messages = std.ArrayList(Parser.Message).init(alloc);
    defer Parser.Message.deinit(&messages);

    var parser = try Parser.init(alloc,
        \\undefined
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
    try std.testing.expectEqual(Type.undefined, std.meta.activeTag(value.type));
}

test "Parse primitive type boolean" {
    const alloc = std.testing.allocator;

    var messages = std.ArrayList(Parser.Message).init(alloc);
    defer Parser.Message.deinit(&messages);

    var parser = try Parser.init(alloc,
        \\boolean
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
    try std.testing.expectEqual(Type.boolean, std.meta.activeTag(value.type));
}

test "Parse primitive type byte" {
    const alloc = std.testing.allocator;

    var messages = std.ArrayList(Parser.Message).init(alloc);
    defer Parser.Message.deinit(&messages);

    var parser = try Parser.init(alloc,
        \\byte
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
    try std.testing.expectEqual(Type.byte, std.meta.activeTag(value.type));
}

test "Parse primitive type octet" {
    const alloc = std.testing.allocator;

    var messages = std.ArrayList(Parser.Message).init(alloc);
    defer Parser.Message.deinit(&messages);

    var parser = try Parser.init(alloc,
        \\octet
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
    try std.testing.expectEqual(Type.octet, std.meta.activeTag(value.type));
}

test "Parse primitive type bigint" {
    const alloc = std.testing.allocator;

    var messages = std.ArrayList(Parser.Message).init(alloc);
    defer Parser.Message.deinit(&messages);

    var parser = try Parser.init(alloc,
        \\bigint
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
    try std.testing.expectEqual(Type.bigint, std.meta.activeTag(value.type));
}
