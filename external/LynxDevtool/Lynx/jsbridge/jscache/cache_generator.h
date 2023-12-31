// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_JSBRIDGE_JSCACHE_CACHE_GENERATOR_H_
#define LYNX_JSBRIDGE_JSCACHE_CACHE_GENERATOR_H_

#include <memory>

#include "jsbridge/jsi/jsi.h"

namespace lynx {
namespace piper {
namespace cache {
class CacheGenerator {
 public:
  virtual ~CacheGenerator() = default;

  virtual std::shared_ptr<Buffer> GenerateCache() = 0;
};
}  // namespace cache
}  // namespace piper
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_JSCACHE_CACHE_GENERATOR_H_
