// Copyright 2022 The Lynx Authors. All rights reserved.

#include "tasm/base/tasm_utils.h"

#include "lepus/lepus_string.h"
#include "lepus/table.h"
#include "tasm/config.h"

namespace lynx {
namespace tasm {

lepus::Value GenerateSystemInfo(const lepus::Value* config) {
  // add for global setting
  lepus::Value system_info = lepus::Value(lepus::Dictionary::Create());
  system_info.SetProperty("platform", lepus::Value(Config::Platform()));
  system_info.SetProperty("pixelRatio", lepus::Value(Config::pixelRatio()));
  system_info.SetProperty("pixelWidth", lepus::Value(Config::pixelWidth()));
  system_info.SetProperty("pixelHeight", lepus::Value(Config::pixelHeight()));
  lepus::String sdkVersion(Config::GetCurrentLynxVersion());
  system_info.SetProperty("lynxSdkVersion", lepus::Value(sdkVersion.impl()));

  bool has_theme = false;
  if (config != nullptr && config->IsObject()) {
    auto theme = config->GetProperty("theme");
    if (theme.IsObject()) {
      system_info.SetProperty("theme", theme);
      has_theme = true;
    }
  }
  if (!has_theme) {
    // add default
    system_info.SetProperty("theme",
                            lepus::Value(lynx::lepus::Dictionary::Create()));
  }
  system_info.SetProperty("enableKrypton",
                          lepus::Value(Config::enableKrypton()));
  return system_info;
}

}  // namespace tasm
}  // namespace lynx
