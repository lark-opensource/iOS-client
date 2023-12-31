
#ifndef LYNX_JSBRIDGE_APPBRAND_APP_BRAND_RUNTIME_MAKER_H_
#define LYNX_JSBRIDGE_APPBRAND_APP_BRAND_RUNTIME_MAKER_H_

#include <memory>
#include <string>

#include "jsbridge/jsi/jsi.h"

namespace provider {
namespace piper {
class AppBrandRuntimeMaker {
 public:
  static std::shared_ptr<lynx::piper::Runtime> MakeJSRuntime(
      const std::string& group_id);

 private:
  AppBrandRuntimeMaker(const AppBrandRuntimeMaker&) = delete;
  AppBrandRuntimeMaker& operator=(const AppBrandRuntimeMaker&) = delete;
};
}  // namespace piper
}  // namespace provider

#endif  // LYNX_JSBRIDGE_APPBRAND_APP_BRAND_RUNTIME_MAKER_H_
