// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef LYNX_SHELL_RENDERKIT_PUBLIC_LYNX_RESOURCE_RESPONSE_H_
#define LYNX_SHELL_RENDERKIT_PUBLIC_LYNX_RESOURCE_RESPONSE_H_

#include <string>

#include "lynx_export.h"

namespace lynx {

class LYNX_EXPORT LynxResourceResponse {
 public:
  LynxResourceResponse() = default;
  ~LynxResourceResponse() = default;

  void InitWithData(const std::string& resource_data);
  bool Success() const;
  std::string GetData() const;

 private:
  std::string data_;
};

}  // namespace lynx
#endif  // LYNX_SHELL_RENDERKIT_PUBLIC_LYNX_RESOURCE_RESPONSE_H_
