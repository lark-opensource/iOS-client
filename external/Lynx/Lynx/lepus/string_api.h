// Copyright 2019 The Lynx Authors. All rights reserved.
#ifndef LYNX_LEPUS_STRING_API_H_
#define LYNX_LEPUS_STRING_API_H_

#include <string>
#include <vector>

#include "config/config.h"

#if !ENABLE_JUST_LEPUSNG

#include <assert.h>

#include "lepus/builtin.h"
#include "lepus/lepus_string.h"
#include "lepus/string_util.h"
#include "lepus/table.h"
#include "lepus/value.h"
#include "lepus/vm_context.h"
#define CAPTURE_COUNT_MAX 255
#ifdef __cplusplus
extern "C" {
#endif
#include "quickjs/include/cutils.h"
#include "quickjs/include/libregexp.h"
#ifdef __cplusplus
}
#endif

namespace lynx {
namespace lepus {
int GetRegExpFlags(std::string flags);
void GetUnicodeFromUft8(const char* buf, size_t buf_len, size_t& unicode_len,
                        bool& has_unicode, std::vector<uint16_t>& result);

void RegisterStringAPI(Context* ctx);
void RegisterStringPrototypeAPI(Context* ctx);
std::string GetReplaceStr(const std::string& data,
                          const std::string& need_to_replace_str,
                          const std::string& replace_to_str, int32_t position);
}  // namespace lepus
}  // namespace lynx

#endif  // ENABLE_JUST_LEPUSNG
#endif  // LYNX_LEPUS_STRING_API_H_
