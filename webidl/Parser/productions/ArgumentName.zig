const std = @import("std");
const ptk = @import("parser-toolkit");
const Parser = @import("../../Parser.zig");
const Symbol = @import("Symbol.zig");
const ArgumentName = @This();

pub const Type = enum {
    @"async",
    attribute,
    callback,
    @"const",
    constructor,
    deleter,
    dictionary,
    @"enum",
    getter,
    includes,
    inherit,
    interface,
    iterable,
    maplike,
    namespace,
    partial,
    required,
    setlike,
    setter,
    static,
    stringifier,
    typedef,
    unrestricted,

    pub fn toSymbol(t: Type) Symbol.Type {
        inline for (comptime std.meta.fields(Type)) |field| {
            if (field.value == @intFromEnum(t)) {
                return std.meta.stringToEnum(Symbol.Type, field.name) orelse unreachable;
            }
        }
        unreachable;
    }
};

type: Type,
location: ptk.Location,

pub fn peek(parser: *Parser, messages: *std.ArrayList(Parser.Message)) Parser.Error!?ArgumentName {
    var ctx = parser.getContext(messages);
    defer parser.restoreContext(ctx);

    const token = try ctx.expectTokenPeek(.symbol) orelse return null;
    return .{
        .location = token.location,
        .type = std.meta.stringToEnum(Type, token.text) orelse return null,
    };
}

pub fn accept(parser: *Parser, messages: *std.ArrayList(Parser.Message)) Parser.Error!ArgumentName {
    var ctx = parser.getContext(messages);
    errdefer parser.restoreContext(ctx);

    const token = try ctx.expectTokenAccept(.symbol);
    return .{
        .location = token.location,
        .type = std.meta.stringToEnum(Type, token.text) orelse return error.UnexpectedToken,
    };
}

pub fn asSymbol(self: ArgumentName) Symbol {
    return .{
        .location = self.location,
        .type = self.type.toSymbol(),
    };
}
