// Copyright 2022 The Lynx Authors. All rights reserved.

#include "jsbridge/quickjs/quickjs_cache_generator.h"

#include <climits>
#include <memory>
#include <string>
#include <utility>

#include "jsbridge/quickjs/quickjs_helper.h"

namespace lynx {
namespace piper {
namespace cache {

QuickjsCacheGenerator::QuickjsCacheGenerator(
    std::string source_url, std::shared_ptr<const Buffer> src_buffer)
    : source_url_(std::move(source_url)), src_buffer_(std::move(src_buffer)) {}

std::shared_ptr<Buffer> QuickjsCacheGenerator::GenerateCache() {
  std::string cache;
  if (!GenerateCacheImpl(source_url_, src_buffer_, cache)) {
    return nullptr;
  }
  return std::make_shared<StringBuffer>(std::move(cache));
}

bool QuickjsCacheGenerator::GenerateCacheImpl(
    const std::string &source_url, const std::shared_ptr<const Buffer> &buffer,
    std::string &contents) {
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
  LEPUS_SetMaxStackSize(ctx, static_cast<size_t>(ULONG_MAX));

  bool ret = CompileJS(ctx, source_url, buffer, contents);

  LEPUS_FreeContext(ctx);
  LEPUS_FreeRuntime(rt);

  return ret;
}

bool QuickjsCacheGenerator::CompileJS(
    LEPUSContext *ctx, const std::string &source_url,
    const std::shared_ptr<const Buffer> &buffer, std::string &contents) {
  int eval_flags;
  LEPUSValue obj;

  eval_flags = LEPUS_EVAL_FLAG_COMPILE_ONLY | LEPUS_EVAL_TYPE_GLOBAL;
  obj = LEPUS_Eval(ctx, reinterpret_cast<const char *>(buffer->data()),
                   buffer->size(), source_url.c_str(), eval_flags);
  if (LEPUS_IsException(obj)) {
    LOGE("CompileJS failed:" << source_url);
    UNUSED_LOG_VARIABLE LEPUSValue exception_val = LEPUS_GetException(ctx);
    LOGE(detail::QuickjsHelper::getErrorMessage(ctx, exception_val));
    return false;
  }

  uint8_t *out_buf;
  size_t out_buf_len;
  out_buf = LEPUS_WriteObject(ctx, &out_buf_len, obj, LEPUS_WRITE_OBJ_BYTECODE);
  if (!out_buf) {
    LOGE("out_buf has error!");
    UNUSED_LOG_VARIABLE LEPUSValue exception_val = LEPUS_GetException(ctx);
    LOGE(detail::QuickjsHelper::getErrorMessage(ctx, exception_val));
    LEPUS_FreeValue(ctx, obj);
    return false;
  }
  contents.append(reinterpret_cast<char *>(out_buf), out_buf_len);
  lepus_free(ctx, out_buf);

  LEPUS_FreeValue(ctx, obj);
  return true;
}

}  // namespace cache
}  // namespace piper
}  // namespace lynx
