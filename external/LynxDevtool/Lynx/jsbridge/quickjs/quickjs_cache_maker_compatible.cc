// Copyright 2017 The Lynx Authors. All rights reserved
//
// Created by 李岩波 on 2019-11-17.
//

#include "jsbridge/quickjs/quickjs_cache_maker_compatible.h"

#include <sys/stat.h>
#include <sys/types.h>

#include <fstream>
#include <thread>
#include <utility>

#include "base/log/logging.h"
#include "base/lynx_env.h"
#include "base/md5.h"

#if defined(OS_ANDROID)
#include "base/android/android_jni.h"
#include "tasm/react/android/environment_android.h"
#endif

#if defined(OS_WIN)
#include <io.h>

#include <cstdio>

#include "base/paths_win.h"
#else
#include <unistd.h>
#endif

// 500k
#define MAX_CACHE_SIZE (500 * 1024)

namespace lynx {
namespace piper {

using detail::QuickjsHelper;

//
// request thread
//
std::shared_ptr<Buffer> QuickjsCacheMaker::TryGetCache(
    const std::string &source_url, const std::string &template_url,
    const std::shared_ptr<const Buffer> &buffer) {
  // 开关关闭
  if (!IsCacheEnabled() || buffer->size() > MAX_CACHE_SIZE) {
    LOGI("cache switch is disable or buffer size is too large:"
         << buffer->size());
    return nullptr;
  }

  if (!IsJsFileSupported(source_url)) {
    return nullptr;
  }

  DLOGI("using code cache for url : " << source_url);
  std::lock_guard<std::mutex> guard(cache_lock_);
  auto cache_it = cache_.find(source_url);
  if (cache_it != cache_.end()) {
    return cache_it->second;
  } else {
    std::string md5sum = lynx::base::md5(
        reinterpret_cast<const char *>(buffer->data()), buffer->size());
    const std::string filename = MakeFilename(md5sum);
    // 通过测试，文件读写速度明显快于js解析速度，所以首次会尝试从文件中读取js。
    // 一加手机上测试读取core.js 只需要2ms,
    // 而执行时间则需要40ms以上，低端机上更加明显，js解析速度远远低于
    // 文件读写速度，在荣耀4a上，读取需要30ms，而解析则需要300ms，所以提升至少10倍。
    // 由此带来的首次js的加载速度在已经存在缓存的情况下，会提升4-10倍以上，而二次加载则需要更少的时间，因为文件
    // 已经存在在内存中，无需读取，更加加速了执行速度。
    // 由此，缓存文件读取，直接在js线程执行，而无需再开新线程来进行。
    std::string data("");
    if (ReadFile(filename, data)) {
      std::shared_ptr<StringBuffer> result =
          std::make_shared<StringBuffer>(std::move(data));
      cache_.insert(std::make_pair(source_url, result));
      return result;
    } else {
      MakeCacheBackground(source_url, filename, buffer);
      return nullptr;
    }
  }
}

void QuickjsCacheMaker::MakeCacheBackground(
    const std::string &source_url, const std::string &filename,
    const std::shared_ptr<const Buffer> &buffer) {
  if (std::find(execute_tasks_.cbegin(), execute_tasks_.cend(), source_url) ==
      execute_tasks_.cend()) {
    execute_tasks_.push_back(source_url);
    std::thread t1(&QuickjsCacheMaker::DoMakeCache, this, source_url, filename,
                   buffer);
#ifdef QUICKJS_CACHE_UNITTEST
    cache_lock_.unlock();
    t1.join();
    cache_lock_.lock();
#else
    t1.detach();
#endif
  }
}

//
// background thread
//

void QuickjsCacheMaker::DoMakeCache(
    const std::string source_url, const std::string filename,
    const std::shared_ptr<const Buffer> buffer) {
#if defined(OS_ANDROID)
  base::android::AttachCurrentThread();
#endif
  auto start = std::chrono::high_resolution_clock::now();

  std::string contents("");
  if (GenerateCache(source_url, filename, buffer, contents)) {
    DLOGI("makeCache success!");
    std::shared_ptr<StringBuffer> result =
        std::make_shared<StringBuffer>(std::move(contents));
    cache_lock_.lock();
    cache_.insert(std::make_pair(source_url, result));
    cache_lock_.unlock();
  } else {
    LOGE("makeCache failed!");
  }

  auto finish = std::chrono::high_resolution_clock::now();
  UNUSED_LOG_VARIABLE auto cost =
      std::chrono::duration_cast<std::chrono::nanoseconds>(finish - start)
          .count() /
      1000000.0;
  LOGI("makeCache cost=" << cost);
#if defined(OS_ANDROID)
  base::android::DetachFromVM();
#endif
}

bool QuickjsCacheMaker::GenerateCache(
    const std::string &source_url, const std::string &filename,
    const std::shared_ptr<const Buffer> &buffer, std::string &contents) {
  LEPUSRuntime *rt = LEPUS_NewRuntime();
  LEPUS_SetRuntimeInfo(rt, "Lynx_JS");
  if (!rt) {
    LOGE("makeCache init quickjs runtime failed!");
    return false;
  }
  LEPUSContext *ctx = LEPUS_NewContext(rt);
  if (!ctx) {
    LOGE("init quickjs context failed!");
    LEPUS_FreeRuntime(rt);
    return false;
  }
  LEPUS_SetMaxStackSize(ctx, static_cast<size_t>(ULLONG_MAX));

  bool ret = CompileJS(ctx, source_url, filename, buffer, contents);

  LEPUS_FreeContext(ctx);
  LEPUS_FreeRuntime(rt);

  return ret;
}

bool QuickjsCacheMaker::MakeBytecodePersistent(LEPUSContext *ctx,
                                               const std::string &filename,
                                               LEPUSValueConst obj,
                                               std::string &contents) {
  uint8_t *out_buf;
  size_t out_buf_len;
  int flags;
  flags = LEPUS_WRITE_OBJ_BYTECODE;
  out_buf = LEPUS_WriteObject(ctx, &out_buf_len, obj, flags);
  if (!out_buf) {
    LOGE("out_buf has error!");
    UNUSED_LOG_VARIABLE LEPUSValue exception_val = LEPUS_GetException(ctx);
    LOGE(QuickjsHelper::getErrorMessage(ctx, exception_val));
    return false;
  }
  contents.append(reinterpret_cast<char *>(out_buf), out_buf_len);

  DLOGI("MakeBytecodePersistent file=" << filename);
  bool ret = WriteFile(filename, out_buf, out_buf_len);
  lepus_free(ctx, out_buf);
  return ret;
}

bool QuickjsCacheMaker::CompileJS(LEPUSContext *ctx,
                                  const std::string &source_url,
                                  const std::string &filename,
                                  const std::shared_ptr<const Buffer> &buffer,
                                  std::string &contents) {
  int eval_flags;
  LEPUSValue obj;

  eval_flags = LEPUS_EVAL_FLAG_COMPILE_ONLY | LEPUS_EVAL_TYPE_GLOBAL;
  obj = LEPUS_Eval(ctx, reinterpret_cast<const char *>(buffer->data()),
                   buffer->size(), source_url.c_str(), eval_flags);
  if (LEPUS_IsException(obj)) {
    LOGE("CompileJS failed:" << filename);
    UNUSED_LOG_VARIABLE LEPUSValue exception_val = LEPUS_GetException(ctx);
    LOGE(QuickjsHelper::getErrorMessage(ctx, exception_val));
    return false;
  }
  bool ret = MakeBytecodePersistent(ctx, filename, obj, contents);
  LEPUS_FreeValue(ctx, obj);
  return ret;
}

}  // namespace piper
}  // namespace lynx
