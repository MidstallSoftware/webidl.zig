pub const Identifier = @import("productions/Identifier.zig");
pub const IntegerType = @import("productions/IntegerType.zig");
pub const String = @import("productions/String.zig");
pub const Symbol = @import("productions/Symbol.zig");
pub const UnsignedIntegerType = @import("productions/UnsignedIntegerType.zig");

test {
    _ = Identifier;
    _ = IntegerType;
    _ = String;
    _ = Symbol;
    _ = UnsignedIntegerType;
}
