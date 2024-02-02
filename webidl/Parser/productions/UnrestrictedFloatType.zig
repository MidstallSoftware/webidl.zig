const std = @import("std");
const ptk = @import("parser-toolkit");
const Parser = @import("../../Parser.zig");
const FloatType = @import("FloatType.zig");
const UnrestrictedFloatType = @This();

type: FloatType,
location: ptk.Location,

pub fn peek(parser: *Parser, messages: *std.ArrayList(Parser.Message)) Parser.Error!?UnrestrictedFloatType {
    var ctx = parser.getContext(messages);
    defer parser.restoreContext(ctx);

    _ = try ctx.expectSymbolPeek(.unrestricted) orelse return null;
    const token = try ctx.expectSymbolAccept(.unrestricted);
    const subtype = try FloatType.peek(parser, messages) orelse return null;

    return .{
        .location = token.location,
        .type = subtype,
    };
}

pub fn accept(parser: *Parser, messages: *std.ArrayList(Parser.Message)) Parser.Error!UnrestrictedFloatType {
    var ctx = parser.getContext(messages);
    errdefer parser.restoreContext(ctx);

    const token = try ctx.expectSymbolAccept(.unrestricted);
    const subtype = try FloatType.accept(parser, messages);

    return .{
        .location = token.location,
        .type = subtype,
    };
}

test "Parse unrestricted float type double" {
    const alloc = std.testing.allocator;

    var messages = std.ArrayList(Parser.Message).init(alloc);
    defer Parser.Message.deinit(&messages);

    var parser = try Parser.init(alloc,
        \\unrestricted double
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
    try std.testing.expectEqual(FloatType.Type.double, value.type.type);
}

test "Parse unrestricted float type float" {
    const alloc = std.testing.allocator;

    var messages = std.ArrayList(Parser.Message).init(alloc);
    defer Parser.Message.deinit(&messages);

    var parser = try Parser.init(alloc,
        \\unrestricted float
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
    try std.testing.expectEqual(FloatType.Type.float, value.type.type);
}
