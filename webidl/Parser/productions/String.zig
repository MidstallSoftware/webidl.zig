const std = @import("std");
const ptk = @import("parser-toolkit");
const Parser = @import("../../Parser.zig");
const String = @This();

text: []const u8,
location: ptk.Location,

pub fn peek(parser: *Parser, messages: *std.ArrayList(Parser.Message)) Parser.Error!?String {
    var ctx = parser.getContext(messages);
    defer parser.restoreContext(ctx);

    const token = try ctx.expectTokenPeek(.string) orelse return null;

    return .{
        .location = token.location,
        .text = token.text[1..(token.text.len - 1)],
    };
}

pub fn accept(parser: *Parser, messages: *std.ArrayList(Parser.Message)) Parser.Error!String {
    var ctx = parser.getContext(messages);
    defer parser.restoreContext(ctx);

    const token = try ctx.expectTokenAccept(.string);
    return .{
        .location = token.location,
        .text = token.text[1..(token.text.len - 1)],
    };
}

test "Parse string" {
    const alloc = std.testing.allocator;

    var messages = std.ArrayList(Parser.Message).init(alloc);
    defer Parser.Message.deinit(&messages);

    var parser = try Parser.init(alloc,
        \\"Hello, world"
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
    try std.testing.expectEqualStrings("Hello, world", value.text);
}
