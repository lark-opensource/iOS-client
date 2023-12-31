#ifndef VMSDK_QUICKJS_TOOLS_VALUE_H
#define VMSDK_QUICKJS_TOOLS_VALUE_H

#include <iostream>

#include "quickjs/tools/bytecode_context.h"

extern "C" {
#include "quickjs.h"
}

namespace quickjs {
namespace bytecode {

class Value;
class BytecodeContext;

enum class ValueType : uint32_t {
  // native
  VT_BOOL,
  VT_INTEGER,
  VT_DOUBLE,
  VT_STR,
  VT_ARRAY,

  VT_INVALID
};

template <typename T, typename RT = T>
struct value_info {};

template <>
struct value_info<bool> {
  static const ValueType type = ValueType::VT_BOOL;

  inline static std::pair<bool, bool> from_js_value(
      std::shared_ptr<BytecodeContext> bctx, LEPUSValue value) {
    int ret = LEPUS_ToBool(bctx->getContext(), value);
#ifndef ENABLE_EM_FEATURE
    assert((ret != -1) && "should been converted to bool");
#endif
    return std::make_pair(!!ret, false);
  }

  inline static std::pair<LEPUSValue, bool> to_js_value(
      std::shared_ptr<BytecodeContext> bctx, bool value) {
    LEPUSValue ret = LEPUS_NewBool(bctx->getContext(), value);
    return std::make_pair(ret, LEPUS_IsException(ret));
  }
};

template <>
struct value_info<int32_t> {
  static const ValueType type = ValueType::VT_INTEGER;

  inline static std::pair<int32_t, bool> from_js_value(
      std::shared_ptr<BytecodeContext> bctx, LEPUSValue value) {
    int32_t ret = 0;
    int has_error = LEPUS_ToInt32(bctx->getContext(), &ret, value);
    (void)has_error;
#ifndef ENABLE_EM_FEATURE
    assert(!has_error && "should been converted to bool");
#endif
    return std::make_pair(ret, has_error);
  }

  inline static std::pair<LEPUSValue, bool> to_js_value(
      std::shared_ptr<BytecodeContext> bctx, int32_t value) {
    LEPUSValue ret = LEPUS_NewInt32(bctx->getContext(), value);
    return std::make_pair(ret, LEPUS_IsException(ret));
  }
};

template <>
struct value_info<double> {
  static const ValueType type = ValueType::VT_DOUBLE;
  inline static std::pair<double, bool> from_js_value(
      std::shared_ptr<BytecodeContext> bctx, LEPUSValue value) {
    double ret = 0.0;
    int has_error = LEPUS_ToFloat64(bctx->getContext(), &ret, value);
    (void)has_error;
#ifndef ENABLE_EM_FEATURE
    assert(!has_error && "should been converted to bool");
#endif
    return std::make_pair(ret, has_error);
  }

  inline static std::pair<LEPUSValue, bool> to_js_value(
      std::shared_ptr<BytecodeContext> bctx, double value) {
    LEPUSValue ret = LEPUS_NewFloat64(bctx->getContext(), value);
    return std::make_pair(ret, LEPUS_IsException(ret));
  }
};

template <>
struct value_info<std::string> {
  static const ValueType type = ValueType::VT_STR;
  inline static std::pair<std::string, bool> from_js_value(
      std::shared_ptr<BytecodeContext> bctx, LEPUSValue value) {
#ifndef ENABLE_EM_FEATURE
    assert(LEPUS_IsString(value) && "should be a string");
#endif
    const char *str = LEPUS_ToCString(bctx->getContext(), value);
#ifndef ENABLE_EM_FEATURE
    assert(str && "should been converted to bool");
#endif
    return std::make_pair(std::string(str), !str);  // result, has_error
  }

  inline static std::pair<LEPUSValue, bool> to_js_value(
      std::shared_ptr<BytecodeContext> bctx, const std::string &value) {
    LEPUSValue ret =
        LEPUS_NewStringLen(bctx->getContext(), value.c_str(), value.size());
    return std::make_pair(ret, LEPUS_IsException(ret));
  }
};

template <>
struct value_info<LEPUSValue> {
  static const ValueType type = ValueType::VT_INVALID;

  inline static std::pair<LEPUSValue, bool> from_js_value(
      std::shared_ptr<BytecodeContext> bctx, LEPUSValue value) {
    __builtin_unreachable();
  }

  inline static std::pair<LEPUSValue, bool> to_js_value(
      std::shared_ptr<BytecodeContext> bctx, const LEPUSValue value) {
    __builtin_unreachable();
  }
};

template <>
struct value_info<std::vector<Value>> {
  static const ValueType type = ValueType::VT_ARRAY;

  inline static std::pair<std::vector<Value>, bool> from_js_value(
      std::shared_ptr<BytecodeContext> bctx, LEPUSValue value);

