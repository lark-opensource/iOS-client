// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_JSBRIDGE_QUICKJS_QUICKJS_CACHE_MANAGER_H_
#define LYNX_JSBRIDGE_QUICKJS_QUICKJS_CACHE_MANAGER_H_

#include <stdint.h>

#include <cmath>
#include <cstdint>
#include <memory>
#include <mutex>
#include <string>
#include <unordered_map>
#include <vector>

#include "jsbridge/jscache/js_cache_manager.h"
#include "jsbridge/jscache/meta_data.h"
#include "jsbridge/quickjs/quickjs_helper.h"

namespace lynx {
namespace piper {
namespace cache {

class QuickjsCacheManager : public JsCacheManager {
 public:
  static QuickjsCacheManager &GetInstance() noexcept {
    static QuickjsCacheManager instance;
    return instance;
  }

  QuickjsCacheManager(const QuickjsCacheManager &) = delete;
  void operator=(const QuickjsCacheManager &) = delete;

 protected:
  virtual std::string CacheDirName() override { return "quickjs_cache"; }

  QuickjsCacheManager() = default;
  virtual ~QuickjsCacheManager() = default;
};

}  // namespace cache
}  // namespace piper
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_QUICKJS_QUICKJS_CACHE_MANAGER_H_
