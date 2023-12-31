#ifndef LYNX_JSBRIDGE_V8_V8_API_H_
#define LYNX_JSBRIDGE_V8_V8_API_H_

#if OS_ANDROID
#include <jni.h>
#endif

#include <memory>
#include <mutex>

#include "jsbridge/jsi/jsi.h"

namespace lynx {
namespace piper {

std::unique_ptr<piper::Runtime> makeV8Runtime();

}  // namespace piper
}  // namespace lynx
#endif  // LYNX_JSBRIDGE_V8_V8_API_H_
