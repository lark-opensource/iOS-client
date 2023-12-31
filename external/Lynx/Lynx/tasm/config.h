// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_CONFIG_H_
#define LYNX_TASM_CONFIG_H_

#include <mutex>
#include <string>
#include <vector>

#include "base/base_export.h"
#include "tasm/generator/version.h"
#include "third_party/rapidjson/document.h"

// use to check engine and js match
// ENGINE_VERSION /  MIN_SUPPORTED_VERSION / NEED_CONSOLE_VERSION is deprecated
// Use TARGET_CLI_VERSION / MIN_SUPPORTED_TARGET_CLI_VERSION to do binary check
// They should be updated when release
#define ENGINE_VERSION "0.2.0.0"                         // deprecated
#define MAX_UNSUPPORTED_GECKO_MONITOR_VERSION "0.1.0.0"  // deprecated
#define MIN_SUPPORTED_VERSION "0.1.0.0"                  // deprecated
#define NEED_CONSOLE_VERSION "0.1.0.0"
#define DEFAULT_FONT_SIZE_DP 14
#define DEFAULT_FONT_SCALE 1.f

#define LYNX_VERSION "2.10"               // need updated when release lynx
#define MIN_SUPPORTED_LYNX_VERSION "1.0"  // updated when break change
// control features developed between release
// use this version to avoid break change
#define FEATURE_CONTROL_VERSION "1.1"
#define FEATURE_RADON_VERSION "1.5"

// feature implemented in feature_2_control_version:
// 1. closure
// 2. switch
#define FEATURE_CONTROL_VERSION_2 "1.4"
#define FEATURE_CSS_EXTERNAL_CLASS_VERSION "1.6"
// TODO(liyanbo): Only when all css parser in C++,can open this feature.
#define FEATURE_CSS_VALUE_VERSION "2.0"
#define FEATURE_CSS_STYLE_VARIABLES "2.0"
#define FEATURE_CSS_FONT_FACE_EXTENSION "2.7"
#define FEATURE_HEADER_EXT_INFO_VERSION "1.6"
#define FEATURE_DYNAMIC_COMPONENT_VERSION "1.6"
#define FEATURE_RADON_DYNAMIC_COMPONENT_VERSION "2.1"
#define BUGFIX_DYNAMIC_COMPONENT_DEFAULT_PROPS_VERSION "2.6"
#define FEATURE_DYNAMIC_COMPONENT_CONFIG "2.7"
#define FEATURE_TEMPLATE_INFO "2.7"
#define FEATURE_FLEXIBLE_TEMPLATE "2.8"
#define FEATURE_FIBER_ARCH "2.8"
#define FEATURE_CONTEXT_GLOBAL_DATA "2.8"
#define FEATURE_TRIAL_OPTIONS_VERSION "2.5"
#define FEATURE_COMPONENT_CONFIG "2.6"
#define LYNX_VERSION_1_6 "1.6"
#define FEATURE_TEMPLATE_SCRIPT "2.3"
#define FEATURE_NEW_RENDER_PAGE "2.1"
#define LYNX_VERSION_2_0 "2.0"
#define LYNX_VERSION_2_1 "2.1"
#define LYNX_VERSION_2_2 "2.2"
#define LYNX_VERSION_2_3 "2.3"
#define LYNX_VERSION_2_4 "2.4"
#define LYNX_VERSION_2_5 "2.5"
#define LYNX_VERSION_2_6 "2.6"
#define LYNX_VERSION_2_7 "2.7"
#define LYNX_VERSION_2_8 "2.8"
#define LYNX_VERSION_2_9 "2.9"
#define LYNX_VERSION_2_10 "2.10"

#define LYNX_LEPUS_VERSION "2.3.0"

namespace lynx {
namespace tasm {
struct CompileOptions;
class Config {
 public:
  BASE_EXPORT_FOR_DEVTOOL static void Initialize(int width, int height,
                                                 float density,
                                                 std::string os_version);

