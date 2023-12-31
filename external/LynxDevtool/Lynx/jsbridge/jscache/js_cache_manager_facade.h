// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef LYNX_JSBRIDGE_JSCACHE_JS_CACHE_MANAGER_FACADE_H_
#define LYNX_JSBRIDGE_JSCACHE_JS_CACHE_MANAGER_FACADE_H_

#include <memory>
#include <string>

namespace lynx {
namespace tasm {
class LynxTemplateBundle;
}

namespace piper {
class StringBuffer;

namespace cache {
enum class JsEngineType {
  V8 = 0,
  JSC = 1,
  QUICK_JS = 2,
};

// The JsCacheManagerFacade class is the C++ layer interface of Code Cache, and
// it is a wrapper of the JsCacheManager class. This class receives different
// parameter inputs, forwards the operation request to a specific class
// according to the target JS engine type, and hides the specific
// implementation. The methods of this class guarantee thread safety for code
// cache operations (excluding reading and writing of incoming parameters, which
// need to be guaranteed by the caller).
class JsCacheManagerFacade {
 public:
  // The PostCacheGenerationTask method makes a cache generation request to the
  // app-service.js code stored in the incoming LynxTemplateBundle. Cache
  // generation will be performed asynchronously on a background thread.
  static void PostCacheGenerationTask(const tasm::LynxTemplateBundle& bundle,
                                      const std::string& template_url,
                                      JsEngineType engine_type);

  static void PostCacheGenerationTask(const std::string& source_url,
                                      const std::string& template_url,
                                      std::string source,
                                      JsEngineType engine_type);

 private:
  static inline void PostCacheGenerationTaskQuickJs(
      const std::string& source_url, const std::string& template_url,
      const std::shared_ptr<StringBuffer>& buffer);

#ifdef QUICKJS_CACHE_UNITTEST
 public:
  static inline void (*post_cache_generation_task_quickjs_for_testing)(
      const std::string& source_url, const std::string& template_url,
      const std::shared_ptr<StringBuffer>& buffer) = nullptr;
#endif
};
}  // namespace cache
}  // namespace piper
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_JSCACHE_JS_CACHE_MANAGER_FACADE_H_
