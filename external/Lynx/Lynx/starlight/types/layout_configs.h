// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_STARLIGHT_TYPES_LAYOUT_CONFIGS_H_
#define LYNX_STARLIGHT_TYPES_LAYOUT_CONFIGS_H_

#include <string>

#include "tasm/generator/version.h"

constexpr char kQuirksModeEnableVersion[] = "1.5";
constexpr char kQuirksModeDisableVersion[] = "1.6";
constexpr char kFlexAlignFixedVersion[] = "2.9";
constexpr char kFlexWrapFixedVersion[] = "2.10";
namespace lynx {
namespace starlight {

struct LayoutConfigs {
  void SetQuirksMode(const std::string& version) {
    quirks_mode_ = tasm::Version(version);
    is_full_quirks_mode_ =
        !IsVersionHigherOrEqual(tasm::Version(kQuirksModeDisableVersion));
    is_flex_align_quirks_mode_ =
        !IsVersionHigherOrEqual(tasm::Version(kFlexAlignFixedVersion));
    is_flex_wrap_quirks_mode_ =
        !IsVersionHigherOrEqual(tasm::Version(kFlexWrapFixedVersion));
  }
  const tasm::Version GetQuirksMode() const { return quirks_mode_; }

  bool IsFullQuirksMode() const { return is_full_quirks_mode_; }
  bool IsVersionHigherOrEqual(const tasm::Version& version) const {
    return quirks_mode_ >= version;
  }
  // Flex-align quirks mode. When the size of a flex node depends on dynamic
  // size, it is always aligned to the top. Fix this issue when
  // is_flex_align_quirks_mode_ is false.
  bool IsFlexAlignQuirksMode() const { return is_flex_align_quirks_mode_; }
  // Flex-wrap quirks mode. When using flex-wrap with max-height/width at main
  // side, it is not shrinking to content size. Fix this issue when
  // is_flex_wrap_quirks_mode_ is false.
  bool IsFlexWrapQuirksMode() const { return is_flex_wrap_quirks_mode_; }

  bool is_absolute_in_content_bound_ = false;
  bool css_align_with_legacy_w3c_ = false;
  std::string target_sdk_version = "1.0";
  bool font_scale_sp_only_ = false;
  bool default_display_linear_ = false;

 private:
  tasm::Version quirks_mode_ = tasm::Version(kQuirksModeEnableVersion);
  // compatible with SSR
  bool is_full_quirks_mode_ = true;
  bool is_flex_align_quirks_mode_ = true;
  bool is_flex_wrap_quirks_mode_ = true;
};

}  // namespace starlight
}  // namespace lynx

#endif  // LYNX_STARLIGHT_TYPES_LAYOUT_CONFIGS_H_
