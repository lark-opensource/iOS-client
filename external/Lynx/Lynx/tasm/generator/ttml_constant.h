// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_GENERATOR_TTML_CONSTANT_H_
#define LYNX_TASM_GENERATOR_TTML_CONSTANT_H_

namespace lynx {
namespace tasm {
// tasm
#define TEMPLATE_BUNDLE_NAME "path"
#define TEMPLATE_BUNDLE_PAGES "pages"
#define TEMPLATE_BUNDLE_DYNAMIC_COMPONENTS "dynamic_components"
#define TEMPLATE_BUNDLE_TTSS ".ttss"
#define TEMPLATE_BUNDLE_DATA "data"
#define TEMPLATE_BUNDLE_APP_TYPE "appType"
#define TEMPLATE_BUNDLE_APP_DSL "dsl"
#define TEMPLATE_SUPPORTED_VERSIONS "__version"
#define TEMPLATE_CLI_VERSION "cli"
#define TEMPLATE_AUTO_EXPOSE "autoExpose"
#define TEMPLATE_BUNDLE_MODULE_MODE "bundleModuleMode"

#define REACT_PRE_PROCESS_LIFECYCLE "getDerivedStateFromProps"
#define REACT_ERROR_PROCESS_LIFECYCLE "getDerivedStateFromError"
#define REACT_SHOULD_COMPONENT_UPDATE "shouldComponentUpdate"

#define REACT_SHOULD_COMPONENT_UPDATE_KEY "$$shouldComponentUpdate"
#define REACT_NATIVE_STATE_VERSION_KEY "$$nativeStateVersion"
#define REACT_JS_STATE_VERSION_KEY "$$jsStateVersion"
#define REACT_RENDER_ERROR_KEY "$$renderError"
#define JS_RENDER_ERROR "JS_RENDER_ERROR"
#define LEPUS_RENDER_ERROR "LEPUS_RENDER_ERROR"

static constexpr const char* SCREEN_METRICS_OVERRIDER =
    "getScreenMetricsOverride";

static constexpr const char* APP_TYPE_CARD = "card";
static constexpr const char* PAGE_ID = "card";
static constexpr const char* APP_TYPE_DYNAMIC_COMPONENT = "DynamicComponent";

static constexpr const char* DSL_TYPE_TT = "tt";
static constexpr const char* DSL_TYPE_REACT = "react";
static constexpr const char* DSL_TYPE_REACT_NODIFF = "react_nodiff";
static constexpr const char* DSL_TYPE_REACT_UNKOWN = "unkown";

enum class PackageInstanceDSL { TT, REACT, REACT_NODIFF, UNKOWN = 100 };
inline const char* GetDSLName(PackageInstanceDSL dsl) {
  switch (dsl) {
    case PackageInstanceDSL::TT:
      return DSL_TYPE_TT;
    case PackageInstanceDSL::REACT:
      return DSL_TYPE_REACT;
    case PackageInstanceDSL::REACT_NODIFF:
      return DSL_TYPE_REACT_NODIFF;
    default:
      return DSL_TYPE_REACT_UNKOWN;
  }
}

inline PackageInstanceDSL GetDSLType(const char* dsl) {
  if (strcmp(DSL_TYPE_TT, dsl) == 0) {
    return PackageInstanceDSL::TT;
  }
  if (strcmp(DSL_TYPE_REACT, dsl) == 0) {
    return PackageInstanceDSL::REACT;
  }
  if (strcmp(DSL_TYPE_REACT_NODIFF, dsl) == 0) {
    return PackageInstanceDSL::REACT_NODIFF;
  }
  return PackageInstanceDSL::UNKOWN;
}

static constexpr const char* BUNDLE_MODULE_MODE_RETURN_BY_FUNCTION =
    "ReturnByFunction";

enum class PackageInstanceBundleModuleMode {
  EVAL_REQUIRE_MODE = 0,       // default
  RETURN_BY_FUNCTION_MODE = 1  // enable flag on lynx_core bundler
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_GENERATOR_TTML_CONSTANT_H_
