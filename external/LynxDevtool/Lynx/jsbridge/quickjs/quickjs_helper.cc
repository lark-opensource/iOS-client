#include "jsbridge/quickjs/quickjs_helper.h"

#include <string>

#include "jsbridge/quickjs/quickjs_exception.h"
// #include "quickjs_runtime.h"
#include <fstream>
#include <iostream>
#include <string>

#include "jsbridge/quickjs/quickjs_runtime.h"

#ifdef __cplusplus
extern "C" {
#endif
#include "quickjs-libc.h"
#include "quickjs.h"
#ifdef __cplusplus
}
#endif

namespace lynx {
namespace piper {
namespace detail {
QuickjsJSValueValue::QuickjsJSValueValue(LEPUSContext *ctx, LEPUSValue val)
    : ctx_(ctx), val_(val) {
  //  static int calc = 0;
  //  time = calc;
  //  LOGE( "create ptr=" << JS_VALUE_GET_PTR(val_) << " create time="
  //  << calc); calc++;
}

void QuickjsJSValueValue::invalidate() {
  //  LOGE( "invalidate ptr=" << LEPUS_VALUE_GET_PTR(val_) << "
  //  invalidate time=" << time);
  LEPUS_FreeValue(ctx_, val_);
  delete this;
}

LEPUSValue QuickjsJSValueValue::Get() const { return val_; }

piper::Runtime::PointerValue *QuickjsHelper::makeStringValue(LEPUSContext *ctx,
                                                             LEPUSValue str) {
  return new QuickjsJSValueValue(ctx, str);
}

piper::Runtime::PointerValue *QuickjsHelper::makeObjectValue(LEPUSContext *ctx,
                                                             LEPUSValue obj) {
  return new QuickjsJSValueValue(ctx, obj);
}

piper::Runtime::PointerValue *QuickjsHelper::makeJSValueValue(LEPUSContext *ctx,
                                                              LEPUSValue obj) {
  return new QuickjsJSValueValue(ctx, obj);
}

piper::Object QuickjsHelper::createJSValue(LEPUSContext *ctx, LEPUSValue obj) {
  return Runtime::make<piper::Object>(makeJSValueValue(ctx, obj));
}

piper::PropNameID QuickjsHelper::createPropNameID(LEPUSContext *ctx,
                                                  LEPUSValue propName) {
  return Runtime::make<piper::PropNameID>(makeStringValue(ctx, propName));
}

piper::String QuickjsHelper::createString(LEPUSContext *ctx, LEPUSValue str) {
  return Runtime::make<piper::String>(makeStringValue(ctx, str));
}

piper::Symbol QuickjsHelper::createSymbol(LEPUSContext *ctx, LEPUSValue sym) {
  return Runtime::make<piper::Symbol>(makeJSValueValue(ctx, sym));
}

piper::Object QuickjsHelper::createObject(LEPUSContext *ctx, LEPUSValue obj) {
  return Runtime::make<piper::Object>(makeObjectValue(ctx, obj));
}

piper::Value QuickjsHelper::createValue(LEPUSValue value, QuickjsRuntime *rt) {
  if (LEPUS_IsInteger(value)) {
    return piper::Value(LEPUS_VALUE_GET_INT(value));
  } else if (LEPUS_IsNumber(value)) {
    return piper::Value(LEPUS_VALUE_GET_FLOAT64(value));
  } else if (LEPUS_IsBool(value)) {
    bool temp = static_cast<bool>(LEPUS_ToBool(rt->getJSContext(), value));
    return piper::Value(temp);
  } else if (LEPUS_IsNull(value)) {
    return piper::Value(nullptr);
  } else if (LEPUS_IsUndefined(value)) {
    return piper::Value();
  } else if (LEPUS_IsSymbol(value)) {
    return piper::Value(createSymbol(rt->getJSContext(), value));
  } else if (LEPUS_IsString(value)) {
    return piper::Value(createString(rt->getJSContext(), value));
  } else if (LEPUS_IsObject(value) || LEPUS_IsException(value)) {
    return piper::Value(createObject(rt->getJSContext(), value));
  } else {
    int64_t tag = LEPUS_VALUE_GET_TAG(value);
    LOGE("createValue failed type is unknown:" << tag);
    std::string msg =
        "createValue failed type is unknown:" + std::to_string(tag);
    rt->reportJSIException(JSINativeException(msg));
    return piper::Value();
  }
}

LEPUSValue QuickjsHelper::symbolRef(const piper::Symbol &sym) {
  const QuickjsJSValueValue *quickjs_sym =
      static_cast<const QuickjsJSValueValue *>(Runtime::getPointerValue(sym));
  return quickjs_sym->Get();
}

LEPUSValue QuickjsHelper::valueRef(const piper::PropNameID &sym) {
  return static_cast<const QuickjsJSValueValue *>(Runtime::getPointerValue(sym))
      ->Get();
}

LEPUSValue QuickjsHelper::stringRef(const piper::String &sym) {
  return static_cast<const QuickjsJSValueValue *>(Runtime::getPointerValue(sym))
      ->Get();
}

LEPUSValue QuickjsHelper::objectRef(const piper::Object &sym) {
  return static_cast<const QuickjsJSValueValue *>(Runtime::getPointerValue(sym))
      ->Get();
}

std::string QuickjsHelper::LEPUSStringToSTLString(LEPUSContext *ctx,
                                                  LEPUSValue s) {
  const char *c = LEPUS_ToCString(ctx, s);
  if (c == nullptr) {
    LEPUS_FreeValue(ctx, LEPUS_GetException(ctx));
    return "Error!";
  }
  std::string ret(c);
  LEPUS_FreeCString(ctx, c);
  return ret;
}

std::optional<piper::Value> QuickjsHelper::call(QuickjsRuntime *rt,
                                                const piper::Function &f,
                                                const piper::Object &jsThis,
                                                LEPUSValue *arguments,
                                                size_t nArgs) {
  LEPUSValue thisObj = QuickjsHelper::objectRef(jsThis);
  LEPUSValue target_object = LEPUS_IsUninitialized(thisObj)
                                 ? LEPUS_GetGlobalObject(rt->getJSContext())
                                 : thisObj;
  LEPUSValue func = objectRef(f);
  LEPUSValue result =
      LEPUS_Call(rt->getJSContext(), func, target_object, nArgs, arguments);

  if (LEPUS_IsUninitialized(thisObj)) {
    LEPUS_FreeValue(rt->getJSContext(), target_object);
  }

  bool has_exception = !QuickjsException::ReportExceptionIfNeeded(*rt, result);
  lepus_std_loop(rt->getJSContext());
  // Before, If function inside quickjs triggered an exception, it return an
  // object as `Exception` type. This type is invisible to jsi, thus cannot be
  // identified. Now, return `undefined` here, the same result as V8.
  if (has_exception) {
    return std::optional<piper::Value>();
  }
  return createValue(result, rt);
}

std::optional<piper::Value> QuickjsHelper::callAsConstructor(QuickjsRuntime *rt,
                                                             LEPUSValue obj,
                                                             LEPUSValue *args,
                                                             int nArgs) {
  LEPUSValue result =
      LEPUS_CallConstructor(rt->getJSContext(), obj, nArgs, args);

  bool has_exception = !QuickjsException::ReportExceptionIfNeeded(*rt, result);
  lepus_std_loop(rt->getJSContext());
  // Same raison as `QuickjsHelper::call`
  if (has_exception) {
    return std::optional<piper::Value>();
  }
  return createValue(result, rt);
}

std::string QuickjsHelper::getErrorMessage(LEPUSContext *ctx,
                                           LEPUSValue &exception_value) {
  std::string error_msg;
  // Even if most of the caller make a check to exception_value before calling
  // getErrorMessage, here we double check if exception_value is an exception or
  // an error to make sure we will not get a message like: [object Object].
  if (LEPUS_IsException(exception_value) ||
      LEPUS_IsError(ctx, exception_value)) {
    auto str = LEPUS_ToCString(ctx, exception_value);
    if (str) {
      error_msg.append(str);
    }
    LEPUS_FreeCString(ctx, str);
  }
  return error_msg;
}

std::optional<piper::Value> QuickjsHelper::evalBuf(QuickjsRuntime *rt,
                                                   LEPUSContext *ctx,
                                                   const char *buf, int buf_len,
                                                   const char *filename,
                                                   int eval_flags) {
  LEPUSValue val = LEPUS_Eval(ctx, buf, buf_len, filename, eval_flags);
  if (!QuickjsException::ReportExceptionIfNeeded(*rt, val)) {
    LOGE("evalBuf failed:" << filename);
    return std::optional<piper::Value>();
  }
  piper::Value evalRes = createValue(val, rt);
  // createValue did not add ref count to val;
  // so don't use LEPUS_FreeValue
  //   LEPUS_FreeValue(ctx, val);
  lepus_std_loop(ctx);
  return evalRes;
}

bool isQualcomm820() {
#if defined(OS_WIN)
  return false;
#else
  static int state = 0;
  const int UNKNOWN = 0;
  const int TRUE = 1;
  const int FALSE = 2;
  if (state != UNKNOWN) {
    return state == TRUE;
  }
  state = FALSE;
  std::ifstream fin("/proc/cpuinfo");
  if (!fin.is_open()) {
    return false;
  }
  std::string str;
  while (getline(fin, str)) {
    // Hardware        : Qualcomm Technologies, Inc MSM8996
    if (str.find("Qualcomm Technologies, Inc MSM8996") != std::string::npos) {
      state = TRUE;
      break;
    }
  }
  fin.close();
  return state == TRUE;
#endif  // OS_WIN
}
std::optional<piper::Value> QuickjsHelper::evalBin(QuickjsRuntime *rt,
                                                   LEPUSContext *ctx,
                                                   const char *buf, int buf_len,
                                                   const char *filename,
                                                   int eval_flags) {
  // https://slardar.bytedance.net/node/app_detail/?aid=13&os=Android&region=cn&lang=zh-Hans#/abnormal/detail/native/291cd7e51dca8da5421047796005901b?params=%7B%22start_time%22%3A1589968140%2C%22end_time%22%3A1591188540%2C%22granularity%22%3A3600%2C%22filters_conditions%22%3A%7B%22type%22%3A%22and%22%2C%22sub_conditions%22%3A%5B%7B%22dimension%22%3A%22update_version_code%22%2C%22op%22%3A%22in%22%2C%22values%22%3A%5B%2277410%22%5D%7D%5D%7D%2C%22order_by%22%3A%22user_descend%22%2C%22pgno%22%3A1%2C%22pgsz%22%3A50%2C%22shortCutKey%22%3A%22%22%2C%22token%22%3A%22lynx%22%2C%22token_type%22%3A0%2C%22anls_dim%22%3A%5B%22device_model%22%2C%22channel%22%2C%22rom%22%2C%22os_version%22%2C%22update_version_code%22%5D%2C%22event_index%22%3A1%2C%22versions_conditions%22%3A%7B%7D%2C%22shortcut_key%22%3A%22custom%22%2C%22crash_type%22%3A%22native%22%2C%22issue_id%22%3A%22291cd7e51dca8da5421047796005901b%22%2C%22sub_issue_id%22%3A%22%22%2C%22event_ids%22%3A%5B%5D%7D
  if (isQualcomm820()) {
    LOGW("Qualcomm 820 CPU, return -1");
    return std::optional<piper::Value>();
  }
  LEPUSValue val = LEPUS_EvalBinary(ctx, reinterpret_cast<const uint8_t *>(buf),
                                    buf_len, eval_flags);
  if (!QuickjsException::ReportExceptionIfNeeded(*rt, val)) {
    LOGE("evalBin failed:" << filename);
    return std::optional<piper::Value>();
  }
  piper::Value evalRes = createValue(val, rt);
  // createValue did not add ref count to val;
  // so don't use LEPUS_FreeValue
  // LEPUS_FreeValue(ctx, val);
  lepus_std_loop(ctx);
  return evalRes;
}

}  // namespace detail
}  // namespace piper
}  // namespace lynx
