// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_JSBRIDGE_JAVASCRIPT_SOURCE_LOADER_H_
#define LYNX_JSBRIDGE_JAVASCRIPT_SOURCE_LOADER_H_

#include <string>

namespace lynx {

namespace piper {

class JSSourceLoader {
 public:
  virtual ~JSSourceLoader() = default;

  virtual std::string LoadJSSource(const std::string& name) = 0;
};

}  // namespace piper
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_JAVASCRIPT_SOURCE_LOADER_H_
