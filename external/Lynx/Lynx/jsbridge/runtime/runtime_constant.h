// Copyright 2020 The Lynx Authors. All rights reserved.

#ifndef LYNX_JSBRIDGE_RUNTIME_RUNTIME_CONSTANT_H_
#define LYNX_JSBRIDGE_RUNTIME_RUNTIME_CONSTANT_H_

namespace lynx {
namespace runtime {

constexpr const char kAppServiceJSName[] = "/app-service.js";
constexpr const char kLynxCoreJSName[] = "/lynx_core.js";
constexpr const char kLynxCanvasJSName[] = "lynx_assets://lynx_canvas.js";
constexpr const char kLynxAssetsScheme[] = "lynx_assets";
constexpr const char kDynamicComponentJSPrefix[] = "dynamic-component/";

}  // namespace runtime
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_RUNTIME_RUNTIME_CONSTANT_H_
