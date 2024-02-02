const std = @import("std");
const ptk = @import("parser-toolkit");
const Parser = @import("../../Parser.zig");
const FloatType = @This();

pub const Type = enum {
    double,
    float,

    pub fn maxFloat(self: Type) f64 {
        return switch (self) {
            .double => std.math.floatMax(f64),
            .float => std.math.floatMax(f32),
        };
    }

    pub fn minFloat(self: Type) f64 {
        return switch (self) {
            .double => std.math.floatMin(f64),
            .float => std.math.floatMin(f32),
        };
    }
};

type: Type,
location: ptk.Location,

pub fn peek(parser: *Parser, messages: *std.ArrayList(Parser.Message)) Parser.Error!?FloatType {
    var ctx = parser.getContext(messages);
    defer parser.restoreContext(ctx);

    _ = try ctx.expectSymbolsPeek(&.{ .float, .double }) orelse return null;
    const token = try ctx.expectSymbolsAccept(&.{ .float, .double });
    const value = std.meta.stringToEnum(Type, token.text).?;

    return .{
        .location = token.location,
        .type = value,
    };
}

pub fn accept(parser: *Parser, messages: *std.ArrayList(Parser.Message)) Parser.Error!FloatType {
    var ctx = parser.getContext(messages);
    errdefer parser.restoreContext(ctx);

    const token = try ctx.expectSymbolsAccept(&.{ .float, .double });
    const value = std.meta.stringToEnum(Type, token.text).?;

    return .{
        .location = token.location,
        .type = value,
    };
}

pub inline fn maxFloat(self: FloatType) f64 {
    return self.type.maxFloat();
}

pub inline fn minFloat(self: FloatType) f64 {
    return self.type.minFloat();
}

test "Parse float type double" {
    const alloc = std.testing.allocator;

    var messages = std.ArrayList(Parser.Message).init(alloc);
    defer Parser.Message.deinit(&messages);

    var parser = try Parser.init(alloc,
        \\double
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
    try std.testing.expectEqual(Type.double, value.type);
    try std.testing.expectEqual(std.math.floatMax(f64), value.maxFloat());
    try std.testing.expectEqual(std.math.floatMin(f64), value.minFloat());
}

test "Parse float type float" {
    const alloc = std.testing.allocator;

    var messages = std.ArrayList(Parser.Message).init(alloc);
    defer Parser.Message.deinit(&messages);

    var parser = try Parser.init(alloc,
        \\float
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
    try std.testing.expectEqual(Type.float, value.type);
    try std.testing.expectEqual(std.math.floatMax(f32), value.maxFloat());
    try std.testing.expectEqual(std.math.floatMin(f32), value.minFloat());
}
