const std = @import("std");
const ptk = @import("parser-toolkit");
const Parser = @import("../../Parser.zig");
const Symbol = @This();

pub const Type = enum {
    any,
    @"async",
    attribute,
    ArrayBuffer,
    bigint,
    boolean,
    byte,
    ByteString,
    callback,
    @"const",
    constructor,
    creator,
    DataView,
    deleter,
    dictionary,
    DOMString,
    double,
    @"enum",
    Error,
    false,
    float,
    Float32Array,
    Float64Array,
    FrozenArray,
    getter,
    implements,
    includes,
    Infinity,
    @"-Infinity",
    inherit,
    Int8Array,
    Int16Array,
    Int32Array,
    interface,
    iterable,
    legacycaller,
    legacyiterable,
    long,
    maplike,
    mixin,
    namespace,
    NaN,
    null,
    object,
    ObservableArray,
    octet,
    optional,
    @"or",
    partial,
    Promise,
    readonly,
    record,
    required,
    sequence,
    setlike,
    setter,
    short,
    static,
    stringifier,
    true,
    typedef,
    Uint8Array,
    Uint16Array,
    Uint32Array,
    Uint8ClampedArray,
    undefined,
    unrestricted,
    unsigned,
    USVString,
};

type: Type,
location: ptk.Location,

pub fn peek(parser: *Parser, messages: *std.ArrayList(Parser.Message)) Parser.Error!?Symbol {
    var ctx = parser.getContext(messages);
    defer parser.restoreContext(ctx);

    const token = try ctx.expectTokenPeek(.symbol) orelse return null;
    return .{
        .location = token.location,
        .type = std.meta.stringToEnum(Type, token.text) orelse return null,
    };
}

pub fn accept(parser: *Parser, messages: *std.ArrayList(Parser.Message)) Parser.Error!Symbol {
    var ctx = parser.getContext(messages);
    errdefer parser.restoreContext(ctx);

    const token = try ctx.expectTokenAccept(.symbol);
    return .{
        .location = token.location,
        .type = std.meta.stringToEnum(Type, token.text) orelse return error.UnexpectedToken,
    };
}

test "Parse symbol" {
    const alloc = std.testing.allocator;

    inline for (comptime std.meta.fields(Type)) |field| {
        var messages = std.ArrayList(Parser.Message).init(alloc);
        defer Parser.Message.deinit(&messages);

        var parser = try Parser.init(alloc, field.name);
        defer parser.deinit();

        const value = accept(&parser, &messages) catch |err| {
            for (messages.items) |item| std.debug.print("{}\n", .{item});
            return err;
        };

        try std.testing.expectEqual(ptk.Location{
            .column = 1,
            .line = 1,
        }, value.location);
        try std.testing.expectEqual(@as(Type, @enumFromInt(field.value)), value.type);
    }
}
