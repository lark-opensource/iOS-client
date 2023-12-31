// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_JSBRIDGE_JSC_JSC_API_H_
#define LYNX_JSBRIDGE_JSC_JSC_API_H_

#if OS_ANDROID
#include <jni.h>
#endif  // OS_ANDROID

#include <memory>

#include "jsbridge/jsi/jsi.h"

namespace lynx {
namespace piper {

std::unique_ptr<Runtime> makeJSCRuntime();

}  // namespace piper
}  // namespace lynx
#endif  // LYNX_JSBRIDGE_JSC_JSC_API_H_
