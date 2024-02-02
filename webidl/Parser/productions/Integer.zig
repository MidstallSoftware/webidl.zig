const std = @import("std");
const ptk = @import("parser-toolkit");
const Parser = @import("../../Parser.zig");
const Integer = @This();

pub const Value = union(std.builtin.Signedness) {
    signed: i64,
    unsigned: u64,

    pub fn parse(sign: std.builtin.Signedness, text: []const u8) !Value {
        return if (sign == .signed) .{
            .signed = try std.fmt.parseInt(i64, text, 10) * -1,
        } else .{
            .unsigned = try std.fmt.parseInt(u64, text, 10),
        };
    }
};

value: Value,
location: ptk.Location,

pub fn peek(parser: *Parser, messages: *std.ArrayList(Parser.Message)) Parser.Error!?Integer {
    var ctx = parser.getContext(messages);
    defer parser.restoreContext(ctx);

    var sign: std.builtin.Signedness = .unsigned;
    var location: ?ptk.Location = null;

    if (try ctx.expectTokenPeek(.@"-")) |token| {
        _ = try ctx.expectTokenAccept(.@"-");
        location = token.location;
        sign = .signed;
    }

    const token = try ctx.expectTokenPeek(.int) orelse return null;
    return .{
        .value = Value.parse(sign, token.text) catch return null,
        .location = location orelse token.location,
    };
}

pub fn accept(parser: *Parser, messages: *std.ArrayList(Parser.Message)) Parser.Error!Integer {
    var ctx = parser.getContext(messages);
    errdefer parser.restoreContext(ctx);

    var sign: std.builtin.Signedness = .unsigned;
    var location: ?ptk.Location = null;

    if (try ctx.expectTokenPeek(.@"-")) |token| {
        _ = try ctx.expectTokenAccept(.@"-");
        location = token.location;
        sign = .signed;
    }

    const token = try ctx.expectTokenAccept(.int);
    return .{
        .value = try Value.parse(sign, token.text),
        .location = location orelse token.location,
    };
}

test "Parse integer signed" {
    const alloc = std.testing.allocator;

    var messages = std.ArrayList(Parser.Message).init(alloc);
    defer Parser.Message.deinit(&messages);

    var parser = try Parser.init(alloc,
        \\-100
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
    try std.testing.expectEqual(std.builtin.Signedness.signed, std.meta.activeTag(value.value));
    try std.testing.expectEqual(@as(i64, -100), value.value.signed);
}

test "Parse integer unsigned" {
    const alloc = std.testing.allocator;

    var messages = std.ArrayList(Parser.Message).init(alloc);
    defer Parser.Message.deinit(&messages);

    var parser = try Parser.init(alloc,
        \\100
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
    try std.testing.expectEqual(std.builtin.Signedness.unsigned, std.meta.activeTag(value.value));
    try std.testing.expectEqual(@as(u64, 100), value.value.unsigned);
}
