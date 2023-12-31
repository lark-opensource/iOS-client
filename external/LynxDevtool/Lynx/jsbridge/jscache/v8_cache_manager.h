// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_JSBRIDGE_JSCACHE_V8_CACHE_MANAGER_H_
#define LYNX_JSBRIDGE_JSCACHE_V8_CACHE_MANAGER_H_

#include <string>

#include "jsbridge/jscache/js_cache_manager.h"

namespace lynx {
namespace piper {
namespace cache {

class V8CacheManager : public JsCacheManager {
 public:
  static V8CacheManager &GetInstance() noexcept {
    static V8CacheManager instance;
    return instance;
  }

  V8CacheManager(const V8CacheManager &) = delete;
  void operator=(const V8CacheManager &) = delete;

 protected:
  virtual std::string CacheDirName() override { return "v8_cache"; }

  V8CacheManager() = default;
  virtual ~V8CacheManager() = default;
};

}  // namespace cache
}  // namespace piper
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_JSCACHE_V8_CACHE_MANAGER_H_
