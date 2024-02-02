const std = @import("std");
const Parser = @import("../Parser.zig");
const Self = @This();

core: *Parser.ParserCore,
state: Parser.ParserCore.State,
expectedToken: ?Parser.TokenType = null,
token: ?Parser.TokenType = null,
messages: *std.ArrayList(Parser.Message),

fn reset(self: *Self) void {
    self.expectedToken = null;
    self.token = null;
}

pub fn pushError(self: *Self, err: Parser.Error) !void {
    try Parser.Message.pushError(self.messages, err, self.*);
}

pub fn peek(self: *Self) Parser.Error!?Parser.Tokenizer.Token {
    return self.core.peek() catch |err| {
        try self.pushError(err);
        return err;
    };
}

pub fn expectTokenPeek(self: *Self, comptime token: Parser.TokenType) Parser.Error!?Parser.Tokenizer.Token {
    defer self.reset();

    self.expectedToken = token;

    if (try self.peek()) |t| {
        self.token = t;

        if (t.type == token) return t;

        try self.pushError(error.UnexpectedToken);
        return error.UnexpectedToken;
    }
    return null;
}

pub fn expectTokenAccept(self: *Self, comptime token: Parser.TokenType) Parser.Error!Parser.Tokenizer.Token {
    defer self.reset();

    self.expectedToken = token;
    self.token = if (try self.peek()) |t| t.type else null;

    return self.core.accept(comptime Parser.ruleset.is(token)) catch |err| {
        try self.pushError(err);
        return err;
    };
}
