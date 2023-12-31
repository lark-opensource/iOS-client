// Copyright 2020 The Lynx Authors. All rights reserved.

#ifndef LYNX_JSBRIDGE_RUNTIME_NONE_INSPECTOR_RUNTIME_MANAGER_H_
#define LYNX_JSBRIDGE_RUNTIME_NONE_INSPECTOR_RUNTIME_MANAGER_H_

#include <memory>
#include <string>
#include <utility>
#include <vector>

#include "jsbridge/runtime/runtime_manager.h"

namespace lynx {
namespace runtime {

class NoneInspectorRuntimeManager : public RuntimeManager {
 public:
  friend class RuntimeManager;
  static NoneInspectorRuntimeManager* Instance();

  NoneInspectorRuntimeManager() {}

  std::shared_ptr<piper::Runtime> MakeRuntime(
      bool force_use_lightweight_js_engine) override;

  std::shared_ptr<piper::Runtime> InitAppBrandRuntime(
      std::shared_ptr<piper::Runtime> app_brand_js_runtime,
      std::shared_ptr<piper::JSIExceptionHandler> exception_handler,
      std::vector<std::pair<std::string, std::string> >& js_pre_sources,
      std::shared_ptr<piper::JSExecutor> executor, int64_t rt_id,
      bool ensure_console) override;
};

}  // namespace runtime
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_RUNTIME_NONE_INSPECTOR_RUNTIME_MANAGER_H_
