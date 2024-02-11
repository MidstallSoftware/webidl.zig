const std = @import("std");
const ptk = @import("parser-toolkit");
const Parser = @import("../../Parser.zig");
const ArgumentName = @import("../productions/ArgumentName.zig");
const Default = @import("../productions/Default.zig");
const ExtendedAttributeList = @import("../productions/ExtendedAttributeList.zig");
const IgnoreInOut = @import("../productions/IgnoreInOut.zig");
const Type = @import("../productions/Type.zig");
const TypeWithExtendedAttributes = @import("../productions/TypeWithExtendedAttributes.zig");
const Argument = @This();

pub const TypeValue = union(enum) {
    default: Type,
    withExtendedAttributes: TypeWithExtendedAttributes,
};

location: ptk.Location,
isOptional: bool,
isVariadic: bool,
extendedAttributeList: ?ExtendedAttributeList,
type: TypeValue,
inOut: ?IgnoreInOut,
name: ArgumentName,
default: ?Default,

pub fn peek(parser: *Parser, messages: *std.ArrayList(Parser.Message)) Parser.Error!?Argument {
    var ctx = parser.getContext(messages);
    defer parser.restoreContext(ctx);

    const extendedAttributeList = try ExtendedAttributeList.peek(parser, messages);
    if (extendedAttributeList != null) _ = try ExtendedAttributeList.accept(parser, messages);

    if (try ctx.expectSymbolPeek(.optional)) |optional| {
        _ = try ctx.expectSymbolAccept(.optional);

        const inOut = try IgnoreInOut.peek(parser, messages);
        if (inOut != null) _ = try IgnoreInOut.accept(parser, messages);

        const withExtendedAttributes = try TypeWithExtendedAttributes.peek(parser, messages) orelse return null;
        _ = try TypeWithExtendedAttributes.accept(parser, messages);

        const name = try ArgumentName.peek(parser, messages) orelse return null;
        _ = try ArgumentName.accept(parser, messages);

        const def = try Default.peek(parser, messages);
        if (def != null) _ = try Default.accept(parser, messages);

        return .{
            .location = if (extendedAttributeList) |eat| eat.location else optional.location,
            .isOptional = true,
            .isVariadic = false,
            .extendedAttributeList = extendedAttributeList,
            .type = .{ .withExtendedAttributes = withExtendedAttributes },
            .inOut = inOut,
            .name = name,
            .default = def,
        };
    }

    const inOut = try IgnoreInOut.peek(parser, messages);
    if (inOut != null) _ = try IgnoreInOut.accept(parser, messages);

    const t = try Type.peek(parser, messages) orelse return null;
    _ = try Type.accept(parser, messages);

    const isVariadic = blk: {
        if (try ctx.expectTokenPeek(.@"...")) |_| {
            _ = try ctx.expectTokenAccept(.@"...");
            break :blk true;
        }
        break :blk false;
    };

    const name = try ArgumentName.peek(parser, messages) orelse return null;
    _ = try ArgumentName.accept(parser, messages);
    return .{
        .location = if (extendedAttributeList) |eat| eat.location else if (inOut) |io| io.location else t.location,
        .isOptional = false,
        .isVariadic = isVariadic,
        .extendedAttributeList = extendedAttributeList,
        .type = .{ .default = t },
        .name = name,
        .default = null,
    };
}

pub fn accept(parser: *Parser, messages: *std.ArrayList(Parser.Message)) Parser.Error!Argument {
    var ctx = parser.getContext(messages);
    errdefer parser.restoreContext(ctx);

    const extendedAttributeList = try ExtendedAttributeList.peek(parser, messages);
    if (extendedAttributeList != null) _ = try ExtendedAttributeList.accept(parser, messages);

    if (try ctx.expectSymbolPeek(.optional)) |optional| {
        _ = try ctx.expectSymbolAccept(.optional);

        const inOut = try IgnoreInOut.peek(parser, messages);
        if (inOut != null) _ = try IgnoreInOut.accept(parser, messages);

        const withExtendedAttributes = try TypeWithExtendedAttributes.accept(parser, messages);

        const name = try ArgumentName.accept(parser, messages);

        const def = try Default.peek(parser, messages);
        if (def != null) _ = try Default.accept(parser, messages);

        return .{
            .location = if (extendedAttributeList) |eat| eat.location else optional.location,
            .isOptional = true,
            .isVariadic = false,
            .extendedAttributeList = extendedAttributeList,
            .type = .{ .withExtendedAttributes = withExtendedAttributes },
            .inOut = inOut,
            .name = name,
            .default = def,
        };
    }

    const inOut = try IgnoreInOut.peek(parser, messages);
    if (inOut != null) _ = try IgnoreInOut.accept(parser, messages);

    const t = try Type.accept(parser, messages);

    const isVariadic = blk: {
        if (try ctx.expectTokenPeek(.@"...")) |_| {
            _ = try ctx.expectTokenAccept(.@"...");
            break :blk true;
        }
        break :blk false;
    };

    const name = try ArgumentName.accept(parser, messages);
    return .{
        .location = if (extendedAttributeList) |eat| eat.location else if (inOut) |io| io.location else t.location,
        .isOptional = false,
        .isVariadic = isVariadic,
        .extendedAttributeList = extendedAttributeList,
        .type = .{ .default = t },
        .name = name,
        .default = null,
    };
}

pub fn deinit(self: *const Argument, parser: *Parser) void {
    if (self.extendedAttributeList) |extendedAttributeList| extendedAttributeList.deinit(parser);
}