  static void InitializeVersion(std::string os_version);

  static void UpdateScreenSize(int width, int height) {
    Instance()->width_ = width;
    Instance()->height_ = height;
  }

  static inline int Width() { return Instance()->width_; }

  static inline int Height() { return Instance()->height_; }

  static inline float Density() { return Instance()->density_; }

  static inline std::string& GetOsVersion() { return Instance()->os_version_; }

  static void UpdatePixelWidthAndHeight(int width, int height) {
    Instance()->pixel_width_ = width;
    Instance()->pixel_height_ = height;
  }

  static void InitPixelValues(int width, int height, float ratio) {
    Instance()->pixel_width_ = width;
    Instance()->pixel_height_ = height;
    Instance()->pixel_ratio_ = ratio;
  }

  static inline int pixelWidth() { return Instance()->pixel_width_; }

  static inline int pixelHeight() { return Instance()->pixel_height_; }

  static inline float pixelRatio() { return Instance()->pixel_ratio_; }

  static inline float DefaultFontSize() {
    return Instance()->default_font_size_;
  }

  static inline bool GetConfig(const char* key,
                               const CompileOptions& compile_options) {
    return Instance()->GetConfigInternal(key, compile_options);
  }

  static inline std::string GetConfigString(
      const char* key, const CompileOptions& compile_options) {
    return Instance()->GetConfigStringInternal(key, compile_options);
  }

  static inline float DefaultFontScale() {
    return Instance()->default_font_scale_;
  }

  static inline bool DefaultFontScaleSpOnly() {
    return Instance()->font_scale_sp_only_;
  }

  static inline std::string& GetNeedConsoleVersion() {
    return Instance()->need_console_version_;
  }
  static inline std::string& GetVersion() { return Instance()->version_; }
  static inline std::string& GetMinSupportedVersion() {
    return Instance()->min_supported_version_;
  }
  static bool IsHigherOrEqual(const std::string& target_v,
                              const std::string& base_v) {
    constexpr const static char* kNull = "null";
    // check for context compile, if target_v == "null", higher than any other
    // versions
    if (target_v == kNull) {
      return true;
    }
    Version base = Version(base_v), target = Version(target_v);
    return base < target || base == target;
  }

  static inline std::string& GetMinSupportLynxVersion() {
    return Instance()->min_supported_lynx_version_;
  }

  static inline std::string& GetCurrentLynxVersion() {
    return Instance()->lynx_version_;
  }

  static bool enableKrypton() { return Instance()->enable_krypton_; }

  static void setEnableKrypton(bool enable_krypton) {
    Instance()->enable_krypton_ = enable_krypton;
  }

  constexpr static const char* Platform() {
#if OS_ANDROID
    return "Android";
#elif OS_IOS
    return "iOS";
#elif MODE_HEADLESS
    return "headless";
#elif OS_WIN
    // TODO(wangqingyu): Change to `"Windows"`
    return "pc";
#elif OS_OSX
    return "macOS";
#else
    return "";
#endif
  };

 private:
  BASE_EXPORT_FOR_DEVTOOL static Config* Instance();
  Config();
  bool GetConfigInternal(const char* key,
                         const CompileOptions& compile_options);
  std::string GetConfigStringInternal(const char* key,
                                      const CompileOptions& compile_options);

 private:
  int width_;
  int height_;
  float density_;
  float default_font_size_;
  float default_font_scale_;
  bool font_scale_sp_only_;
  std::string os_version_;
  std::string version_;                // deprecated
  std::string min_supported_version_;  // deprecated
  std::string need_console_version_;

  // used these to do version check
  std::string lynx_version_;
  std::string min_supported_lynx_version_;
  int pixel_width_, pixel_height_;
  float pixel_ratio_;
  bool enable_krypton_;
};
}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_CONFIG_H_
