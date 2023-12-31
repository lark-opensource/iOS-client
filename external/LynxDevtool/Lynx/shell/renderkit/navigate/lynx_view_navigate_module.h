// Copyright 2021 The Lynx Authors. All rights reserved
#ifndef LYNX_SHELL_RENDERKIT_NAVIGATE_LYNX_VIEW_NAVIGATE_MODULE_H_
#define LYNX_SHELL_RENDERKIT_NAVIGATE_LYNX_VIEW_NAVIGATE_MODULE_H_
#include <memory>

#include "shell/renderkit/public/common_native_module.h"

class LynxViewNavigateModule : public lynx::CommonNativeModule {
 public:
  LynxViewNavigateModule();
  virtual ~LynxViewNavigateModule() = default;

  void RegisterJsb();

  std::unique_ptr<lynx::EncodableValue> NavigateTo(void* lynx_view,
                                                   lynx::EncodableList params);
  std::unique_ptr<lynx::EncodableValue> Replace(void* lynx_view,
                                                lynx::EncodableList params);
  std::unique_ptr<lynx::EncodableValue> Refresh(void* lynx_view,
                                                lynx::EncodableList params);
  std::unique_ptr<lynx::EncodableValue> GoBack(void* lynx_view,
                                               lynx::EncodableList params);
  std::unique_ptr<lynx::EncodableValue> GoAhead(void* lynx_view,
                                                lynx::EncodableList params);
};

#endif  // LYNX_SHELL_RENDERKIT_NAVIGATE_LYNX_VIEW_NAVIGATE_MODULE_H_
