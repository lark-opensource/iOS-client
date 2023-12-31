//  Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_COMPONENT_CONFIG_H_
#define LYNX_TASM_COMPONENT_CONFIG_H_

namespace lynx {
namespace tasm {

enum class BooleanProp {
  NotSet,
  TrueValue,
  FalseValue,
};

class ComponentConfig {
 public:
  ComponentConfig() = default;
  inline void SetDisableIsolateContext(bool disable_isolate_context) {
    disable_isolate_context_ = disable_isolate_context;
  }

  inline bool IsDisableIsolateContext() { return disable_isolate_context_; }

  inline void SetEnableRemoveExtraData(bool enable) {
    enable_remove_extra_data_ =
        enable ? BooleanProp::TrueValue : BooleanProp::FalseValue;
  }

  inline BooleanProp GetEnableRemoveExtraData() const {
    return enable_remove_extra_data_;
  }

 private:
  ComponentConfig(ComponentConfig& config) = delete;
  ComponentConfig& operator=(ComponentConfig& config) = delete;

  bool disable_isolate_context_{true};
  BooleanProp enable_remove_extra_data_{BooleanProp::NotSet};
};
}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_COMPONENT_CONFIG_H_
