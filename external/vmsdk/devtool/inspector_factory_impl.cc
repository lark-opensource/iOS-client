#include "devtool/inspector_factory_impl.h"

#include <basic/no_destructor.h>
#include <jsb/runtime/task_runner.h>

#include "devtool/inspector_impl.h"

namespace vmsdk {
namespace devtool {

#if defined(OS_ANDROID)
std::unique_ptr<Inspector> InspectorFactoryImpl::Create(
    jobject inspector_client, std::shared_ptr<runtime::TaskRunner> taskRunner) {
  auto inspector =
      std::make_unique<InspectorImpl>(inspector_client, std::move(taskRunner));
  return std::unique_ptr<Inspector>(
      static_cast<Inspector *>(inspector.release()));
}
#endif
#if defined(OS_IOS)
std::shared_ptr<Inspector> InspectorFactoryImpl::Create(
    std::shared_ptr<iOS::VMSDKDebugICBase> inspector_client,
    std::shared_ptr<runtime::TaskRunner> taskRunner) {
  auto p_insp =
      std::make_shared<InspectorImpl>(inspector_client, std::move(taskRunner));
  p_insp->initInspectorImpl(inspector_client);
  return p_insp;
}
#endif

InspectorFactoryImpl *InspectorFactoryImpl::GetInstance() {
  static basic::NoDestructor<InspectorFactoryImpl> sInstance{};
  return &*sInstance;
}

}  // namespace devtool
}  // namespace vmsdk
