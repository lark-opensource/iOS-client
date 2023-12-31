// Copyright 2019 The Lynx Authors. All rights reserved.
#ifndef LYNX_LEPUS_BUILTIN_H_
#define LYNX_LEPUS_BUILTIN_H_

#include "lepus/context.h"
#include "lepus/quick_context.h"
#include "lepus/table.h"
#include "tasm/config.h"

namespace lynx {
namespace lepus {
void RegisterBuiltin(Context* context);
void RegisterCFunction(Context* context, const char* name, CFunction function);
void RegisterBuiltinFunction(Context* context, const char* name,
                             CFunction function);
void RegisterBuiltinFunctionTable(
    Context* context, const char* name,
    lynx::base::scoped_refptr<Dictionary> function);
void RegisterFunctionTable(Context* context, const char* name,
                           lynx::base::scoped_refptr<Dictionary> function);
void RegisterTableFunction(Context* context,
                           lynx::base::scoped_refptr<Dictionary> table,
                           const char* name, CFunction function);

void RegisterNGCFunction(Context* ctx, const char* name,
                         LEPUSCFunction* function);

}  // namespace lepus
}  // namespace lynx

#endif  // LYNX_LEPUS_BUILTIN_H_
