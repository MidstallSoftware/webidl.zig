const std = @import("std");
const ptk = @import("parser-toolkit");
const Parser = @import("../../Parser.zig");
const IntegerType = @This();

pub const Type = enum {
    long,
    short,
    longLong,

    pub fn maxInt(self: Type) usize {
        return switch (self) {
            .long => std.math.maxInt(c_long),
            .short => std.math.maxInt(c_short),
            .longLong => std.math.maxInt(c_longlong),
        };
    }

    pub fn minInt(self: Type) isize {
        return switch (self) {
            .long => std.math.minInt(c_long),
            .short => std.math.minInt(c_short),
            .longLong => std.math.minInt(c_longlong),
        };
    }
};

type: Type,
location: ptk.Location,

pub fn peek(parser: *Parser, messages: *std.ArrayList(Parser.Message)) Parser.Error!?IntegerType {
    var ctx = parser.getContext(messages);
    defer parser.restoreContext(ctx);

    _ = try ctx.expectSymbolsPeek(&.{ .long, .short }) orelse return null;
    const first = try ctx.expectSymbolsAccept(&.{ .long, .short });
    var value = std.meta.stringToEnum(Type, first.text).?;

    if (value == .long) {
        if (try ctx.expectSymbolPeek(.long)) |_| {
            value = .longLong;
        }
    }

    return .{
        .location = first.location,
        .type = value,
    };
}

pub fn accept(parser: *Parser, messages: *std.ArrayList(Parser.Message)) Parser.Error!IntegerType {
    var ctx = parser.getContext(messages);
    errdefer parser.restoreContext(ctx);

    const first = try ctx.expectSymbolsAccept(&.{ .long, .short });
    var value = std.meta.stringToEnum(Type, first.text).?;

    if (value == .long) {
        if (try ctx.expectSymbolPeek(.long)) |_| {
            _ = try ctx.expectSymbolAccept(.long);
            value = .longLong;
        }
    }

    return .{
        .location = first.location,
        .type = value,
    };
}

pub inline fn maxInt(self: IntegerType) usize {
    return self.type.maxInt();
}

pub inline fn minInt(self: IntegerType) isize {
    return self.type.minInt();
}

test "Parse integer type long" {
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
    try std.testing.expectEqual(Type.long, value.type);
    try std.testing.expectEqual(std.math.maxInt(c_long), value.maxInt());
    try std.testing.expectEqual(std.math.minInt(c_long), value.minInt());
}

test "Parse integer type short" {
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
    try std.testing.expectEqual(Type.short, value.type);
    try std.testing.expectEqual(std.math.maxInt(c_short), value.maxInt());
    try std.testing.expectEqual(std.math.minInt(c_short), value.minInt());
}

test "Parse integer type long long" {
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
    try std.testing.expectEqual(Type.longLong, value.type);
    try std.testing.expectEqual(std.math.maxInt(c_longlong), value.maxInt());
    try std.testing.expectEqual(std.math.minInt(c_longlong), value.minInt());
}
