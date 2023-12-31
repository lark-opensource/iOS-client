// Copyright 2020 The Lynx Authors. All rights reserved.

#include "jsbridge/appbrand/app_brand_js_task_runner.h"

#include <utility>

#include "base/log/logging.h"
#include "third_party/fml/message_loop_impl.h"

namespace provider {
namespace piper {

class InternalTask : public Task {
 public:
  explicit InternalTask(lynx::base::closure closure)
      : closure_(std::move(closure)) {}

  int64_t Id() override { return 0; }

  void Run() override {
    DCHECK(closure_);
    closure_();
  }

 private:
  lynx::base::closure closure_;
};

AppBrandJsTaskRunner::AppBrandJsTaskRunner(const std::string& group_id)
    : lynx::fml::TaskRunner(nullptr), group_id_(group_id) {
  JSThreadProviderGenerator::Provider().OnAttachThread(group_id_.c_str());
}
AppBrandJsTaskRunner::~AppBrandJsTaskRunner() {
  JSThreadProviderGenerator::Provider().OnDetachThread(group_id_.c_str());
}

void AppBrandJsTaskRunner::PostTask(lynx::base::closure task) {
  JSThreadProviderGenerator::Provider().OnPostTask(
      new InternalTask(std::move(task)), group_id_.c_str());
}

bool AppBrandJsTaskRunner::RunsTasksOnCurrentThread() { return false; }

}  // namespace piper
}  // namespace provider
