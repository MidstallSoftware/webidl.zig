const std = @import("std");
const Allocator = std.mem.Allocator;
const ptk = @import("parser-toolkit");
const Self = @This();
const Parser = @import("../Parser.zig");

pub const Error = error{};

location: ptk.Location,
tag: []const u8,
message: []const u8,

pub fn pushError(list: *std.ArrayList(Self), err: Parser.Error, ctx: Parser.Context) Allocator.Error!void {
    const msg = try (switch (err) {
        error.UnexpectedToken => std.fmt.allocPrint(list.allocator, "Expected token {?}, got token {?}", .{ ctx.expectedToken, ctx.token }),
        else => std.fmt.allocPrint(list.allocator, "Internal error", .{}),
    });
    errdefer list.allocator.free(msg);

    try list.append(.{
        .location = ctx.state.location,
        .tag = @errorName(err),
        .message = msg,
    });
}

pub fn deinit(list: *std.ArrayList(Self)) void {
    for (list.items) |item| list.allocator.free(item.message);
    list.deinit();
}

pub fn format(self: Self, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
    _ = fmt;
    _ = options;

    try writer.print("{}: {s}: {s}", .{ self.location, self.tag, self.message });
}

test "Parser message push error" {
    var list = std.ArrayList(Self).init(std.testing.allocator);
    defer deinit(&list);

    try pushError(&list, error.OutOfMemory, .{
        .core = undefined,
        .state = .{
            .offset = 0,
            .location = .{
                .line = 0,
                .column = 0,
            },
        },
        .messages = &list,
    });
}
