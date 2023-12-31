#ifndef LYNX_LEPUS_FUNCTION_API_H_
#define LYNX_LEPUS_FUNCTION_API_H_

#include "config/config.h"

#if !ENABLE_JUST_LEPUSNG
#include "lepus/builtin.h"
namespace lynx {
namespace lepus {
void RegisterFunctionAPI(Context* ctx);
}  // namespace lepus
}  // namespace lynx
#endif  // ENABLE_JUST_LEPUSNG
#endif  // LYNX_LEPUS_FUNCTION_API_H_
