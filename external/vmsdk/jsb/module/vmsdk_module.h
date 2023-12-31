#pragma once

#include <memory>
#include <string>
#include <unordered_map>
#include <unordered_set>

#include "jsb/module/module_delegate.h"
#include "napi.h"

namespace vmsdk {
namespace piper {

namespace VmsdkModuleUtils {
// module error message creating
std::string JSTypeToString(const Napi::Value arg);
std::string ExpectedButGotAtIndexError(const std::string &expected,
                                       const std::string &but_got,
                                       int arg_index);
std::string ExpectedButGotError(int expected, int but_got);
}  // namespace VmsdkModuleUtils

class VmsdkModuleWrap;

// c++ VmsdkMoudle
class VmsdkModule {
 public:
  VmsdkModule(const std::string &name,
              const std::shared_ptr<ModuleDelegate> &delegate)
      : name_(name), delegate_(delegate) {}
  ~VmsdkModule() = default;
  virtual void Destroy() = 0;

  // Napi::Value get(Napi::Env env, const PropNameID& prop) override;

  const std::string name_;

 protected:
  class MethodMetadata {
   public:
    const size_t argCount;
    const std::string name;
    VmsdkModule *module;
    MethodMetadata(size_t argCount, const std::string &methodName,
                   VmsdkModule *module);
  };

  virtual Napi::Value invokeMethod(const Napi::CallbackInfo &info) = 0;

  void OnJSBridgeInvoked(const std::string &method_name,
                         const std::string &param_str);

  std::unordered_map<std::string, std::shared_ptr<MethodMetadata>> methodMap_;
  const std::shared_ptr<ModuleDelegate> delegate_;

 private:
  static const std::unordered_set<std::string> &MethodAllowList();
  Napi::Reference<Napi::Function> constructor_;
  friend class VmsdkModuleWrap;
};

// Wrapper to create Napi::Value from c++ VmsdkMoudle object
class VmsdkModuleWrap : public Napi::ScriptWrappable {
 public:
  explicit VmsdkModuleWrap(const Napi::CallbackInfo &info);
  static Napi::Value CreateFromVmsdkModule(Napi::Env env, VmsdkModule *module);
  Napi::Value Getter(const Napi::CallbackInfo &info);

 private:
  VmsdkModule *module_;
};

/**
 * An app/platform-specific provider function to get an instance of a module
 * given a name.
 */
using VmsdkModuleProviderFunction =
    std::function<std::shared_ptr<VmsdkModule>(const std::string &name)>;

}  // namespace piper
}  // namespace vmsdk
