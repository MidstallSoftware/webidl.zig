const std = @import("std");
const Allocator = std.mem.Allocator;
const ptk = @import("parser-toolkit");
const Self = @This();

pub const Message = @import("Parser/Message.zig");
pub const Context = @import("Parser/Context.zig");
pub const constructs = @import("Parser/constructs.zig");
pub const productions = @import("Parser/productions.zig");
pub const matchers = @import("Parser/matchers.zig");

pub const TokenType = enum {
    whitespace,
    linefeed,
    @",",
    float,
    int,
    symbol,
    identifier,
    string,
    @"=",
    @"+",
    @"-",
    @"(",
    @")",
    @"[",
    @"]",
    @"{",
    @"}",
    @";",
    @"?",
    @"...",
};

const Pattern = ptk.Pattern(TokenType);
pub const ruleset = ptk.RuleSet(TokenType);

pub const Tokenizer = ptk.Tokenizer(TokenType, &[_]Pattern{
    Pattern.create(.whitespace, ptk.matchers.whitespace),
    Pattern.create(.linefeed, ptk.matchers.linefeed),
    Pattern.create(.@",", ptk.matchers.literal(",")),
    Pattern.create(.float, matchers.float),
    Pattern.create(.int, matchers.int),
    Pattern.create(.symbol, matchers.symbol),
    Pattern.create(.identifier, matchers.identifier),
    Pattern.create(.string, matchers.string),
    Pattern.create(.@"=", ptk.matchers.literal("=")),
    Pattern.create(.@"+", ptk.matchers.literal("+")),
    Pattern.create(.@"-", ptk.matchers.literal("-")),
    Pattern.create(.@"(", ptk.matchers.literal("(")),
    Pattern.create(.@")", ptk.matchers.literal(")")),
    Pattern.create(.@"[", ptk.matchers.literal("[")),
    Pattern.create(.@"]", ptk.matchers.literal("]")),
    Pattern.create(.@"{", ptk.matchers.literal("{")),
    Pattern.create(.@"}", ptk.matchers.literal("}")),
    Pattern.create(.@";", ptk.matchers.literal(";")),
    Pattern.create(.@"?", ptk.matchers.literal("?")),
    Pattern.create(.@"...", ptk.matchers.literal("...")),
});

pub const ParserCore = ptk.ParserCore(Tokenizer, .{ .whitespace, .linefeed });
pub const Error = ParserCore.Error || Allocator.Error || Message.Error || std.fmt.ParseIntError || std.fmt.ParseFloatError;

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
        .messages = messages,
    };
}

pub fn restoreContext(self: *Self, ctx: Context) void {
    self.core.restoreState(ctx.state);
}

test {
    _ = Context;
    _ = Message;
    _ = constructs;
    _ = productions;
    _ = matchers;
}
