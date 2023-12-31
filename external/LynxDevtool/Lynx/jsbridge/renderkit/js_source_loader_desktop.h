// Copyright 2021 The Lynx Authors. All rights reserved

#ifndef LYNX_JSBRIDGE_RENDERKIT_JS_SOURCE_LOADER_DESKTOP_H_
#define LYNX_JSBRIDGE_RENDERKIT_JS_SOURCE_LOADER_DESKTOP_H_

#include <string>

#include "jsbridge/javascript_source_loader.h"

namespace lynx {
namespace piper {

class JSSourceLoaderDesktop : public JSSourceLoader {
 private:
  static std::string LoadFileData(const std::string& path);

 public:
  std::string LoadJSSource(const std::string& name) override;
};

}  // namespace piper
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_RENDERKIT_JS_SOURCE_LOADER_DESKTOP_H_
