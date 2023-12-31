// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_SHELL_EXTERNAL_SOURCE_LOADER_H_
#define LYNX_SHELL_EXTERNAL_SOURCE_LOADER_H_

#include <string>

#include "jsbridge/runtime/template_delegate.h"

namespace lynx {
namespace shell {

class ExternalSourceLoader {
 public:
  ExternalSourceLoader() = default;
  virtual ~ExternalSourceLoader() = default;

  ExternalSourceLoader(ExternalSourceLoader&&) = default;
  ExternalSourceLoader& operator=(ExternalSourceLoader&&) = default;

  virtual std::string LoadScript(const std::string& url) = 0;

  virtual void LoadScriptAsync(const std::string& url, int32_t callback_id) = 0;

  virtual void LoadDynamicComponent(const std::string& url,
                                    int32_t callback_id) = 0;
};

}  // namespace shell
}  // namespace lynx

#endif  // LYNX_SHELL_EXTERNAL_SOURCE_LOADER_H_
