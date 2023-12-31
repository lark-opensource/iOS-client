// Copyright 2019 The Lynx Authors. All rights reserved.

#include "tasm/config.h"

#include <utility>

#include "base/log/logging.h"
#include "base/lynx_env.h"
#include "config/config.h"
#include "tasm/compile_options.h"
#include "tasm/fluency/fluency_tracer.h"
namespace lynx {
namespace tasm {

Config::Config() : width_(0), height_(0) { enable_krypton_ = false; }

Config* Config::Instance() {
  static Config* kConfig = new Config;
  return kConfig;
}

void Config::Initialize(int width, int height, float density,
                        std::string os_version) {
  Instance()->width_ = width;
  Instance()->height_ = height;
  Instance()->density_ = density;
  Instance()->default_font_size_ = DEFAULT_FONT_SIZE_DP * density;
  Instance()->default_font_scale_ = DEFAULT_FONT_SCALE;
  InitializeVersion(std::move(os_version));
}

void Config::InitializeVersion(std::string os_version) {
  Instance()->os_version_ = std::move(os_version);
  Instance()->version_ = ENGINE_VERSION;                       // deprecated
  Instance()->min_supported_version_ = MIN_SUPPORTED_VERSION;  // deprecated
  Instance()->need_console_version_ = NEED_CONSOLE_VERSION;
  Instance()->lynx_version_ = LYNX_VERSION;
  Instance()->min_supported_lynx_version_ = MIN_SUPPORTED_LYNX_VERSION;
}

bool Config::GetConfigInternal(const char* key,
                               const CompileOptions& compile_options) {
  if (compile_options.config_type == CONFIG_TYPE_EXPERIMENT_SETTINGS) {
    auto value = base::LynxEnv::GetInstance().GetExperimentSettings(key);
    return value == "true" || value == "1";
  }
  return false;
}

std::string Config::GetConfigStringInternal(
    const char* key, const CompileOptions& compile_options) {
  if (compile_options.config_type == CONFIG_TYPE_EXPERIMENT_SETTINGS) {
    return base::LynxEnv::GetInstance().GetExperimentSettings(key);
  }
  return "";
}

}  // namespace tasm
}  // namespace lynx
