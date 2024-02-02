pub const FloatType = @import("productions/FloatType.zig");
pub const Identifier = @import("productions/Identifier.zig");
pub const IntegerType = @import("productions/IntegerType.zig");
pub const PrimitiveType = @import("productions/PrimitiveType.zig");
pub const String = @import("productions/String.zig");
pub const Symbol = @import("productions/Symbol.zig");
pub const UnsignedIntegerType = @import("productions/UnsignedIntegerType.zig");
pub const UnrestrictedFloatType = @import("productions/UnrestrictedFloatType.zig");

test {
    _ = FloatType;
    _ = Identifier;
    _ = IntegerType;
    _ = PrimitiveType;
    _ = String;
    _ = Symbol;
    _ = UnsignedIntegerType;
    _ = UnrestrictedFloatType;
}
