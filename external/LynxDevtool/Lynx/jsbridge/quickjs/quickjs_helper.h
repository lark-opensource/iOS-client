#ifndef LYNX_JSBRIDGE_QUICKJS_QUICKJS_HELPER_H_
#define LYNX_JSBRIDGE_QUICKJS_QUICKJS_HELPER_H_
#include <string>

#include "base/log/logging.h"
#include "jsbridge/jsi/jsi.h"

#ifdef __cplusplus
extern "C" {
#endif
#include "quickjs.h"
#ifdef __cplusplus
}
#endif

namespace lynx {
namespace piper {
class QuickjsRuntime;
namespace detail {

class QuickjsJSValueValue : public Runtime::PointerValue {
 public:
  QuickjsJSValueValue(LEPUSContext* ctx, LEPUSValue val);
  ~QuickjsJSValueValue() = default;

  void invalidate() override;
  virtual std::string Name() override { return "QuickjsJSValueValue"; }
  LEPUSValue Get() const;

  LEPUSContext* ctx_;
  LEPUSValue val_;

 protected:
  friend class piper::QuickjsRuntime;
  friend class QuickjsHelper;
  // for debug
  //  int time;
};

class QuickjsHelper {
 public:
  static piper::Runtime::PointerValue* makeStringValue(LEPUSContext* ctx,
                                                       LEPUSValue str);
  static piper::Runtime::PointerValue* makeObjectValue(LEPUSContext* ctx,
                                                       LEPUSValue obj);
  static piper::Runtime::PointerValue* makeJSValueValue(LEPUSContext* ctx,
                                                        LEPUSValue obj);
  static piper::Value createValue(LEPUSValue value, QuickjsRuntime* rt);
  static piper::String createString(LEPUSContext* ctx, LEPUSValue str);
  static piper::Symbol createSymbol(LEPUSContext* ctx, LEPUSValue sym);
  static piper::Object createObject(LEPUSContext* ctx, LEPUSValue obj);
  static piper::Object createJSValue(LEPUSContext* ctx, LEPUSValue obj);
  static piper::PropNameID createPropNameID(LEPUSContext* ctx,
                                            LEPUSValue propName);
  static LEPUSValue symbolRef(const piper::Symbol& sym);
  static LEPUSValue valueRef(const piper::PropNameID& sym);
  static LEPUSValue stringRef(const piper::String& sym);
  static LEPUSValue objectRef(const piper::Object& sym);

  static std::string LEPUSStringToSTLString(LEPUSContext* ctx, LEPUSValue s);

  static std::optional<piper::Value> call(QuickjsRuntime* rt,
                                          const piper::Function& f,
                                          const piper::Object& jsThis,
                                          LEPUSValue* args, size_t nArgs);
  static std::optional<piper::Value> callAsConstructor(QuickjsRuntime* rt,
                                                       LEPUSValue obj,
                                                       LEPUSValue* args,
                                                       int nArgs);
  static std::string getErrorMessage(LEPUSContext* ctx,
                                     LEPUSValue& exception_val);

  static std::optional<piper::Value> evalBuf(QuickjsRuntime* rt,
                                             LEPUSContext* ctx, const char* buf,
                                             int buf_len, const char* filename,
                                             int eval_flags);
  static std::optional<piper::Value> evalBin(QuickjsRuntime* rt,
                                             LEPUSContext* ctx, const char* buf,
                                             int buf_len, const char* filename,
                                             int eval_flags);
};

}  // namespace detail
}  // namespace piper
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_QUICKJS_QUICKJS_HELPER_H_
