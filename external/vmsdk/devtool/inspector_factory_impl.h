#ifndef DEVTOOL_INSPECTOR_FACTORY_IMPL_H
#define DEVTOOL_INSPECTOR_FACTORY_IMPL_H

#include <jsb/runtime/task_runner.h>

#include "jsb/devtool/inspector_factory.h"

namespace vmsdk {
namespace devtool {

class InspectorFactoryImpl : public InspectorFactory {
 public:
  static InspectorFactoryImpl* GetInstance();
#if defined(OS_ANDROID)
  std::unique_ptr<Inspector> Create(
      jobject inspector_client,
      std::shared_ptr<runtime::TaskRunner> taskRunner) override;
#endif
#if defined(OS_IOS)
  std::shared_ptr<Inspector> Create(
      std::shared_ptr<iOS::VMSDKDebugICBase> inspector_client,
      std::shared_ptr<runtime::TaskRunner> taskRunner) override;
#endif
};

}  // namespace devtool
}  // namespace vmsdk
#endif  // DEVTOOL_INSPECTOR_FACTORY_IMPL_H
