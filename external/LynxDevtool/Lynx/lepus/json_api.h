//
// Created by zhangye on 2020/6/28.
//
#ifndef LYNX_LEPUS_JSON_API_H_
#define LYNX_LEPUS_JSON_API_H_

#include <string>

#include "config/config.h"

#if !ENABLE_JUST_LEPUSNG
#include "lepus/json_parser.h"
namespace lynx {
namespace lepus {
Value Stringify(Context* context) {
  long params_count = context->GetParamsSize();
  DCHECK(params_count == 1);
  Value* arg = context->GetParam(0);
  if (arg->IsString()) {
    return Value(StringImpl::Create(arg->String()->str()));
  } else if (arg->IsNil() || arg->IsUndefined()) {
    return Value(StringImpl::Create("null"));
  }
  DCHECK(arg->IsTable() || arg->IsArray());
  std::string str = lepusValueToJSONString(*arg);
  return Value(StringImpl::Create(str));
}

Value Parse(Context* context) {
  long params_count = context->GetParamsSize();
  DCHECK(params_count == 1);
  Value* arg = context->GetParam(0);
  Value res;
  if (arg->IsString()) {
    res = jsonValueTolepusValue(arg->String()->c_str());
  } else {
    // other type
    res = jsonValueTolepusValue("");
  }
  return res;
}

void RegisterJSONAPI(Context* ctx) {
  lynx::base::scoped_refptr<Dictionary> table = Dictionary::Create();
  RegisterTableFunction(ctx, table, "stringify", &Stringify);
  RegisterTableFunction(ctx, table, "parse", &Parse);
  RegisterBuiltinFunctionTable(ctx, "JSON", table);
}
}  // namespace lepus
}  // namespace lynx
#endif  // ENABLE_JUST_LEPUSNG
#endif  // LYNX_LEPUS_JSON_API_H_
