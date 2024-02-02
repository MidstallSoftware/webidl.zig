const std = @import("std");
const ptk = @import("parser-toolkit");
const Parser = @import("../../Parser.zig");
const Identifier = @import("Identifier.zig");
const PrimitiveType = @import("PrimitiveType.zig");
const IntegerType = @import("IntegerType.zig");
const ConstType = @This();

pub const Type = union(enum) {
    identifier: Identifier,
    primitive: PrimitiveType,
};

type: Type,
isNullable: bool,
location: ptk.Location,

pub fn peek(parser: *Parser, messages: *std.ArrayList(Parser.Message)) Parser.Error!?ConstType {
    var ctx = parser.getContext(messages);
    defer parser.restoreContext(ctx);

    var self: ConstType = undefined;

    if (try PrimitiveType.peek(parser, messages)) |primitive| {
        _ = try PrimitiveType.accept(parser, messages);
        self.type = .{ .primitive = primitive };
        self.location = primitive.location;
    } else if (try Identifier.peek(parser, messages)) |identifier| {
        _ = try Identifier.accept(parser, messages);
        self.type = .{ .identifier = identifier };
        self.location = identifier.location;
    } else return null;

    if (try ctx.expectTokenPeek(.@"?")) |_| {
        self.isNullable = true;
    }
    return self;
}

pub fn accept(parser: *Parser, messages: *std.ArrayList(Parser.Message)) Parser.Error!ConstType {
    var ctx = parser.getContext(messages);
    errdefer parser.restoreContext(ctx);

    var self: ConstType = undefined;

    if (try PrimitiveType.peek(parser, messages)) |primitive| {
        _ = try PrimitiveType.accept(parser, messages);
        self.type = .{ .primitive = primitive };
        self.location = primitive.location;
    } else {
        const identifier = try Identifier.accept(parser, messages);
        self.type = .{ .identifier = identifier };
        self.location = identifier.location;
    }

    if (try ctx.expectTokenPeek(.@"?")) |_| {
        _ = try ctx.expectTokenAccept(.@"?");
        self.isNullable = true;
    }
    return self;
}

test "Parse const type primitive" {
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
    try std.testing.expectEqual(Type.primitive, std.meta.activeTag(value.type));
    try std.testing.expectEqual(false, value.isNullable);
    try std.testing.expectEqual(PrimitiveType.Type.unsignedIntegerType, std.meta.activeTag(value.type.primitive.type));
    try std.testing.expectEqual(false, value.type.primitive.type.unsignedIntegerType.isUnsigned);
    try std.testing.expectEqual(IntegerType.Type.longLong, value.type.primitive.type.unsignedIntegerType.type.type);
}

test "Parse const type nullable" {
    const alloc = std.testing.allocator;

    var messages = std.ArrayList(Parser.Message).init(alloc);
    defer Parser.Message.deinit(&messages);

    var parser = try Parser.init(alloc,
        \\long long?
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
    try std.testing.expectEqual(Type.primitive, std.meta.activeTag(value.type));
    try std.testing.expectEqual(true, value.isNullable);
    try std.testing.expectEqual(PrimitiveType.Type.unsignedIntegerType, std.meta.activeTag(value.type.primitive.type));
    try std.testing.expectEqual(false, value.type.primitive.type.unsignedIntegerType.isUnsigned);
    try std.testing.expectEqual(IntegerType.Type.longLong, value.type.primitive.type.unsignedIntegerType.type.type);
}
