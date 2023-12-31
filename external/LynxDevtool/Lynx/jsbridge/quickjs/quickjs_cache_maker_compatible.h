// Copyright 2017 The Lynx Authors. All rights reserve
//
// Created by 李岩波 on 2019-11-17.
//

#ifndef LYNX_JSBRIDGE_QUICKJS_QUICKJS_CACHE_MAKER_COMPATIBLE_H_
#define LYNX_JSBRIDGE_QUICKJS_QUICKJS_CACHE_MAKER_COMPATIBLE_H_

#include <stdint.h>

#include <climits>
#include <cmath>
#include <memory>
#include <mutex>
#include <string>
#include <unordered_map>
#include <vector>

#include "jsbridge/jscache/js_cache_manager.h"
#include "jsbridge/quickjs/quickjs_helper.h"

namespace lynx {
namespace piper {
class QuickjsCacheMaker : public cache::AbstractJsCacheManager {
 public:
  static QuickjsCacheMaker &GetInstance() noexcept {
    static QuickjsCacheMaker instance;
    return instance;
  }

  /**
   * Get cache if existed.
   * @param url url of js file.
   * @param template_url url of the template.
   * @param buffer source code of js file.
   * @return cache buffer; or nullptr if no cache existed.
   */
  virtual std::shared_ptr<Buffer> TryGetCache(
      const std::string &url, const std::string &template_url,
      const std::shared_ptr<const Buffer> &buffer);

  QuickjsCacheMaker(const QuickjsCacheMaker &) = delete;
  void operator=(const QuickjsCacheMaker &) = delete;

 protected:
  /**
   * Generate cache in background thread.
   * @param source_url url of js file.
   * @param filename filename to save cache.
   * @param buffer source code of js file.
   */
  void MakeCacheBackground(const std::string &source_url,
                           const std::string &filename,
                           const std::shared_ptr<const Buffer> &buffer);

  /**
   * Generate cache.
   * @param source_url url of js file.
   * @param filename filename to save cache.
   * @param buffer source code of js file.
   */
  void DoMakeCache(const std::string source_url, const std::string filename,
                   const std::shared_ptr<const Buffer> buffer);

  /**
   * Generate cache buffer & save to storage.
   * @param source_url url of js file.
   * @param filename filename to save cache.
   * @param buffer source code of js file.
   * @param contents generated cache buffer.
   * @return true if success; or false if failed.
   */
  bool GenerateCache(const std::string &source_url, const std::string &filename,
                     const std::shared_ptr<const Buffer> &buffer,
                     std::string &contents);

  /**
   * Generate cache buffer.
   * @param ctx quickjs context.
   * @param source_url url of js file.
   * @param filename filename to save cache.
   * @param buffer source code of js file.
   * @param contents generated cache buffer.
   * @return true if success; or false if failed.
   */
  bool CompileJS(LEPUSContext *ctx, const std::string &source_url,
                 const std::string &filename,
                 const std::shared_ptr<const Buffer> &buffer,
                 std::string &contents);

  /**
   * Save cache to storage.
   * @param ctx quickjs context.
   * @param filename filename to save cache.
   * @param obj cache object.
   * @param contents generated cache buffer.
   * @return true if success; or false if failed.
   */
  bool MakeBytecodePersistent(LEPUSContext *ctx, const std::string &filename,
                              LEPUSValueConst obj, std::string &contents);

  virtual std::string CacheDirName() override { return "lynx_quickjs"; }

  bool IsJsFileSupported(const std::string &source_url) override {
    return IsCoreJS(source_url);
  }

  std::vector<std::string> execute_tasks_;
  std::unordered_map<std::string, std::shared_ptr<Buffer>> cache_;
  std::mutex cache_lock_;

  QuickjsCacheMaker() = default;
  virtual ~QuickjsCacheMaker() = default;
};

}  // namespace piper
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_QUICKJS_QUICKJS_CACHE_MAKER_COMPATIBLE_H_
