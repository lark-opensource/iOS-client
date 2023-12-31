#ifndef LYNX_JSBRIDGE_QUICKJS_QUICKJS_API_H_
#define LYNX_JSBRIDGE_QUICKJS_QUICKJS_API_H_

#if defined(OS_ANDROID)
#include <jni.h>
#endif

#include <memory>

#include "base/base_export.h"

namespace lynx {
namespace piper {

BASE_EXPORT_FOR_DEVTOOL std::unique_ptr<piper::Runtime> makeQuickJsRuntime();

}  // namespace piper
}  // namespace lynx
#endif  // LYNX_JSBRIDGE_QUICKJS_QUICKJS_API_H_
