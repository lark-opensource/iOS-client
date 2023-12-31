// Copyright 2019 The Lynx Authors. All rights reserved.
#include "lepus/builtin.h"

#include "base/trace_event/trace_event.h"
#include "config/config.h"
#include "tasm/lynx_trace_event.h"
#if !ENABLE_JUST_LEPUSNG
#include "lepus/array_api.h"
#include "lepus/base_api.h"
#include "lepus/date_api.h"
#include "lepus/function_api.h"
#include "lepus/json_api.h"
#include "lepus/lepus_date_api.h"
#include "lepus/math_api.h"
#include "lepus/regexp_api.h"
#include "lepus/string_api.h"
#include "lepus/table_api.h"
#endif

namespace lynx {
namespace lepus {

#if !ENABLE_JUST_LEPUSNG
void RegisterCFunction(Context* context, const char* name, CFunction function) {
  Value value(function);
  VMContext::Cast(context)->SetGlobalData(name, value);
}

void RegisterBuiltinFunction(Context* context, const char* name,
                             CFunction function) {
  Value value(function);
  VMContext::Cast(context)->SetBuiltinData(name, value);
}

void RegisterBuiltFunction(Context* context, const char* name,
                           CFunction function) {
  Value value(function);
  VMContext::Cast(context)->SetBuiltinData(name, value);
}
void RegisterBuiltinFunctionTable(Context* context, const char* name,
                                  lynx::base::scoped_refptr<Dictionary> table) {
  Value value(table);
  VMContext::Cast(context)->builtin()->Set(name, value);
}

void RegisterFunctionTable(Context* context, const char* name,
                           lynx::base::scoped_refptr<Dictionary> table) {
  Value value(table);
  VMContext::Cast(context)->global()->Set(name, value);
}

void RegisterTableFunction(Context* context,
                           lynx::base::scoped_refptr<Dictionary> table,
                           const char* name, CFunction function) {
  Value value(function);
  table->SetValue(name, value);
}

void RegisterBuiltin(Context* ctx) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "RegisterBuiltin");
  RegisterBaseAPI(ctx);
  RegisterStringAPI(ctx);
  RegisterStringPrototypeAPI(ctx);
  RegisterMathAPI(ctx);
  RegisterArrayAPI(ctx);
  RegisterDateAPI(ctx);
  RegisterJSONAPI(ctx);
  if (lynx::tasm::Config::IsHigherOrEqual(
          reinterpret_cast<VMContext*>(ctx)->GetSdkVersion(),
          FEATURE_CONTROL_VERSION_2)) {
    RegisterLepusDateAPI(ctx);
    RegisterLepusDatePrototypeAPI(ctx);
    RegisterREGEXPPrototypeAPI(ctx);
    RegisterFunctionAPI(ctx);
    RegisterTableAPI(ctx);
    RegisterNumberAPI(ctx);
  }
}
#endif

void RegisterNGCFunction(Context* ctx, const char* name,
                         LEPUSCFunction* function) {
  if (ctx->IsLepusNGContext()) {
    QuickContext* quick_ctx = QuickContext::Cast(ctx);
    quick_ctx->RegisterGlobalFunction(name, function);
  } else {
    assert(false);
  }
}
}  // namespace lepus
}  // namespace lynx
