// Copyright 2020 The Lynx Authors. All rights reserved.

#ifndef LYNX_JSBRIDGE_APPBRAND_APP_BRAND_JS_TASK_RUNNER_H_
#define LYNX_JSBRIDGE_APPBRAND_APP_BRAND_JS_TASK_RUNNER_H_

#include <memory>
#include <string>

#include "jsbridge/appbrand/js_thread_provider.h"
#include "third_party/fml/task_runner.h"

namespace provider {
namespace piper {
class AppBrandJsTaskRunner : public lynx::fml::TaskRunner {
 public:
  AppBrandJsTaskRunner(const std::string& group_id);

  ~AppBrandJsTaskRunner() override;

  void PostTask(lynx::base::closure task) override;

  bool RunsTasksOnCurrentThread() override;

 private:
  std::string group_id_;
};
}  // namespace piper
}  // namespace provider

#endif  // LYNX_JSBRIDGE_APPBRAND_APP_BRAND_JS_TASK_RUNNER_H_
