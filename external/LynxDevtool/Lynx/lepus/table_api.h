//
// Created by zhangye on 2020/8/17.
//
#ifndef LYNX_LEPUS_TABLE_API_H_
#define LYNX_LEPUS_TABLE_API_H_

#include "config/config.h"

#if !ENABLE_JUST_LEPUSNG
#include "lepus/builtin.h"
#include "lepus/table.h"
#include "lepus/value.h"
#include "lepus/vm_context.h"
namespace lynx {
namespace lepus {

void RegisterTableAPI(Context* ctx);

}  // namespace lepus
}  // namespace lynx
#endif  // ENABLE_JUST_LEPUSNG
#endif  // LYNX_LEPUS_TABLE_API_H_
