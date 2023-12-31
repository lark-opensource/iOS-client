
#ifndef LYNX_JSBRIDGE_MODULE_LYNX_MODULE_H_
#define LYNX_JSBRIDGE_MODULE_LYNX_MODULE_H_

#include <memory>
#include <string>
#include <unordered_map>
#include <unordered_set>

#include "jsbridge/jsi/jsi.h"
#include "jsbridge/module/module_delegate.h"

namespace lynx {
namespace piper {
namespace LynxModuleUtils {
// module error message creating
std::string JSTypeToString(const piper::Value* arg);
std::string ExpectedButGotAtIndexError(const std::string& expected,
                                       const std::string& but_got,
                                       int arg_index);
std::string ExpectedButGotError(int expected, int but_got);
}  // namespace LynxModuleUtils

class ModuleMethodInterceptor;

/**
 * Base HostObject class for every module to be exposed to JS
 */
class LynxModule : public piper::HostObject {
 public:
  LynxModule(const std::string& name,
             const std::shared_ptr<ModuleDelegate>& delegate)
      : name_(name), delegate_(delegate) {}
  ~LynxModule() override = default;
  virtual void Destroy() = 0;

  piper::Value get(Runtime* rt, const PropNameID& prop) override;

  const std::string name_;
  // FIXME: use unique_ptr if we solve the `shared_ptr<LynxModule>` issue.
  std::shared_ptr<ModuleMethodInterceptor> interceptor_;

  class MethodMetadata {
   public:
    const size_t argCount;
    const std::string name;
    MethodMetadata(size_t argCount, const std::string& methodName);
  };

  virtual std::optional<piper::Value> invokeMethod(const MethodMetadata& method,
                                                   Runtime* rt,
                                                   const piper::Value* args,
                                                   size_t count) = 0;

  virtual piper::Value getAttributeValue(Runtime* rt, std::string propName) = 0;
  /*
   *SetRecordID, EndRecordFunction and StartRecordFunction only used by
   *TestBench
   */
  virtual void SetRecordID(int64_t record_id) {}
  virtual void EndRecordFunction(const std::string& method_name, size_t count,
                                 const piper::Value* js_args, Runtime* rt,
                                 piper::Value& res) {}
  virtual void StartRecordFunction(const std::string& method_name = "") {}

 protected:
  std::unordered_map<std::string, std::shared_ptr<MethodMetadata>> methodMap_;
  const std::shared_ptr<ModuleDelegate> delegate_;

 private:
  static const std::unordered_set<std::string>& MethodAllowList();
};

/**
 * An app/platform-specific provider function to get an instance of a module
 * given a name.
 */
using LynxModuleProviderFunction =
    std::function<std::shared_ptr<LynxModule>(const std::string& name)>;

/**
 * Result for ModuleMethodInterceptor.
 * `handled` meaning whether the Module Method is handled and stop
 * propagation.
 * `result` is the Module Method result, only valid when `handled`
 * is true.
 */
struct ModuleInterceptorResult {
  bool handled;
  Value result;
};

/**
 * Intercept mould method call.
 * This object should only alive in JS Thread.
 */
class ModuleMethodInterceptor {
 public:
  virtual ModuleInterceptorResult InterceptModuleMethod(
      LynxModule* module, LynxModule::MethodMetadata* method, Runtime* rt,
      const std::shared_ptr<piper::ModuleDelegate>& delegate,
      const piper::Value* args, size_t count) const = 0;
  virtual ~ModuleMethodInterceptor() = default;
  virtual void SetTemplateUrl(const std::string& url) = 0;
};

}  // namespace piper
}  // namespace lynx
#endif  // LYNX_JSBRIDGE_MODULE_LYNX_MODULE_H_
