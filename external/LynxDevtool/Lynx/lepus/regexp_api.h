//
// Created by zhangye on 2020/8/8.
//
#ifndef LYNX_LEPUS_REGEXP_API_H_
#define LYNX_LEPUS_REGEXP_API_H_

#include "config/config.h"

#if !ENABLE_JUST_LEPUSNG

#include "lepus/builtin.h"
#include "lepus/regexp.h"
#include "lepus/string_api.h"
#include "lepus/table.h"
#include "lepus/value.h"
#include "lepus/vm_context.h"
#define CAPTURE_COUNT_MAX 255

#ifdef __cplusplus
extern "C" {
#endif
#include "quickjs/include/libregexp.h"
#ifdef __cplusplus
}
#endif

namespace lynx {
namespace lepus {
void RegisterREGEXPPrototypeAPI(Context* ctx);
}  // namespace lepus
}  // namespace lynx
#endif  // ENABLE_JUST_LEPUSNG
#endif  // LYNX_LEPUS_REGEXP_API_H_
