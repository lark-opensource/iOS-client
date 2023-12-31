#include "jsbridge/utils/utils.h"

#include <memory>
#include <utility>

#include "config/config.h"
#include "jsbridge/bindings/big_int/constants.h"
#include "jsbridge/utils/jsi_object_wrapper.h"
#include "lepus/table.h"
#include "tasm/config.h"

namespace lynx {
namespace piper {

std::optional<Value> valueFromLepus(
    Runtime& runtime, const lepus::Value& data,
    JSIObjectWrapperManager* jsi_object_wrapper_manager) {
  piper::Scope scope(runtime);
  if (data.IsJSValue()) {
    LOGE("!!! value form lepus: is JSValue");
    return Value::null();
  }
  switch (data.Type()) {
    case lepus::ValueType::Value_Nil:
      return Value::null();
    case lepus::ValueType::Value_Undefined:
      return Value::undefined();
    case lepus::ValueType::Value_Double:
    case lepus::ValueType::Value_UInt32:
    case lepus::ValueType::Value_Int32:
      return Value(data.Number());
    case lepus::ValueType::Value_Int64: {
      int64_t value = data.Int64();
      // In JavaScript,  the max safe integer is 9007199254740991 and the min
      // safe integer is -9007199254740991, so when integer beyond limit, use
      // BigInt Object to define it. More information from
      // https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number
      if (value < kMinJavaScriptNumber || value > kMaxJavaScriptNumber) {
        auto bigint = BigInt::createWithString(runtime, std::to_string(value));
        return bigint ? std::optional<Value>(Value(*bigint))
                      : std::optional<Value>();
      } else {
        return Value(data.Number());
      }
    }
    case lepus::ValueType::Value_UInt64: {
      if (data.UInt64() > kMaxJavaScriptNumber) {
        auto bigint =
            BigInt::createWithString(runtime, std::to_string(data.UInt64()));
        return bigint ? std::optional<Value>(Value(*bigint))
                      : std::optional<Value>();
      } else {
        return Value(data.Number());
      }
    }
    case lepus::ValueType::Value_String: {
      const std::string& origin = data.String().Get()->str();
      piper::String result = String::createFromUtf8(runtime, origin);
      return Value(result);
    }
    case lepus::ValueType::Value_Array: {
      lepus::CArray* array = data.Array().Get();
      auto ret = Array::createWithLength(runtime, array->size());
      if (!ret) {
        return std::optional<Value>();
      }
      for (size_t i = 0; i < array->size(); ++i) {
        auto element =
            valueFromLepus(runtime, array->get(i), jsi_object_wrapper_manager);
        if (!element) {
          return std::optional<Value>();
        }
        if (!((*ret).setValueAtIndex(runtime, i, std::move(*element)))) {
          return std::optional<Value>();
        }
      }
      piper::Value jsArray(std::move(*ret));
      return jsArray;
    }
    case lepus::Value_Bool:
      return Value(data.Bool());
    case lepus::Value_Table: {
      lepus::Dictionary* dict = data.Table().Get();
      Object ret(runtime);
      for (auto& iter : *dict) {
        auto element =
            valueFromLepus(runtime, iter.second, jsi_object_wrapper_manager);
        if (!element) {
          return std::optional<Value>();
        }
        if (!ret.setProperty(runtime, iter.first.impl()->c_str(),
                             std::move(*element))) {
          return std::optional<Value>();
        }
      }
      return Value(std::move(ret));
    }
    case lepus::Value_JSObject: {
      if (jsi_object_wrapper_manager) {
        piper::Value func =
            jsi_object_wrapper_manager->GetJSIObjectByIDOnJSThread(
                runtime, data.LEPUSObject()->JSIObjectID());
        return func;
      }

      return Value::null();
    }
    case lepus::ValueType::Value_ByteArray: {
      lynx::base::scoped_refptr<lepus::ByteArray> byte_array = data.ByteArray();
      size_t length = byte_array.Get()->GetLength();
      std::unique_ptr<const uint8_t[]> buffer = byte_array.Get()->MovePtr();
      return Value(piper::ArrayBuffer(runtime, std::move(buffer), length));
    }
    case lepus::ValueType::Value_Closure:
    case lepus::ValueType::Value_CFunction:
    case lepus::ValueType::Value_CPointer:
    case lepus::ValueType::Value_RefCounted:
    case lepus::ValueType::Value_NaN:
    case lepus::ValueType::Value_CDate:
    case lepus::ValueType::Value_RegExp:
    case lepus::ValueType::Value_PrimJsValue:
    case lepus::ValueType::Value_TypeCount:
      break;
  }
  return Value::null();
}

std::optional<Array> arrayFromLepus(Runtime& runtime,
                                    const lepus::CArray& array) {
  piper::Scope scope(runtime);
  auto ret = Array::createWithLength(runtime, array.size());
  if (!ret) {
    return std::optional<Array>();
  }
  for (size_t i = 0; i < array.size(); ++i) {
    auto element = valueFromLepus(runtime, array.get(i), nullptr);
    if (!element) {
      return std::optional<Array>();
    }
    if (!((*ret).setValueAtIndex(runtime, i, std::move(*element)))) {
      return std::optional<Array>();
    }
  }
  return ret;
}

// if 'jsi_object_wrapper_manager' is null, don't parse js function
std::optional<lepus_value> ParseJSValue(
    piper::Runtime& runtime, const piper::Value& value,
    JSIObjectWrapperManager* jsi_object_wrapper_manager,
    const std::string& jsi_object_group_id, const std::string& targetSDKVersion,
    std::vector<piper::Object>& pre_object_vector) {
  piper::Scope scope(runtime);
  if (value.isNull()) {
    return lepus::Value();
  } else if (value.isUndefined()) {
    lepus::Value result;
    result.SetUndefined();
    return result;
  } else if (value.isBool()) {
    return lepus::Value(value.getBool());
  } else if (value.isNumber()) {
    return lepus::Value(value.getNumber());
  } else if (value.isString()) {
    return lepus::Value(
        lepus::StringImpl::Create(value.getString(runtime).utf8(runtime)));
  } else {
    piper::Object obj = value.getObject(runtime);
    if (CheckIsCircularJSObjectIfNecessaryAndReportError(
            runtime, obj, pre_object_vector, "ParseJSValue!")) {
      return std::optional<lepus_value>();
    }
    // As Object is Movable, not copyable, do not push the Object you will use
    // later to vector! You need clone a new one.
    ScopedJSObjectPushPopHelper scoped_push_pop_helper(
        pre_object_vector, value.getObject(runtime));
    if (obj.isArray(runtime)) {
      piper::Array array = obj.getArray(runtime);
      auto size_opt = array.size(runtime);
      if (!size_opt) {
        return std::optional<lepus_value>();
      }
      auto lepus_array = lepus::CArray::Create();
      for (size_t i = 0; i < *size_opt; ++i) {
        auto item_opt = array.getValueAtIndex(runtime, i);
        if (!item_opt) {
          return std::optional<lepus_value>();
        }
        auto value_opt = ParseJSValue(
            runtime, *item_opt, jsi_object_wrapper_manager, jsi_object_group_id,
            targetSDKVersion, pre_object_vector);
        if (!value_opt) {
          return std::optional<lepus_value>();
        }
        lepus_array.Get()->push_back(std::move(*value_opt));
      }
      return lepus::Value(lepus_array);
    } else if (obj.isFunction(runtime)) {
      if (jsi_object_wrapper_manager) {
        return lepus_value(lepus::LEPUSObject::Create(
            jsi_object_wrapper_manager->CreateJSIObjectWrapperOnJSThread(
                runtime, std::move(obj), jsi_object_group_id)));
      } else {
        // do nothing
      }
    } else {
      // 判断是否为JS里的 BigInt 对象
      if (obj.hasProperty(runtime, BIG_INT_VAL)) {
        auto value_long_opt = obj.getProperty(runtime, BIG_INT_VAL);
        if (!value_long_opt) {
          return std::optional<lepus_value>();
        }
        if (value_long_opt->isString()) {
          // 取出 bigInt 的值并统一转换为 int64
          auto str = value_long_opt->toString(runtime);
          if (!str) {
            return std::optional<lepus_value>();
          }
          const std::string val_str = str->utf8(runtime);
          return lepus::Value(
              static_cast<int64_t>(std::strtoll(val_str.c_str(), nullptr, 0)));
        }
      }
      auto lepus_map = lepus::Dictionary::Create();
      auto names = obj.getPropertyNames(runtime);
      if (!names) {
        return std::optional<lepus_value>();
      }
      auto size = (*names).size(runtime);
      if (!size) {
        return std::optional<lepus_value>();
      }
      for (size_t i = 0; i < *size; ++i) {
        auto item = (*names).getValueAtIndex(runtime, i);
        if (!item) {
          return std::optional<lepus_value>();
        }
        piper::String name = item->getString(runtime);
        auto prop = obj.getProperty(runtime, name);
        if (!prop) {
          return std::optional<lepus_value>();
        }
        auto key = lepus::String(name.utf8(runtime).c_str());
        // lynx sdk < 2.3, ignore undefined, compatible with old lynx project
        if (prop->isUndefined() && !lynx::tasm::Config::IsHigherOrEqual(
                                       targetSDKVersion, LYNX_VERSION_2_3)) {
          continue;
        }
        auto value_opt = ParseJSValue(
            runtime, *prop, jsi_object_wrapper_manager, jsi_object_group_id,
            targetSDKVersion, pre_object_vector);
        if (!value_opt) {
          return std::optional<lepus_value>();
        }
        lepus_map.Get()->SetValue(key, std::move(*value_opt));
      }
      return lepus::Value(lepus_map);
    }
  }
  return lepus_value();
}

bool IsCircularJSObject(Runtime& runtime, const Object& object,
                        const std::vector<piper::Object>& pre_object_vector) {
  for (auto& pre_object : pre_object_vector) {
    if (piper::Object::strictEquals(runtime, pre_object, object)) {
      return true;
    }
  }
  return false;
}

bool CheckIsCircularJSObjectIfNecessaryAndReportError(
    Runtime& runtime, const Object& object,
    const std::vector<piper::Object>& pre_object_vector, const char* message) {
  if (runtime.IsEnableCircularDataCheck() &&
      IsCircularJSObject(runtime, object, pre_object_vector)) {
    runtime.reportJSIException(
        JSINativeException(std::string("Find circular JS data in ") + message));
    return true;
  }
  return false;
}

}  // namespace piper
}  // namespace lynx
