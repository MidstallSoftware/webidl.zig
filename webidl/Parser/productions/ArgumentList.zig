const std = @import("std");
const ptk = @import("parser-toolkit");
const Parser = @import("../../Parser.zig");
const Argument = @import("../constructs/Argument.zig");
const ArgumentList = @This();

location: ptk.Location,
list: std.ArrayListUnmanaged(Argument),

pub fn peek(parser: *Parser, messages: *std.ArrayList(Parser.Message)) Parser.Error!?ArgumentList {
    var ctx = parser.getContext(messages);
    defer parser.restoreContext(ctx);

    var list = std.ArrayListUnmanaged(Argument){};
    errdefer {
        for (list.items) |arg| arg.deinit(parser);
        list.deinit(parser.allocator);
    }

    while (try Argument.peek(parser, messages)) |arg| {
        _ = try Argument.accept(parser, messages);
        try list.append(parser.allocator, arg);

        if (try ctx.expectTokenPeek(.@",")) |_| {
            try ctx.expectTokenAccept(.@",");
            continue;
        }

        break;
    }

    if (list.items.len == 0) return null;

    return .{
        .list = list,
        .location = list.items[0].location,
    };
}

pub fn accept(parser: *Parser, messages: *std.ArrayList(Parser.Message)) Parser.Error!ArgumentList {
    var ctx = parser.getContext(messages);
    defer parser.restoreContext(ctx);

    var list = std.ArrayListUnmanaged(Argument){};
    errdefer {
        for (list.items) |arg| arg.deinit(parser);
        list.deinit(parser.allocator);
    }

    while (try Argument.peek(parser, messages)) |arg| {
        _ = try Argument.accept(parser, messages);
        try list.append(parser.allocator, arg);

        if (try ctx.expectTokenPeek(.@",")) |_| {
            try ctx.expectTokenAccept(.@",");
            continue;
        }

        break;
    }

    if (list.items.len == 0) {
        defer ctx.reset();
        ctx.expected = .{ .token = .@"," };
        ctx.got = if (try ctx.peek()) |token| .{ .token = token.type } else null;
        try ctx.pushError(error.UnexpectedSymbol);
        return error.UnexpectedSymbol;
    }

    return .{
        .list = list,
        .location = list.items[0].location,
    };
}

pub fn deinit(self: *const ArgumentList, parser: *Parser) void {
    for (self.list.item) |arg| arg.deinit(self);
    self.list.deinit(parser.allocator);
}
