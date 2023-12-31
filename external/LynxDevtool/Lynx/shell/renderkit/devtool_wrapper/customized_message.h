// Copyright 2021 The Lynx Authors. All rights reserved.
#ifndef LYNX_SHELL_RENDERKIT_DEVTOOL_WRAPPER_CUSTOMIZED_MESSAGE_H_
#define LYNX_SHELL_RENDERKIT_DEVTOOL_WRAPPER_CUSTOMIZED_MESSAGE_H_

#include <string>

namespace lynx {
namespace devtool {
struct CustomizedMessage {
  std::string type;
  std::string data;
};

}  // namespace devtool
}  // namespace lynx

#endif  // LYNX_SHELL_RENDERKIT_DEVTOOL_WRAPPER_CUSTOMIZED_MESSAGE_H_
