// Copyright 2020 The Lynx Authors. All rights reserved.

#ifndef LYNX_SHELL_TESTING_MOCK_RUNNER_MANUFACTOR_H_
#define LYNX_SHELL_TESTING_MOCK_RUNNER_MANUFACTOR_H_

#include "base/threading/task_runner_manufactor.h"

namespace lynx {
namespace shell {

class MockRunnerManufactor : public base::TaskRunnerManufactor {
 public:
  explicit MockRunnerManufactor(base::ThreadStrategyForRendering strategy);
  ~MockRunnerManufactor() override = default;

  static bool IsOnUIThread();

  static bool InOnTASMThread();

  static bool InOnLayoutThread();

  static bool InOnJSThread();

  static fml::RefPtr<fml::TaskRunner> GetHookUITaskRunner();

  static fml::RefPtr<fml::TaskRunner> GetHookTASMTaskRunner();

  static fml::RefPtr<fml::TaskRunner> GetHookLayoutTaskRunner();

  static fml::RefPtr<fml::TaskRunner> GetHookJsTaskRunner();

 private:
  void HookUIThread();

  void HookTASMThread();

  void HookLayoutThread();

  void HookJSThread();
};

}  // namespace shell
}  // namespace lynx

#endif  // LYNX_SHELL_TESTING_MOCK_RUNNER_MANUFACTOR_H_
