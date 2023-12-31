// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef LYNX_SHELL_RENDERKIT_PUBLIC_LYNX_RESOURCE_PROVIDER_H_
#define LYNX_SHELL_RENDERKIT_PUBLIC_LYNX_RESOURCE_PROVIDER_H_

#include <memory>
#include <string>

#include "lynx_export.h"
#include "shell/renderkit/public/lynx_resource_response.h"

namespace lynx {
static const std::string LYNX_PROVIDER_TYPE_IMAGE = "IMAGE";
static const std::string LYNX_PROVIDER_TYPE_FONT = "FONT";
static const std::string LYNX_PROVIDER_TYPE_LOTTIE = "LOTTIE";
static const std::string LYNX_PROVIDER_TYPE_VIDEO = "VIDEO";
static const std::string LYNX_PROVIDER_TYPE_SVG = "SVG";
static const std::string LYNX_PROVIDER_TYPE_TEMPLATE = "TEMPLATE";
static const std::string LYNX_PROVIDER_TYPE_LYNX_CORE_JS = "LYNX_CORE_JS";
static const std::string LYNX_PROVIDER_TYPE_DYNAMIC_COMPONENT =
    "DYNAMIC_COMPONENT";
static const std::string LYNX_PROVIDER_TYPE_I18N_TEXT = "I18N_TEXT";
static const std::string LYNX_PROVIDER_TYPE_THEME = "THEME";
// for external js source provider
static const std::string LYNX_PROVIDER_TYPE_EXTERNAL_JS = "EXTERNAL_JS_SOURCE";

class LYNX_EXPORT LynxResourceProvider {
 public:
  explicit LynxResourceProvider(const std::string& type)
      : resource_type_(type) {}
  virtual ~LynxResourceProvider() = default;

  std::string GetType() const { return resource_type_; }
  virtual lynx::LynxResourceResponse Request(const std::string& url) = 0;
  virtual void Cancel(const std::string& url) = 0;

 private:
  std::string resource_type_;
};

}  // namespace lynx
#endif  // LYNX_SHELL_RENDERKIT_PUBLIC_LYNX_RESOURCE_PROVIDER_H_
