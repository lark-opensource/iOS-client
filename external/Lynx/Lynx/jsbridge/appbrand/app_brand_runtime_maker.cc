
#include "jsbridge/appbrand/app_brand_runtime_maker.h"

#include "jsbridge/appbrand/runtime_provider.h"
#ifdef OS_IOS
#include "jsbridge/appbrand/jsc/jsc_app_brand_runtime.h"

#endif  // OS_IOS

namespace provider {
namespace piper {

/**
 *  android: return provider/v8/app_brand_runtime
 *  iOS :
 *   - release: return provider/jsc/app_brand_runtime
 *   - debug: return v8Runtime
 */
std::shared_ptr<lynx::piper::Runtime> AppBrandRuntimeMaker::MakeJSRuntime(
    const std::string& group_id) {
  auto ptr = static_cast<lynx::piper::Runtime*>(
      RuntimeProviderGenerator::Provider().MakeRuntime(group_id.c_str()));
  if (ptr == nullptr) {
    LOGE("fatal error : runtime ptr can't be null !!!");
  }
  return std::shared_ptr<lynx::piper::Runtime>(ptr);
}
}  // namespace piper
}  // namespace provider
