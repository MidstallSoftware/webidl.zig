const std = @import("std");
const ptk = @import("parser-toolkit");
const Parser = @import("../../Parser.zig");
const IntegerType = @import("IntegerType.zig");
const UnsignedIntegerType = @This();

type: IntegerType,
isUnsigned: bool,
location: ptk.Location,

pub fn peek(parser: *Parser, messages: *std.ArrayList(Parser.Message)) Parser.Error!?UnsignedIntegerType {
    var ctx = parser.getContext(messages);
    defer parser.restoreContext(ctx);

    var self: UnsignedIntegerType = undefined;

    if (try ctx.expectSymbolPeek(.unsigned)) |token| {
        _ = try ctx.expectSymbolAccept(.unsigned);
        self.location = token.location;
        self.isUnsigned = true;
    }

    self.type = try IntegerType.peek(parser, messages) orelse return null;
    if (!self.isUnsigned) self.location = self.type.location;
    return self;
}

pub fn accept(parser: *Parser, messages: *std.ArrayList(Parser.Message)) Parser.Error!UnsignedIntegerType {
    var ctx = parser.getContext(messages);
    errdefer parser.restoreContext(ctx);

    var self: UnsignedIntegerType = undefined;

    if (try ctx.expectSymbolPeek(.unsigned)) |token| {
        _ = try ctx.expectSymbolAccept(.unsigned);
        self.location = token.location;
        self.isUnsigned = true;
    }

    self.type = try IntegerType.accept(parser, messages);
    if (!self.isUnsigned) self.location = self.type.location;
    return self;
}

pub fn maxInt(self: UnsignedIntegerType) usize {
    if (self.isUnsigned) {
        return switch (self.type.type) {
            .long => std.math.maxInt(c_ulong),
            .short => std.math.maxInt(c_ushort),
            .longLong => std.math.maxInt(c_ulonglong),
        };
    }
    return self.type.maxInt();
}

pub fn minInt(self: UnsignedIntegerType) isize {
    if (self.isUnsigned) {
        return switch (self.type.type) {
            .long => std.math.minInt(c_ulong),
            .short => std.math.minInt(c_ushort),
            .longLong => std.math.minInt(c_ulonglong),
        };
    }
    return self.type.minInt();
}

test "Parse unsigned integer type long" {
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
    try std.testing.expectEqual(IntegerType.Type.long, value.type.type);
    try std.testing.expectEqual(true, value.isUnsigned);
    try std.testing.expectEqual(std.math.maxInt(c_ulong), value.maxInt());
    try std.testing.expectEqual(std.math.minInt(c_ulong), value.minInt());
}

test "Parse unsigned integer type short" {
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
    try std.testing.expectEqual(IntegerType.Type.short, value.type.type);
    try std.testing.expectEqual(true, value.isUnsigned);
    try std.testing.expectEqual(std.math.maxInt(c_ushort), value.maxInt());
    try std.testing.expectEqual(std.math.minInt(c_ushort), value.minInt());
}

test "Parse unsigned integer type long long" {
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
    try std.testing.expectEqual(IntegerType.Type.longLong, value.type.type);
    try std.testing.expectEqual(true, value.isUnsigned);
    try std.testing.expectEqual(std.math.maxInt(c_ulonglong), value.maxInt());
    try std.testing.expectEqual(std.math.minInt(c_ulonglong), value.minInt());
}
