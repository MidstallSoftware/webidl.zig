const std = @import("std");
const Allocator = std.mem.Allocator;
const ptk = @import("parser-toolkit");
const Self = @This();

pub const Message = @import("Parser/Message.zig");
pub const Context = @import("Parser/Context.zig");
pub const productions = @import("Parser/productions.zig");

pub const TokenType = enum {
    whitespace,
    int,
    float,
    typedef,
    identifier,
    @"or",
    @"(",
    @")",
    @";",
    string,
};

const Pattern = ptk.Pattern(TokenType);
pub const ruleset = ptk.RuleSet(TokenType);

pub const Tokenizer = ptk.Tokenizer(TokenType, &[_]Pattern{
    Pattern.create(.whitespace, ptk.matchers.whitespace),
    Pattern.create(.int, ptk.matchers.decimalNumber),
    Pattern.create(.float, ptk.matchers.sequenceOf(.{ ptk.matchers.decimalNumber, ptk.matchers.literal("."), ptk.matchers.decimalNumber })),
    Pattern.create(.typedef, ptk.matchers.literal("typedef")),
    Pattern.create(.identifier, ptk.matchers.identifier),
    Pattern.create(.@"or", ptk.matchers.literal("or")),
    Pattern.create(.@"(", ptk.matchers.literal("(")),
    Pattern.create(.@")", ptk.matchers.literal(")")),
    Pattern.create(.@";", ptk.matchers.literal(";")),
    Pattern.create(.string, struct {
        fn func(input: []const u8) ?usize {
            if (input[0] == '"') {
                if (std.mem.indexOf(u8, input[1..], "\"")) |i| {
                    return i + 2;
                }
            }
            return null;
        }
    }.func),
});

pub const ParserCore = ptk.ParserCore(Tokenizer, .{.whitespace});
pub const Error = ParserCore.Error || Allocator.Error || Message.Error;

allocator: Allocator,
core: ParserCore,

pub fn init(alloc: Allocator, expr: []const u8) Allocator.Error!Self {
    const tokenizer = try alloc.create(Tokenizer);
    errdefer alloc.destroy(tokenizer);
    tokenizer.* = Tokenizer.init(expr, null);

    return .{
        .allocator = alloc,
        .core = ParserCore.init(tokenizer),
    };
}

pub fn deinit(self: *Self) void {
    self.allocator.destroy(self.core.tokenizer);
}

pub fn getContext(self: *Self, messages: *std.ArrayList(Message)) Context {
    return .{
        .core = &self.core,
        .state = self.core.saveState(),
        .expectedToken = null,
        .token = null,
        .messages = messages,
    };
}

pub fn restoreContext(self: *Self, ctx: Context) void {
    self.core.restoreState(ctx.state);
}

test {
    _ = Context;
    _ = Message;
    _ = productions;
}
