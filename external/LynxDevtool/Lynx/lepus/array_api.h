// Copyright 2019 The Lynx Authors. All rights reserved.
#ifndef LYNX_LEPUS_ARRAY_API_H_
#define LYNX_LEPUS_ARRAY_API_H_

#include "config/config.h"
#if !ENABLE_JUST_LEPUSNG
#include "lepus/array.h"
#include "lepus/builtin.h"
#include "lepus/table.h"
#include "lepus/value.h"
#include "lepus/vm_context.h"
namespace lynx {
namespace lepus {

void RegisterArrayAPI(Context* ctx);

}  // namespace lepus
}  // namespace lynx
#endif  //  ENABLE_JUST_LEPUSNG
#endif  // LYNX_LEPUS_ARRAY_API_H_
