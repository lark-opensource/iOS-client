// Copyright 2021 The Lynx Authors. All rights reserved.

#include "tasm/lynx_env_config.h"

namespace lynx {
namespace tasm {

LynxEnvConfig::LynxEnvConfig(int32_t width, int32_t height) {
  screen_width_ = width;
  screen_height_ = height;
}

void LynxEnvConfig::UpdateScreenSize(int32_t width, int32_t height) {
  screen_width_ = width;
  screen_height_ = height;
}

}  // namespace tasm
}  // namespace lynx
