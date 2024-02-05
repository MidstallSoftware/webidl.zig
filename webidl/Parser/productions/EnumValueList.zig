const std = @import("std");
const ptk = @import("parser-toolkit");
const Parser = @import("../../Parser.zig");
const Identifier = @import("Identifier.zig");
const EnumValueList = @This();

list: std.ArrayListUnmanaged(Identifier),
location: ptk.Location,

pub fn peek(parser: *Parser, messages: *std.ArrayList(Parser.Message)) Parser.Error!?EnumValueList {
    var ctx = parser.getContext(messages);
    defer parser.restoreContext(ctx);

    const start = try ctx.expectTokenPeek(.@"{") orelse return null;
    _ = try ctx.expectTokenAccept(.@"{");

    var list = std.ArrayListUnmanaged(Identifier){};
    errdefer list.deinit(parser.allocator);

    while (try Identifier.peek(parser, messages)) |ident| {
        _ = try Identifier.accept(parser, messages);
        try list.append(parser.allocator, ident);

        const token = try ctx.expectTokensAccept(&.{ .@",", .@"}" });
        if (token.type == .@"}") {
            return .{
                .list = list,
                .location = start.location,
            };
        }
    }

    _ = try ctx.expectTokenAccept(.@"}");

    return .{
        .list = list,
        .location = start.location,
    };
}

pub fn accept(parser: *Parser, messages: *std.ArrayList(Parser.Message)) Parser.Error!EnumValueList {
    var ctx = parser.getContext(messages);
    errdefer parser.restoreContext(ctx);

    const start = try ctx.expectTokenAccept(.@"{");

    var list = std.ArrayListUnmanaged(Identifier){};
    errdefer list.deinit(parser.allocator);

    while (try Identifier.peek(parser, messages)) |ident| {
        _ = try Identifier.accept(parser, messages);
        try list.append(parser.allocator, ident);

        const token = try ctx.expectTokensAccept(&.{ .@",", .@"}" });
        if (token.type == .@"}") {
            return .{
                .list = list,
                .location = start.location,
            };
        }
    }

    _ = try ctx.expectTokenAccept(.@"}");

    return .{
        .list = list,
        .location = start.location,
    };
}

pub inline fn deinit(self: *EnumValueList, parser: *Parser) void {
    self.list.deinit(parser.allocator);
}

test "Parse enum value list" {
    const alloc = std.testing.allocator;

    var messages = std.ArrayList(Parser.Message).init(alloc);
    defer Parser.Message.deinit(&messages);

    var parser = try Parser.init(alloc,
        \\{
        \\  a,
        \\  b,
        \\  c
        \\}
    );
    defer parser.deinit();

    var value = accept(&parser, &messages) catch |err| {
        for (messages.items) |item| std.debug.print("{}\n", .{item});
        return err;
    };
    defer value.deinit(&parser);

    try std.testing.expectEqual(ptk.Location{
        .column = 1,
        .line = 1,
    }, value.location);
    try std.testing.expectEqual(@as(usize, 3), value.list.items.len);
    try std.testing.expectEqualStrings("a", value.list.items[0].name);
    try std.testing.expectEqualStrings("b", value.list.items[1].name);
    try std.testing.expectEqualStrings("c", value.list.items[2].name);
}
