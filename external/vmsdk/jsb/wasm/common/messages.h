// Copyright 2022 The Vmsdk Authors. All rights reserved.

#ifndef JSB_WASM_COMMON_MESSAGES_H_
#define JSB_WASM_COMMON_MESSAGES_H_

namespace vmsdk {

class ExceptionMessages {
 public:
#define MESSAGE_TEMPLATE(T)                                            \
  T(DescriptorNeeded, "A descriptor must be provided.")                \
  T(InternalError, "An internal webassembly error occured.")           \
  T(TypedArrayNeeded, "A TypedArray or ArrayBuffer must be provided.") \
  T(CreatingModuleFailed, "Creating WasmModule failed.")               \
  T(ModuleNeeded, "The 1st argument is not a wasm module.")            \
  T(InstantiationFailed, "WebAssembly Instantiation failed.")          \
  T(GrowWithInvalidArgs, "Grow with invalid arguments!")               \
  T(GrowFailed, "Grow failed.")                                        \
  T(InvalidArgs, "Argument(s) is invalid.")                            \
  T(ModifyImmutable, "Trying to modify an immutable Global.")          \
  T(InvalidMemoryLimits, "For page count max >= initial is required.") \
  T(InvalidTableLimits, "invalid table limits, max is 65536.")         \
  T(OutOfBoundOperation, "The operation exceeds the boundary.")        \
  T(MemoryAllocFailed, "Memory allocation failed.")                    \
  T(InvalidInitialSize, "Invalid initial size in Descriptor.")         \
  T(UnsupportedElemType, "Only 'anyfunc' is supported in Table.")      \
  T(InvalidTableElem, "Setting table with an invalid element.")        \
  T(OSVersionUnsupported,                                              \
    "Such operation is not supported on this version yet.")

#define DEF_MESSAGES(NAME, STRING) \
  static constexpr const char* k##NAME = STRING;

  MESSAGE_TEMPLATE(DEF_MESSAGES)
#undef DEF_MESSAGES

#undef MESSAGE_TEMPLATE
};

}  // namespace vmsdk

#endif  // JSB_WASM_COMMON_MESSAGES_H_
