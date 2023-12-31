#ifndef DEF
#error "should define DEF before use bytecode_shuffle_mode.inc"
#endif

DEF("NONE", NONE, "none"),
DEF("SIMPLE_MOVE", SIMPLE_MOVE, "move bytecode from one place to another"),
DEF("XOR", XOR, "use xor to encrypt bytecode num"),
DEF("INVALID", INVALID, "invalid")