  inline static std::pair<LEPUSValue, bool> to_js_value(
      std::shared_ptr<BytecodeContext> bctx, const std::vector<Value> &value);
};

template <typename T>
struct is_js_value {
  static const bool value = false;
};
template <>
struct is_js_value<LEPUSValue> {
  static const bool value = true;
};

class Value {
 public:
  Value()
      : ctx(nullptr),
        type(ValueType::VT_INVALID),
        value(LEPUS_UNDEFINED),
        hasError(false) {}
  Value(std::shared_ptr<BytecodeContext> &ctx, LEPUSValue value)
      : ctx(ctx), type(value_info<LEPUSValue>::type), hasError(false) {
    this->value = LEPUS_DupValue(getContext(), value);

    if (LEPUS_IsBool(value))
      type = ValueType::VT_BOOL;
    else if (LEPUS_IsInteger(value))
      type = ValueType::VT_INTEGER;
    else if (LEPUS_IsNumber(value))
      type = ValueType::VT_DOUBLE;
    else if (LEPUS_IsString(value))
      type = ValueType::VT_STR;
    else if (LEPUS_IsArray(getContext(), value))
      type = ValueType::VT_ARRAY;

#ifndef ENABLE_EM_FEATURE
    assert(isValid() && "should be valid");
#endif
  }

#undef SCALAR_CONSTRUCTOR
#define SCALAR_CONSTRUCTOR(T)                           \
  Value(std::shared_ptr<BytecodeContext> &ctx, T value) \
      : ctx(ctx),                                       \
        type(value_info<T>::type),                      \
        value(LEPUS_UNDEFINED),                         \
        hasError(false) {                               \
    Status status = toJSValue<T>(value);                \
    hasError = !status.ok();                            \
  }

  SCALAR_CONSTRUCTOR(bool);
  SCALAR_CONSTRUCTOR(int32_t);
  SCALAR_CONSTRUCTOR(double);
  SCALAR_CONSTRUCTOR(std::string);
  SCALAR_CONSTRUCTOR(std::vector<Value>);

  Value(std::shared_ptr<BytecodeContext> &ctx, const char *value)
      : ctx(ctx),
        type(value_info<std::string>::type),
        value(LEPUS_UNDEFINED),
        hasError(false) {
    std::string str(value);
    Status status = toJSValue<std::string>(str);
    hasError = !status.ok();
  }

#undef SCALAR_CONSTRUCTOR

  Value(const Value &other) { this->operator=(other); }
  Value &operator=(const Value &other) {
    ctx = other.ctx;
    type = other.type;
    value = LEPUS_DupValue(getContext(), other.value);
    return *this;
  }

  ~Value() { LEPUS_FreeValue(getContext(), value); }

  template <typename T>
  Status fromJSValue(T &retVal) {
    if (isUndef() || isNull())
      return Status(ERR_CONVERET_UNDEF_OR_NULL_TO_NATIVE,
                    "null or undef can not convert to native type");

    auto result = value_info<T>::from_js_value(ctx, value);
    Status status = Status::OK();
    if (result.second)  // has error
      status =
          Status(ERR_FAIL_CONVERT_TO_NATIVE, "fail to convert native type");
    else
      retVal = result.first;

    return status;
  }

#ifdef ENABLE_QUICKJS_UNITTEST
  LEPUSValue getJSValueRef() const { return value; }
#endif

  LEPUSContext *getContext() const {
    if (!ctx) return nullptr;
    return ctx->getContext();
  }
  LEPUSValue getJSValue() const { return LEPUS_DupValue(getContext(), value); }
  ValueType getType() const { return type; }
  bool hasException() const { return LEPUS_IsException(value); }
  bool isUndef() const { return LEPUS_IsUndefined(value); }
  bool isNull() const { return LEPUS_IsNull(value); }
  bool isValid() const {
    return ctx != nullptr && type != ValueType::VT_INVALID && !hasError;
  }

 private:
  template <typename T>
  Status toJSValue(T &input) {
    auto result = value_info<T>::to_js_value(ctx, input);
    Status status = Status::OK();
    if (result.second) {  // has error
      // If the error happed, when Value try to convert native value to jsvalue.
      // The variable of "result" might contain some valid data, array for
      // example.
      // So we need to free value when error happed
      status = Status(ERR_FAIL_CONVERT_TO_JSVALUE, "failed to convert");
      LEPUS_FreeValue(getContext(), result.first);
    } else {
      LEPUS_FreeValue(getContext(), value);
      value = result.first;
    }
    return status;
  }

 private:
  std::shared_ptr<BytecodeContext> ctx;
  ValueType type;
  LEPUSValue value;
  bool hasError{false};
};  // namespace bytecode

std::pair<std::vector<Value>, bool>
value_info<std::vector<Value>>::from_js_value(
    std::shared_ptr<BytecodeContext> bctx, LEPUSValue value) {
  std::vector<Value> ret;
  LEPUSContext *ctx = bctx->getContext();
#ifndef ENABLE_EM_FEATURE
  assert(ctx && "should not be null");
#endif
  int len = LEPUS_GetLength(ctx, value);
  if (len > 0) {
    ret.reserve(len);
    for (int idx = 0; idx < len; idx++) {
      LEPUSValue element = LEPUS_GetPropertyUint32(ctx, value, idx);
      if (LEPUS_IsException(element)) return std::make_pair(ret, true);
      ret.emplace_back(bctx, element);
      LEPUS_FreeValue(ctx, element);
    }
    return std::make_pair(ret, false);  // result, has_error
  }
  return std::make_pair(ret, true);
}

std::pair<LEPUSValue, bool> value_info<std::vector<Value>>::to_js_value(
    std::shared_ptr<BytecodeContext> bctx, const std::vector<Value> &value) {
  std::vector<LEPUSValue> vals;
  LEPUSContext *ctx = bctx->getContext();
#ifndef ENABLE_EM_FEATURE
  assert(ctx && "should not be null");
#endif
  uint32_t len = value.size();
  vals.reserve(len);
  for (uint32_t idx = 0; idx < len; idx++)
    vals.emplace_back(value[idx].getJSValue());
  LEPUSValue ret = LEPUS_NewArrayWithValue(ctx, len, vals.data());
  return std::make_pair(ret, LEPUS_IsException(ret));
}

}  // namespace bytecode
}  // namespace quickjs

#endif
