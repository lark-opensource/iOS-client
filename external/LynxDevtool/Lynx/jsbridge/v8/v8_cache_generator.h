// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_JSBRIDGE_V8_V8_CACHE_GENERATOR_H_
#define LYNX_JSBRIDGE_V8_V8_CACHE_GENERATOR_H_

#include <memory>
#include <string>

#include "jsbridge/jscache/cache_generator.h"

namespace lynx {
namespace piper {
namespace cache {

class V8CacheGenerator : public CacheGenerator {
 public:
  V8CacheGenerator(std::string origin_url,
                   std::shared_ptr<const Buffer> src_buffer);

  std::shared_ptr<Buffer> GenerateCache() override;

 private:
  bool GenerateCacheImpl(const std::string &origin_url,
                         const std::shared_ptr<const Buffer> &buffer,
                         std::string &contents);

  std::string origin_url_;
  std::shared_ptr<const Buffer> src_buffer_;
};

}  // namespace cache
}  // namespace piper
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_V8_V8_CACHE_GENERATOR_H_
