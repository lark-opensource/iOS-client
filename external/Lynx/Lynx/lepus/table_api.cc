//
// Created by zhangye on 2020/8/19.
//
#include "lepus/table_api.h"
namespace lynx {
namespace lepus {

static Value Freeze(Context* context) {
  long params_count = context->GetParamsSize();
  DCHECK(params_count == 1);
  Value object = Value(context->GetParam(0)->Table());
  Value result = Value(Dictionary::Create());
  for (auto iter = object.Table()->begin(); iter != object.Table()->end();
       iter++) {
    result.Table()->SetValue(iter->first, iter->second);
  }
  return result;
}

static Value Keys(Context* context) {
  long params_count = context->GetParamsSize();
  DCHECK(params_count == 1);
  Value* param = context->GetParam(0);
  Value result = Value(CArray::Create());
  if (param->IsArray()) {
    size_t array_size = param->Array()->size();
    for (size_t i = 0; i < array_size; i++) {
      result.Array()->push_back(Value(StringImpl::Create(std::to_string(i))));
    }
  } else if (param->IsTable()) {
    for (auto& iter : *param->Table()) {
      result.Array()->push_back(Value(StringImpl::Create(iter.first.str())));
    }
  }
  return result;
}

static Value Assign(Context* context) {
  long params_count = context->GetParamsSize();
  DCHECK(params_count >= 1);
  Value* target = context->GetParam(0);
  switch (target->Type()) {
    case Value_Table: {
      for (int32_t i = 1; i < params_count; i++) {
        Value* source = context->GetParam(i);
        if (source->IsTable()) {
          for (const auto& iter : *(source->Table())) {
            target->Table()->SetValue(iter.first, iter.second);
          }
        }
      }
      break;
    }
    case Value_Array: {
      for (int32_t i = 1; i < params_count; i++) {
        Value* source = context->GetParam(i);
        int32_t index = 0;
        if (source->IsArray()) {
          size_t array_size = source->Array()->size();
          for (size_t j = 0; j < array_size; j++) {
            Value item = source->Array()->get(j);
            target->Array()->set(index++, item);
          }
        }
      }
      break;
    }
    default: {
      break;
    }
  }
  return *target;
}

void RegisterTableAPI(Context* ctx) {
  lynx::base::scoped_refptr<Dictionary> table = Dictionary::Create();
  RegisterTableFunction(ctx, table, "assign", &Assign);
  RegisterTableFunction(ctx, table, "freeze", &Freeze);
  RegisterTableFunction(ctx, table, "keys", &Keys);
  RegisterBuiltinFunctionTable(ctx, "Object", table);
}
}  // namespace lepus
}  // namespace lynx
