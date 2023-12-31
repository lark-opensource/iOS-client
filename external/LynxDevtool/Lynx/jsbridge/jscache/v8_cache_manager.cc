// Copyright 2022 The Lynx Authors. All rights reserved.

#include "jsbridge/jscache/v8_cache_manager.h"

#include <memory>
#include <string>
#include <utility>

#include "base/lynx_env.h"

namespace lynx {
namespace piper {
namespace cache {
__attribute__((visibility("default"))) std::shared_ptr<Buffer> TryGetCacheV8(
    const std::string &source_url, const std::string &template_url,
    const std::shared_ptr<const Buffer> &buffer,
    std::unique_ptr<CacheGenerator> cache_generator) {
  return V8CacheManager::GetInstance().TryGetCache(
      source_url, template_url, buffer, std::move(cache_generator));
}

__attribute__((visibility("default"))) void RequestCacheGenerationV8(
    const std::string &source_url, const std::string &template_url,
    const std::shared_ptr<const Buffer> &buffer,
    std::unique_ptr<CacheGenerator> cache_generator, bool force) {
  V8CacheManager::GetInstance().RequestCacheGeneration(
      source_url, template_url, buffer, std::move(cache_generator), force);
}
}  // namespace cache
}  // namespace piper
}  // namespace lynx
