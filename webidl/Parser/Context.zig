const std = @import("std");
const Parser = @import("../Parser.zig");
const Symbol = @import("productions/Symbol.zig");
const Self = @This();

pub const ValueType = union(enum) {
    token: Parser.TokenType,
    tokens: []const Parser.TokenType,
    symbol: Symbol.Type,
    symbols: []const Symbol.Type,
    text: []const u8,

    pub fn format(self: ValueType, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;

        inline for (comptime std.meta.fields(ValueType), 0..) |field, i| {
            if (i == @intFromEnum(self)) {
                try writer.writeAll(field.name);
                try writer.writeByte(' ');

                const value = @field(self, field.name);
                const Value = @TypeOf(value);

                if (@typeInfo(Value) == .Pointer or @typeInfo(Value) == .Array) {
                    for (value, 0..) |item, x| {
                        const Item = @TypeOf(item);

                        if (Item == u8) {
                            try writer.writeByte(item);
                        } else {
                            try writer.writeAll(@tagName(item));
                            if ((x + 1) < value.len) try writer.writeAll(", ");
                        }
                    }
                } else {
                    try writer.writeAll(@tagName(value));
                }
                break;
            }
        }
    }
};

core: *Parser.ParserCore,
state: Parser.ParserCore.State,
expected: ?ValueType = null,
got: ?ValueType = null,
messages: *std.ArrayList(Parser.Message),

pub fn reset(self: *Self) void {
    self.expected = null;
    self.got = null;
}

pub fn pushError(self: *Self, err: Parser.Error) !void {
    if (err == error.UnexpectedCharacter) {
        self.got = .{ .text = self.core.tokenizer.source[self.core.tokenizer.offset..] };
    }
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

    self.expected = .{ .token = token };

    if (try self.peek()) |t| {
        self.got = .{ .token = t.type };

        if (t.type == token) return t;
        return null;
    }
    return null;
}

pub fn expectTokenAccept(self: *Self, comptime token: Parser.TokenType) Parser.Error!Parser.Tokenizer.Token {
    defer self.reset();

    self.expected = .{ .token = token };
    self.got = if (try self.peek()) |t| ValueType{ .token = t.type } else null;

    return self.core.accept(comptime Parser.ruleset.is(token)) catch |err| {
        try self.pushError(err);
        return err;
    };
}

pub fn expectTokensPeek(self: *Self, comptime tokens: []const Parser.TokenType) Parser.Error!?Parser.Tokenizer.Token {
    defer self.reset();

    self.expected = .{ .tokens = tokens };

    if (try self.peek()) |t| {
        self.got = .{ .token = t.type };

        for (tokens) |token| {
            if (token == t.type) return t;
        }
        return null;
    }
    return null;
}

pub fn expectTokensAccept(self: *Self, comptime tokens: []const Parser.TokenType) Parser.Error!Parser.Tokenizer.Token {
    defer self.reset();

    self.expected = .{ .tokens = tokens };
    self.got = if (try self.peek()) |t| ValueType{ .token = t.type } else null;

    return self.core.accept(struct {
        fn func(t: Parser.TokenType) bool {
            return (std.mem.indexOfScalar(Parser.TokenType, tokens, t) != null);
        }
    }.func) catch |err| {
        try self.pushError(err);
        return err;
    };
}

pub fn expectSymbolPeek(self: *Self, expected: Symbol.Type) Parser.Error!?Parser.Tokenizer.Token {
    defer self.reset();
    if (try self.expectTokenPeek(.symbol)) |sym| {
        self.expected = .{ .symbol = expected };

        if (std.meta.stringToEnum(Symbol.Type, sym.text)) |symValue| {
            if (symValue == expected) return sym;
            return null;
        }
    }
    return null;
}

pub fn expectSymbolAccept(self: *Self, expected: Symbol.Type) Parser.Error!Parser.Tokenizer.Token {
    defer self.reset();

    const sym = try self.expectTokenAccept(.symbol);
    self.expected = .{ .symbol = expected };

    if (std.meta.stringToEnum(Symbol.Type, sym.text)) |symValue| {
        if (symValue == expected) return sym;

        self.got = .{ .symbol = symValue };
    }

    try self.pushError(error.UnexpectedSymbol);
    return error.UnexpectedSymbol;
}

pub fn expectSymbolsPeek(self: *Self, expected: []const Symbol.Type) Parser.Error!?Parser.Tokenizer.Token {
    defer self.reset();
    if (try self.expectTokenPeek(.symbol)) |sym| {
        self.expected = .{ .symbols = expected };

        if (std.meta.stringToEnum(Symbol.Type, sym.text)) |symValue| {
            for (expected) |e| {
                if (symValue == e) return sym;
            }
            return null;
        }
    }
    return null;
}

pub fn expectSymbolsAccept(self: *Self, expected: []const Symbol.Type) Parser.Error!Parser.Tokenizer.Token {
    defer self.reset();

    const sym = try self.expectTokenAccept(.symbol);
    self.expected = .{ .symbols = expected };

    if (std.meta.stringToEnum(Symbol.Type, sym.text)) |symValue| {
        for (expected) |e| {
            if (symValue == e) return sym;
        }

        self.got = .{ .symbol = symValue };
    }

    try self.pushError(error.UnexpectedSymbol);
    return error.UnexpectedSymbol;
}
