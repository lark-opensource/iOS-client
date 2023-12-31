// Copyright 2023 The Lynx Authors. All rights reserved.

#include "jsbridge/jscache/js_cache_manager_facade.h"

#include <memory>
#include <utility>

#include "jsbridge/bindings/js_app.h"
#include "jsbridge/quickjs/quickjs_cache_generator.h"
#include "jsbridge/quickjs/quickjs_cache_manager.h"
#include "jsbridge/runtime/runtime_constant.h"
#include "tasm/binary_decoder/lynx_template_bundle.h"

namespace lynx {
namespace piper {
namespace cache {
void JsCacheManagerFacade::PostCacheGenerationTask(
    const tasm::LynxTemplateBundle& bundle, const std::string& template_url,
    JsEngineType engine_type) {
  auto js_sources = bundle.GetJsSources();
  auto iter = js_sources.find(runtime::kAppServiceJSName);
  if (iter != js_sources.end()) {
    const auto& [url, source] = *iter;
    PostCacheGenerationTask(bundle.IsCard()
                                ? url.str()
                                : piper::App::GenerateDynamicComponentSourceUrl(
                                      template_url, url.str()),
                            template_url, source.str(), engine_type);
  }
}

void JsCacheManagerFacade::PostCacheGenerationTask(
    const std::string& source_url, const std::string& template_url,
    std::string source, JsEngineType engine_type) {
  LOGI("JsCacheManagerFacade::PostCacheGenerationTask source_url: "
       << source_url << " template_url: " << template_url
       << " engine_type: " << static_cast<int>(engine_type));
  auto buffer = std::make_shared<StringBuffer>(std::move(source));
  switch (engine_type) {
    case JsEngineType::V8:
      LOGI("PostCacheGenerationTask for V8 is not supported");
      return;
    case JsEngineType::JSC:
      LOGI("PostCacheGenerationTask for JSC is not supported");
      return;
    case JsEngineType::QUICK_JS: {
      PostCacheGenerationTaskQuickJs(source_url, template_url, buffer);
      return;
    }
  }
}

inline void JsCacheManagerFacade::PostCacheGenerationTaskQuickJs(
    const std::string& source_url, const std::string& template_url,
    const std::shared_ptr<StringBuffer>& buffer) {
#ifdef QUICKJS_CACHE_UNITTEST
  post_cache_generation_task_quickjs_for_testing(source_url, template_url,
                                                 buffer);
#else
  auto generator =
      std::make_unique<cache::QuickjsCacheGenerator>(source_url, buffer);
  QuickjsCacheManager::GetInstance().RequestCacheGeneration(
      source_url, template_url, buffer, std::move(generator), false);
#endif
}
}  // namespace cache
}  // namespace piper
}  // namespace lynx
