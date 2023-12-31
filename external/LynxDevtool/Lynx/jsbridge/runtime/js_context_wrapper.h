#ifndef LYNX_JSBRIDGE_RUNTIME_JS_CONTEXT_WRAPPER_H_
#define LYNX_JSBRIDGE_RUNTIME_JS_CONTEXT_WRAPPER_H_

#include <memory>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

#include "base/base_export.h"
#include "jsbridge/bindings/global.h"
#include "jsbridge/jsi/jsi.h"

namespace lynx {
namespace runtime {

class BASE_EXPORT_FOR_DEVTOOL JSContextWrapper
    : public piper::JSIContext::Observer,
      public std::enable_shared_from_this<JSContextWrapper> {
 public:
  BASE_EXPORT_FOR_DEVTOOL JSContextWrapper(std::shared_ptr<piper::JSIContext>);
  BASE_EXPORT_FOR_DEVTOOL ~JSContextWrapper() = default;

  virtual void Def() = 0;
  virtual void EnsureConsole(
      std::shared_ptr<piper::ConsoleMessagePostMan> post_man) = 0;

  bool isGlobalInited() { return global_inited_; }
  bool isJSCoreLoaded() { return js_core_loaded_; }
  BASE_EXPORT_FOR_DEVTOOL void loadPreJS(
      std::weak_ptr<piper::Runtime> js_runtime,
      std::vector<std::pair<std::string, std::string>>& js_preload);
  std::shared_ptr<piper::JSIContext> getJSContext() {
    return js_context_.lock();
  }
  bool isSharedVM() { return shared_vm_; }

 protected:
  std::weak_ptr<piper::JSIContext> js_context_;
  bool js_core_loaded_;
  bool global_inited_;
  bool shared_vm_ = false;
  piper::JSRuntimeType vm_runtime_type_;
};

class BASE_EXPORT_FOR_DEVTOOL SharedJSContextWrapper : public JSContextWrapper {
 public:
  class ReleaseListener {
   public:
    virtual void OnRelease(const std::string& group_id) = 0;
    virtual void OnVMUnref(piper::JSRuntimeType runtime_type) = 0;
  };
  SharedJSContextWrapper(std::shared_ptr<piper::JSIContext>,
                         const std::string& group_id,
                         ReleaseListener* listener);
  ~SharedJSContextWrapper() = default;

  virtual void Def() override;
  virtual void EnsureConsole(
      std::shared_ptr<piper::ConsoleMessagePostMan> post_man) override;

  BASE_EXPORT_FOR_DEVTOOL void initGlobal(
      std::shared_ptr<piper::Runtime>& rt,
      std::shared_ptr<piper::ConsoleMessagePostMan> post_man);

 protected:
  std::shared_ptr<piper::SharedContextGlobal> global_;
  std::string group_id_;
  ReleaseListener* listener_;
};

class BASE_EXPORT_FOR_DEVTOOL NoneSharedJSContextWrapper
    : public JSContextWrapper {
 public:
  BASE_EXPORT_FOR_DEVTOOL NoneSharedJSContextWrapper(
      std::shared_ptr<piper::JSIContext>);
  BASE_EXPORT_FOR_DEVTOOL NoneSharedJSContextWrapper(
      std::shared_ptr<piper::JSIContext>,
      SharedJSContextWrapper::ReleaseListener* listener);
  BASE_EXPORT_FOR_DEVTOOL ~NoneSharedJSContextWrapper() = default;

  virtual void Def() override;
  virtual void EnsureConsole(
      std::shared_ptr<piper::ConsoleMessagePostMan> post_man) override;

  BASE_EXPORT_FOR_DEVTOOL void initGlobal(
      std::shared_ptr<piper::Runtime>& js_runtime,
      std::shared_ptr<piper::ConsoleMessagePostMan> post_man);

 protected:
  std::shared_ptr<piper::SingleGlobal> global_;
  SharedJSContextWrapper::ReleaseListener* listener_ = nullptr;
};

}  // namespace runtime
}  // namespace lynx
#endif  // LYNX_JSBRIDGE_RUNTIME_JS_CONTEXT_WRAPPER_H_
