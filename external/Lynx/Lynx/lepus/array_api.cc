//
// Created by zhangye on 2020/8/20.
//
#include "lepus/array_api.h"

#include <string>

namespace lynx {
namespace lepus {

static Value Push(Context* context) {
  auto params_count = context->GetParamsSize();
  DCHECK(params_count >= 1);
  Value* this_obj = context->GetParam(params_count - 1);
  DCHECK(this_obj->IsArray());

  for (auto i = 0; i < params_count - 1; i++) {
    Value* val = context->GetParam(i);
    this_obj->Array()->push_back(*val);
  }
  return Value(static_cast<uint64_t>(this_obj->Array()->size()));
}

static Value Pop(Context* context) {
  auto params_count = context->GetParamsSize();
  DCHECK(params_count == 1);
  Value* this_obj = context->GetParam(params_count - 1);
  DCHECK(this_obj->IsArray());
  this_obj->Array()->pop_back();
  return Value(static_cast<uint64_t>(this_obj->Array()->size()));
}

static Value Shift(Context* context) {
  auto params_count = context->GetParamsSize();
  DCHECK(params_count == 1);
  Value* this_obj = context->GetParam(params_count - 1);
  DCHECK(this_obj->IsArray());

  Value val = this_obj->Array()->get_shift();
  return val;
}

static Value Map(Context* context) {
  auto params_count = context->GetParamsSize();
  DCHECK(params_count == 2);
  Value* map_function = context->GetParam(0);
  Value* this_obj = context->GetParam(1);
  Value* index = this_obj + 1;
  Value* this_array = this_obj + 2;
  size_t length = this_obj->Array()->size();
  *this_array = *this_obj;
  Value array_temp_ = (*this_obj), ret, map_ret;
  ret.SetArray(CArray::Create());
  for (size_t i = 0; i < length; i++) {
    *this_obj = array_temp_.Array()->get(i);
    index->SetNumber(static_cast<int64_t>(i));
    static_cast<VMContext*>(context)->CallFunction(map_function, 3, &map_ret);
    ret.Array()->push_back(map_ret);
  }
  return ret;
}

static Value Filter(Context* context) {
  auto params_count = context->GetParamsSize();
  DCHECK(params_count == 2);
  Value* filter_function = context->GetParam(0);
  Value* this_obj = context->GetParam(1);
  Value* index = this_obj + 1;
  Value* this_array = this_obj + 2;
  size_t length = this_obj->Array()->size();
  *this_array = *this_obj;
  Value array_temp_ = (*this_obj), ret, filter_ret;
  ret.SetArray(CArray::Create());
  for (size_t i = 0; i < length; i++) {
    *this_obj = array_temp_.Array()->get(i);
    index->SetNumber(static_cast<int64_t>(i));
    static_cast<VMContext*>(context)->CallFunction(filter_function, 3,
                                                   &filter_ret);
    if (filter_ret.Bool()) {
      ret.Array()->push_back(*this_obj);
    }
  }
  return ret;
}

static Value Concat(Context* context) {
  auto params_count = context->GetParamsSize();
  Value* this_obj = context->GetParam(params_count - 1);
  DCHECK(this_obj->IsArray());

  Value result = Value(CArray::Create());
  for (size_t i = 0; i < this_obj->Array()->size(); i++) {
    result.Array()->push_back(this_obj->Array()->get(i));
  }
  for (int i = 1; i < params_count; i++) {
    if (context->GetParam(i - 1)->IsArray()) {
      for (size_t j = 0; j < context->GetParam(i - 1)->Array()->size(); j++) {
        result.Array()->push_back(context->GetParam(i - 1)->Array()->get(j));
      }
    } else {
      result.Array()->push_back(*context->GetParam(i - 1));
    }
  }

  return result;
}

static std::string CastToString(Value v) {
  std::string result;
  switch (v.Type()) {
    case lepus::ValueType::Value_Nil:
    case lepus::ValueType::Value_Undefined:
      result = "";
      break;
    case lepus::ValueType::Value_Double:
      result = std::to_string(v.Number());
      break;
    case lepus::ValueType::Value_Int32:
      result = std::to_string(static_cast<int32_t>(v.Number()));
      break;
    case lepus::ValueType::Value_Int64:
      result = std::to_string(static_cast<int64_t>(v.Number()));
      break;
    case lepus::ValueType::Value_UInt32:
      result = std::to_string(static_cast<uint32_t>(v.Number()));
      break;
    case lepus::ValueType::Value_UInt64:
      result = std::to_string(static_cast<uint64_t>(v.Number()));
      break;
    case lepus::ValueType::Value_Bool: {
      if (v.Number()) {
        result = "true";
      } else {
        result = "false";
      }
    } break;
    case lepus::ValueType::Value_String:
      result = v.String()->str();
      break;
    case lepus::ValueType::Value_Table:
      result = "[object Object]";
      break;
    case lepus::ValueType::Value_Array:
      for (size_t i = 0; i < v.Array()->size(); i++) {
        result += CastToString(v.Array()->get(i));
        if (i != (v.Array()->size() - 1)) {
          result += ',';
        }
      }
      break;
    case lepus::ValueType::Value_RegExp:
      result += "/";
      result += v.RegExp()->get_pattern().str();
      result += "/";
      result += v.RegExp()->get_flags().str();
      break;
    case lepus::ValueType::Value_CDate: {
      std::stringstream ss;
      v.Date()->print(ss);
      result = ss.str();
      result.pop_back();
      break;
    }
    case lepus::ValueType::Value_NaN: {
      result = "NaN";
      break;
    }
    case lepus::ValueType::Value_Closure:
    case lepus::ValueType::Value_CFunction:
    case lepus::ValueType::Value_CPointer:
    case lepus::ValueType::Value_RefCounted:
    case lepus::ValueType::Value_JSObject:
      break;
    case lepus::ValueType::Value_ByteArray: {
      result = "ByteArray";
      break;
    }
    case lepus::ValueType::Value_PrimJsValue:
    case lepus::ValueType::Value_TypeCount:
      break;
  }
  return result;
}

static Value Join(Context* context) {
  auto params_count = context->GetParamsSize();
  Value* this_obj = context->GetParam(params_count - 1);
  DCHECK(this_obj->IsArray());

  std::string result = "";
  std::string separator = ",";
  if (params_count == 2) {
    separator = context->GetParam(0)->String()->str();
  }

  for (size_t i = 0; i < this_obj->Array()->size(); i++) {
    if (i < this_obj->Array()->size() - 1) {
      result += (CastToString(this_obj->Array()->get(i)) + separator);
    } else {
      result += (CastToString(this_obj->Array()->get(i)));
    }
  }
  return Value(StringImpl::Create(result));
}

static Value FindIndex(Context* context) {
  auto params_count = context->GetParamsSize();
  DCHECK(params_count == 2);
  Value* find_index_function = context->GetParam(0);
  Value* this_obj = context->GetParam(1);
  Value* index = this_obj + 1;
  Value* this_array = this_obj + 2;
  size_t length = this_obj->Array()->size();
  *this_array = *this_obj;
  Value array_temp_ = (*this_obj), ret, find_index_ret;
  ret = Value(-1);
  for (int i = 0; static_cast<size_t>(i) < length; i++) {
    *this_obj = array_temp_.Array()->get(i);
    index->SetNumber(static_cast<int64_t>(i));
    static_cast<VMContext*>(context)->CallFunction(find_index_function, 3,
                                                   &find_index_ret);
    if ((find_index_ret.IsTrue())) {
      ret = Value(i);
      break;
    }
  }
  return ret;
}

static Value Find(Context* context) {
  auto params_count = context->GetParamsSize();
  DCHECK(params_count == 2);
  Value* find_index_function = context->GetParam(0);
  Value* this_obj = context->GetParam(1);
  Value* index = this_obj + 1;
  Value* this_array = this_obj + 2;
  size_t length = this_obj->Array()->size();
  *this_array = *this_obj;
  Value array_temp_ = (*this_obj), ret, find_index_ret;
  ret = Value();
  for (size_t i = 0; i < length; i++) {
    *this_obj = array_temp_.Array()->get(i);
    index->SetNumber(static_cast<int64_t>(i));
    static_cast<VMContext*>(context)->CallFunction(find_index_function, 3,
                                                   &find_index_ret);
    if ((find_index_ret.IsTrue())) {
      ret = *this_obj;
      break;
    }
  }
  return ret;
}

static Value Includes(Context* context) {
  auto params_count = context->GetParamsSize();
  Value* this_obj = context->GetParam(params_count - 1);
  DCHECK(this_obj->IsArray());

  if (params_count == 1) {
    return Value(false);
  }

  int64_t start_find = 0;

  if (params_count == 3) {
    int param2 = context->GetParam(1)->Number();
    if (param2 >= 0) {
      start_find = param2;
    } else {
      start_find = (this_obj->Array()->size() + param2);
      start_find = start_find < 0 ? 0 : start_find;
    }
  }

  Value* param1 = context->GetParam(0);
  for (size_t i = static_cast<size_t>(start_find);
       i < this_obj->Array()->size(); i++) {
    if (this_obj->Array()->get(i) == *param1) {
      return Value(true);
    }
  }
  return Value(false);
}

static Value ArraySlice(Context* context) {
  auto params_count = context->GetParamsSize();
  Value* this_val = context->GetParam(params_count - 1);
  DCHECK(this_val->IsArray());

  int64_t start_index = 0;
  size_t end_index = this_val->Array()->size();

  if (params_count != 1) {
    int param1 = context->GetParam(0)->Number();
    if (param1 >= 0) {
      start_index = param1;
    } else {
      start_index = this_val->Array()->size() + param1;
      start_index = start_index < 0 ? 0 : start_index;
    }
  }

  if (params_count == 3) {
    int param2 = context->GetParam(1)->Number();
    if (param2 >= 0) {
      end_index = static_cast<size_t>(param2) > this_val->Array()->size()
                      ? this_val->Array()->size()
                      : param2;
    } else {
      end_index = (this_val->Array()->size() + param2) < 0
                      ? 0
                      : (this_val->Array()->size() + param2);
    }
  }

  Value result = Value(CArray::Create());
  for (size_t i = static_cast<size_t>(start_index); i < end_index; i++) {
    result.Array()->push_back(this_val->Array()->get(i));
  }
  return result;
}

static Value ForEach(Context* context) {
  auto params_count = context->GetParamsSize();
  DCHECK(params_count == 2);
  Value* foreach_function = context->GetParam(0);
  Value* this_obj = context->GetParam(1);
  Value* index = this_obj + 1;
  Value* this_array = this_obj + 2;
  size_t length = this_obj->Array()->size();
  *this_array = *this_obj;
  Value array_temp_ = (*this_obj), ret, foreach_ret;
  ret.SetArray(CArray::Create());
  for (size_t i = 0; i < length; i++) {
    *this_obj = array_temp_.Array()->get(i);
    index->SetNumber(static_cast<int64_t>(i));
    static_cast<VMContext*>(context)->CallFunction(foreach_function, 3,
                                                   &foreach_ret);
  }
  return ret;
}

void RegisterArrayAPI(Context* ctx) {
  lynx::base::scoped_refptr<Dictionary> table = Dictionary::Create();
  RegisterTableFunction(ctx, table, "push", &Push);
  RegisterTableFunction(ctx, table, "pop", &Pop);
  RegisterTableFunction(ctx, table, "shift", &Shift);
  RegisterTableFunction(ctx, table, "map", &Map);
  RegisterTableFunction(ctx, table, "filter", &Filter);
  RegisterTableFunction(ctx, table, "concat", &Concat);
  RegisterTableFunction(ctx, table, "join", &Join);
  RegisterTableFunction(ctx, table, "findIndex", &FindIndex);
  RegisterTableFunction(ctx, table, "find", &Find);
  RegisterTableFunction(ctx, table, "includes", &Includes);
  RegisterTableFunction(ctx, table, "slice", &ArraySlice);
  RegisterTableFunction(ctx, table, "forEach", &ForEach);
  reinterpret_cast<VMContext*>(ctx)->SetArrayPrototype(Value(table));
}
}  // namespace lepus
}  // namespace lynx
