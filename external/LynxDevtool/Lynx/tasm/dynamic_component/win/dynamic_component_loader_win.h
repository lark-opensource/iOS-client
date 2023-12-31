// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_DYNAMIC_COMPONENT_WIN_DYNAMIC_COMPONENT_LOADER_WIN_H_
#define LYNX_TASM_DYNAMIC_COMPONENT_WIN_DYNAMIC_COMPONENT_LOADER_WIN_H_

#include <string>

#include "tasm/dynamic_component/dynamic_component_loader.h"
namespace lynx ::tasm {
class DynamicComponentLoaderWin : public DynamicComponentLoader {
 public:
  ~DynamicComponentLoaderWin() override = default;
  void RequireTemplate(RadonDynamicComponent* dynamic_component,
                       const std::string& url, int trace_id) override;
};
}  // namespace lynx::tasm

#endif  // LYNX_TASM_DYNAMIC_COMPONENT_WIN_DYNAMIC_COMPONENT_LOADER_WIN_H_
