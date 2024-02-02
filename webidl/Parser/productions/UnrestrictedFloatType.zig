const std = @import("std");
const ptk = @import("parser-toolkit");
const Parser = @import("../../Parser.zig");
const FloatType = @import("FloatType.zig");
const UnrestrictedFloatType = @This();

type: FloatType,
isUnrestricted: bool,
location: ptk.Location,

pub fn peek(parser: *Parser, messages: *std.ArrayList(Parser.Message)) Parser.Error!?UnrestrictedFloatType {
    var ctx = parser.getContext(messages);
    defer parser.restoreContext(ctx);

    var self: UnrestrictedFloatType = undefined;

    if (try ctx.expectSymbolPeek(.unrestricted)) |token| {
        _ = try ctx.expectSymbolAccept(.unrestricted);
        self.location = token.location;
        self.isUnrestricted = true;
    }

    self.type = try FloatType.peek(parser, messages) orelse return null;
    if (!self.isUnrestricted) self.location = self.type.location;
    return self;
}

pub fn accept(parser: *Parser, messages: *std.ArrayList(Parser.Message)) Parser.Error!UnrestrictedFloatType {
    var ctx = parser.getContext(messages);
    errdefer parser.restoreContext(ctx);

    var self: UnrestrictedFloatType = undefined;

    if (try ctx.expectSymbolPeek(.unrestricted)) |token| {
        _ = try ctx.expectSymbolAccept(.unrestricted);
        self.location = token.location;
        self.isUnrestricted = true;
    }

    self.type = try FloatType.accept(parser, messages);
    if (!self.isUnrestricted) self.location = self.type.location;
    return self;
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
    try std.testing.expectEqual(true, value.isUnrestricted);
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
    try std.testing.expectEqual(true, value.isUnrestricted);
    try std.testing.expectEqual(FloatType.Type.float, value.type.type);
}
