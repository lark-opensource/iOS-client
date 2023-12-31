// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_JSBRIDGE_IOS_PIPER_RESOURCE_LOADER_DARWIN_H_
#define LYNX_JSBRIDGE_IOS_PIPER_RESOURCE_LOADER_DARWIN_H_

#include <string>

#include "jsbridge/javascript_source_loader.h"

namespace lynx {
namespace piper {

class JSSourceLoaderDarwin : public JSSourceLoader {
 public:
  JSSourceLoaderDarwin() {}

  virtual std::string LoadJSSource(const std::string& name) override;
  virtual std::string LoadLynxJSAsset(const std::string& name, NSURL& bundleUrl,
                                      NSURL& debugBundleUrl);
};

}  // namespace piper
}  // namespace lynx
#endif  // LYNX_JSBRIDGE_IOS_PIPER_RESOURCE_LOADER_DARWIN_H_
