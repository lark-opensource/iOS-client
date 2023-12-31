#ifndef LYNX_JSBRIDGE_QUICKJS_QUICKJS_RUNTIME_H_
#define LYNX_JSBRIDGE_QUICKJS_QUICKJS_RUNTIME_H_

#include <memory>
#include <string>

#include "base/base_export.h"
#include "base/log/logging.h"
#include "base/observer/observer.h"
#include "base/observer/observer_list.h"
#include "jsbridge/jsi/jsi.h"
#include "jsbridge/jsi/jslib.h"
#include "jsbridge/quickjs/quickjs_context_wrapper.h"
#include "jsbridge/quickjs/quickjs_helper.h"
#include "jsbridge/quickjs/quickjs_host_function.h"
#include "jsbridge/quickjs/quickjs_host_object.h"
#include "jsbridge/quickjs/quickjs_runtime_wrapper.h"

namespace lynx {
namespace piper {
class QuickjsRuntime : public Runtime {
 public:
  QuickjsRuntime();
  ~QuickjsRuntime() override;
  JSRuntimeType type() override { return JSRuntimeType::quickjs; }

  void InitRuntime(std::shared_ptr<JSIContext> sharedContext,
                   std::shared_ptr<JSIExceptionHandler> handler) override;
  std::shared_ptr<VMInstance> createVM(const StartupData *) const override;
  std::shared_ptr<VMInstance> getSharedVM() override;
  std::shared_ptr<JSIContext> createContext(
      std::shared_ptr<VMInstance>) const override;
  std::shared_ptr<JSIContext> getSharedContext() override;

  std::optional<Value> evaluateJavaScript(
      const std::shared_ptr<const Buffer> &buffer,
      const std::string &sourceURL) override;

  std::shared_ptr<const PreparedJavaScript> prepareJavaScript(
      const std::shared_ptr<const Buffer> &buffer,
      std::string sourceURL) override;

  std::optional<Value> evaluatePreparedJavaScript(
      const std::shared_ptr<const PreparedJavaScript> &js) override;

  Object global() override;

  std::string description() override { return description_; };

  bool isInspectable() override { return false; };

  LEPUSContext *getJSContext() const { return context_->getContext(); };
  LEPUSRuntime *getJSRuntime() const {
    return quickjs_runtime_wrapper_->Runtime();
  };
  LEPUSValue valueRef(const piper::Value &value);
  LEPUSClassID getFunctionClassID() const;
  LEPUSClassID getObjectClassID() const;
  void AddObserver(base::Observer *obs);
  void RemoveObserver(base::Observer *obs);

  BASE_EXPORT_FOR_DEVTOOL void SetDebugViewId(int view_id);

  void RequestGC() override;

 protected:
  PointerValue *cloneSymbol(const Runtime::PointerValue *pv) override;

  PointerValue *cloneString(const Runtime::PointerValue *pv) override;

  PointerValue *cloneObject(const Runtime::PointerValue *pv) override;

  PointerValue *clonePropNameID(const Runtime::PointerValue *pv) override;

  PropNameID createPropNameIDFromAscii(const char *str, size_t length) override;

  PropNameID createPropNameIDFromUtf8(const uint8_t *utf8,
                                      size_t length) override;

  PropNameID createPropNameIDFromString(const piper::String &str) override;

  std::string utf8(const PropNameID &id) override;

  bool compare(const PropNameID &id, const PropNameID &nameID) override;

  std::optional<std::string> symbolToString(const Symbol &symbol) override;

  piper::String createStringFromAscii(const char *str, size_t length) override;

  piper::String createStringFromUtf8(const uint8_t *utf8,
                                     size_t length) override;

  std::string utf8(const piper::String &string) override;

  Object createObject() override;

  Object createObject(std::shared_ptr<HostObject> ho) override;

  std::shared_ptr<HostObject> getHostObject(
      const piper::Object &object) override;

  //  piper::HostFunctionType &getHostFunction(const piper::Function
  //  &function) override;

  piper::HostFunctionType f = [](Runtime &rt, const piper::Value &thisVal,
                                 const piper::Value *args, size_t count) {
    return piper::Value::undefined();
  };
  piper::HostFunctionType &getHostFunction(const piper::Function &) override {
    return f;
  }

  std::optional<Value> getProperty(const Object &object,
                                   const PropNameID &name) override;

  std::optional<Value> getProperty(const Object &object,
                                   const piper::String &name) override;

  bool hasProperty(const Object &object, const PropNameID &name) override;

  bool hasProperty(const Object &object, const piper::String &name) override;

  bool setPropertyValue(Object &object, const PropNameID &name,
                        const piper::Value &value) override;

  bool setPropertyValue(Object &object, const piper::String &name,
                        const piper::Value &value) override;

  bool isArray(const Object &object) const override;

  bool isArrayBuffer(const Object &object) const override;

  bool isFunction(const Object &object) const override;

  bool isHostObject(const piper::Object &object) const override;

  bool isHostFunction(const piper::Function &function) const override;

  std::optional<piper::Array> getPropertyNames(const Object &object) override;

  std::optional<Array> createArray(size_t length) override;

  std::optional<BigInt> createBigInt(const std::string &value,
                                     Runtime &rt) override;

  piper::ArrayBuffer createArrayBufferCopy(const uint8_t *bytes,
                                           size_t byte_length) override;

  piper::ArrayBuffer createArrayBufferNoCopy(
      std::unique_ptr<const uint8_t[]> bytes, size_t byte_length) override;

  std::optional<size_t> size(const Array &array) override;

  size_t size(const ArrayBuffer &buffer) override;

  uint8_t *data(const ArrayBuffer &buffer) override;

  size_t copyData(const ArrayBuffer &, uint8_t *, size_t) override;

  std::optional<Value> getValueAtIndex(const Array &array, size_t i) override;

  bool setValueAtIndexImpl(Array &array, size_t i,
                           const piper::Value &value) override;

  piper::Function createFunctionFromHostFunction(
      const PropNameID &name, unsigned int paramCount,
      piper::HostFunctionType func) override;

  std::optional<Value> call(const piper::Function &function,
                            const piper::Value &jsThis,
                            const piper::Value *args, size_t count) override;

  std::optional<Value> callAsConstructor(const piper::Function &function,
                                         const piper::Value *args,
                                         size_t count) override;

  ScopeState *pushScope() override;

  void popScope(ScopeState *state) override;

  bool strictEquals(const Symbol &a, const Symbol &b) const override;

  bool strictEquals(const piper::String &a,
                    const piper::String &b) const override;

  bool strictEquals(const Object &a, const Object &b) const override;

  bool instanceOf(const Object &o, const piper::Function &f) override;

 private:
  std::shared_ptr<QuickjsRuntimeInstance> CreateVM_(const char *arg,
                                                    bool useSnapshot) const;
  std::shared_ptr<QuickjsContextWrapper> CreateContext_(
      std::shared_ptr<VMInstance> vm) const;
  void Finalize();

 private:
  std::shared_ptr<QuickjsRuntimeInstance> quickjs_runtime_wrapper_;
  std::shared_ptr<QuickjsContextWrapper> context_;
  std::string description_;
  base::ObserverList observers_;
  int debug_view_id_ = -1;
};

}  // namespace piper
}  // namespace lynx

// #ifdef __cplusplus
// }
// #endif

#endif  // LYNX_JSBRIDGE_QUICKJS_QUICKJS_RUNTIME_H_
