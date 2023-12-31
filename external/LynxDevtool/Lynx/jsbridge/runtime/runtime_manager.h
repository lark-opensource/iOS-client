#ifndef LYNX_JSBRIDGE_RUNTIME_RUNTIME_MANAGER_H_
#define LYNX_JSBRIDGE_RUNTIME_RUNTIME_MANAGER_H_

#include <memory>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

#include "base/base_export.h"
#include "jsbridge/jsi/jsi.h"
#include "jsbridge/runtime/js_context_wrapper.h"

namespace lynx {

namespace piper {
class JSExecutor;
}  // namespace piper

namespace runtime {

using CreateJSContextResult =
    std::pair<bool, std::shared_ptr<piper::JSIContext>>;

class BASE_EXPORT_FOR_DEVTOOL RuntimeManager
    : public SharedJSContextWrapper::ReleaseListener {
 public:
  RuntimeManager() {}
  typedef std::unordered_map<std::string,
                             std::shared_ptr<SharedJSContextWrapper>>
      Shared_Context_Map;
  typedef std::vector<std::shared_ptr<NoneSharedJSContextWrapper>>
      None_Shared_Context_List;

  bool IsSingleJSContext(const std::string& group_id);

  BASE_EXPORT_FOR_DEVTOOL virtual std::shared_ptr<piper::Runtime>
  CreateJSRuntime(
      const std::string& group_id,
      std::shared_ptr<piper::JSIExceptionHandler> exception_handler,
      std::vector<std::pair<std::string, std::string>>& js_pre_sources,
      bool forceUseLightweightJSEngine,
      std::shared_ptr<piper::JSExecutor> executor, int64_t rt_id,
      bool ensure_console);

  BASE_EXPORT_FOR_DEVTOOL virtual std::shared_ptr<piper::Runtime>
  InitAppBrandRuntime(
      std::shared_ptr<piper::Runtime> app_brand_js_runtime,
      std::shared_ptr<piper::JSIExceptionHandler> exception_handler,
      std::vector<std::pair<std::string, std::string>>& js_pre_sources,
      std::shared_ptr<piper::JSExecutor> executor, int64_t rt_id,
      bool ensure_console) = 0;

  BASE_EXPORT_FOR_DEVTOOL virtual void OnRelease(
      const std::string& group_id) override;
  void OnVMUnref(piper::JSRuntimeType runtime_type) override;

 protected:
  std::shared_ptr<piper::JSIContext> GetSharedJSContext(
      std::shared_ptr<piper::ConsoleMessagePostMan> post_man,
      const std::string& group_id, bool ensure_console);

  BASE_EXPORT_FOR_DEVTOOL virtual CreateJSContextResult CreateJSContext(
      std::shared_ptr<piper::Runtime>& rt, bool shared_vm);

  BASE_EXPORT_FOR_DEVTOOL virtual std::shared_ptr<piper::Runtime> MakeRuntime(
      bool force_use_lightweight_js_engine) = 0;

  bool EnsureVM(std::shared_ptr<piper::Runtime>& rt);
  void EnsureConsolePostMan(std::shared_ptr<piper::JSIContext>& context,
                            std::shared_ptr<piper::JSExecutor>& executor);

  void InitJSRuntimeCreatedType(bool need_create_vm,
                                std::shared_ptr<piper::Runtime>& rt);

  Shared_Context_Map shared_context_map_;
  std::unordered_map<piper::JSRuntimeType, std::shared_ptr<piper::VMInstance>>
      mVMContainer_;
  std::unordered_map<piper::JSRuntimeType, int> vm_container_ref_count_;
};

}  // namespace runtime
}  // namespace lynx
#endif  // LYNX_JSBRIDGE_RUNTIME_RUNTIME_MANAGER_H_
