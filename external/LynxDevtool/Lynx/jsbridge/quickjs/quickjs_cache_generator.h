// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_JSBRIDGE_QUICKJS_QUICKJS_CACHE_GENERATOR_H_
#define LYNX_JSBRIDGE_QUICKJS_QUICKJS_CACHE_GENERATOR_H_

#include <memory>
#include <string>

#include "jsbridge/jscache/cache_generator.h"

struct LEPUSContext;

namespace lynx {
namespace piper {
namespace cache {

class QuickjsCacheGenerator : public CacheGenerator {
 public:
  QuickjsCacheGenerator(std::string source_url,
                        std::shared_ptr<const Buffer> src_buffer);

  std::shared_ptr<Buffer> GenerateCache() override;

 private:
  bool GenerateCacheImpl(const std::string &source_url,
                         const std::shared_ptr<const Buffer> &buffer,
                         std::string &contents);

  bool CompileJS(LEPUSContext *ctx, const std::string &source_url,
                 const std::shared_ptr<const Buffer> &buffer,
                 std::string &contents);

  std::string source_url_;
  std::shared_ptr<const Buffer> src_buffer_;
};

}  // namespace cache
}  // namespace piper
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_QUICKJS_QUICKJS_CACHE_GENERATOR_H_
