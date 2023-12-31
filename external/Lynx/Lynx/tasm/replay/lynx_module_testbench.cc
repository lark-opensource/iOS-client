// Copyright 2021 The Lynx Authors. All rights reserved.

#include "tasm/replay/lynx_module_testbench.h"

#include <limits>
#include <utility>
#include <vector>

#include "jsbridge/jsi/jsi.h"
#include "tasm/replay/lynx_callback_testbench.h"

namespace lynx {
namespace piper {

std::string ModuleTestBench::kUndefined = "undefined";
std::string ModuleTestBench::kHeader = "header";
std::string ModuleTestBench::kTimeStamp = "timestamp";
std::string ModuleTestBench::kCardVersion = "card_version";
std::string ModuleTestBench::kContainerID = "containerID";
std::string ModuleTestBench::kRequestTime = "request_time";
std::string ModuleTestBench::kFunction = "function";
std::string ModuleTestBench::kNaN = "NaN";

void ModuleTestBench::Destroy() {}

bool ModuleTestBench::IsStrictMode() {
  if (jsb_settings_ == nullptr) {
    return true;
  }

  if (jsb_settings_->IsObject() && jsb_settings_->HasMember("strict")) {
    bool strict = ((*(jsb_settings_))["strict"]).GetBool();
    return strict;
  } else {
    return true;
  }
}

void ModuleTestBench::InvokeJsbCallback(piper::Function callback_function,
                                        piper::Value value, int64_t delay) {
  int64_t callback_id =
      delegate_->RegisterJSCallbackFunction(std::move(callback_function));
  std::shared_ptr<ModuleDelegate> delegate(delegate_);
  auto wrapper = std::make_shared<ModuleCallbackTestBench>(callback_id);
  wrapper->argument = std::move(value);
  if (delay < 0) {
    testbench_thread_.GetTaskRunner()->PostTask(
        [deg = delegate, wap = wrapper]() { deg->CallJSCallback(wap); });
  } else {
    testbench_thread_.GetTaskRunner()->PostDelayedTask(
        [deg = delegate, wap = wrapper]() { deg->CallJSCallback(wap); },
        fml::TimeDelta::FromMilliseconds(static_cast<int64_t>(delay)));
  }
}

void ModuleTestBench::ActionsForJsbMatchFailed(Runtime *rt,
                                               const piper::Value *args,
                                               size_t count) {
  if (!IsStrictMode()) {
    for (size_t index = 0; index < count; index++) {
      if ((args + index)->kind() == ValueKind::ObjectKind &&
          (args + index)->getObject(*rt).isFunction(*rt)) {
        piper::Function callback_function =
            (args + index)->getObject(*rt).getFunction(*rt);
        InvokeJsbCallback(std::move(callback_function), piper::Value::null());
      }
    }
  }
  if (args->isString()) {
    LOGI("Testbench Jsb match failed, more information: "
         << args->getString(*rt).utf8(*rt));
  } else {
    LOGI("Testbench Jsb match failed");
  }
}

bool ModuleTestBench::IsJsbIgnoredParams(const std::string &param) {
  // These values must be ignored during jsb match, because Uncertainty.
  if (param == kTimeStamp || param == kCardVersion || param == kContainerID ||
      param == kHeader || param == kRequestTime) {
    return true;
  }

  if (jsb_ignored_info_ != nullptr) {
    if (jsb_ignored_info_->IsArray()) {
      for (unsigned int index = 0; index < jsb_ignored_info_->Size(); index++) {
        std::string value = (*jsb_ignored_info_)[index].GetString();
        if (value == param) {
          return true;
        }
      }
    }
  }
  return false;
}

// http:{host}?{params_list}
// The same url means the exact same host and similar params_list
// params_list: key_1=value_1&key_2=value_2...
// if key is not JsbIgnoredParams, the key must be exact same.
// if not, the key will be similar param.
bool ModuleTestBench::IsSameURL(const std::string &first,
                                const std::string &second) {
  if (first.rfind("http") == 0 && second.rfind("http") == 0) {
    // split url to host address and params_list
    // index 0 is host address
    // index 1 is params_list
    std::vector<std::string> url_first, url_second;
    base::SplitString(first, '?', url_first);
    base::SplitString(second, '?', url_second);
    if ((url_first.size() != url_second.size()) ||
        (url_first[0] != url_second[0])) {
      return false;
    }

    if (url_first.size() > 1 && url_second.size() > 1) {
      // split params_list to independent params.
      std::vector<std::string> url_params_first, url_params_second;
      base::SplitString(url_first[1], '&', url_params_first);
      base::SplitString(url_second[1], '&', url_params_second);
      if (url_params_first.size() != url_params_second.size()) {
        return false;
      }

      for (unsigned long i = 0; i < url_params_second.size(); i++) {
        // In fact, we just need analysis not-equal param in depth.
        if (url_params_second[i] != url_params_first[i]) {
          // Split param to key and value
          std::vector<std::string> params_first_vector, params_second_vector;
          base::SplitString(url_params_first[i], '=', params_first_vector);
          base::SplitString(url_params_second[i], '=', params_second_vector);
          std::string params_name_first = params_first_vector[0];
          std::string params_name_second = params_second_vector[0];
          // Similar: key1 is equal to key2 and value is ignored information.
          if ((params_name_first == params_name_second) &&
              IsJsbIgnoredParams(params_name_first)) {
            continue;
          } else {
            return false;
          }
        }
      }
    }
    return true;
  }
  // isn't http url
  return false;
}

bool ModuleTestBench::sameKernel(Runtime *rt, const piper::Value *arg,
                                 rapidjson::Value &value) {
  switch (arg->kind()) {
    case ValueKind::StringKind: {
      if (value.IsString()) {
        std::string cc = value.GetString();
        std::string js = arg->getString(*rt).utf8(*rt);
        if (cc == js) {
          return true;
        }
        if (IsSameURL(cc, js)) {
          return true;
        }
      }
      return false;
    }
    case ValueKind::ObjectKind: {
      if (value.IsObject()) {
        auto properties_opt = arg->getObject(*rt).getPropertyNames(*rt);
        if (!properties_opt) {
          return false;
        }
        for (int index = 0; index < properties_opt->size(*rt); index++) {
          auto name_opt = properties_opt->getValueAtIndex(*rt, index);
          if (!name_opt || !name_opt->isString()) {
            return false;
          }
          std::string name = name_opt->getString(*rt).utf8(*rt);
          if (IsJsbIgnoredParams(name) && value.HasMember(name.c_str())) {
            continue;
          }
          if (!value.HasMember(name.c_str())) {
            return false;
          }

          auto arg_ = arg->getObject(*rt).getProperty(*rt, name.c_str());
          if (!arg_) {
            return false;
          }
          if (!sameKernel(rt, &(*arg_), value[name.c_str()])) {
            return false;
          }
        }
        return true;
      }
      if (value.IsArray() && arg->getObject(*rt).isArray(*rt)) {
        piper::Array arr = arg->getObject(*rt).getArray(*rt);
        if (value.Size() != arr.size(*rt)) {
          return false;
        }
        for (int index = 0; index < arr.size(*rt); index++) {
          auto arg_opt = arr.getValueAtIndex(*rt, index);
          if (!arg_opt || !sameKernel(rt, &(*arg_opt), value[index])) {
            return false;
          }
        }
        return true;
      }
      if (arg->getObject(*rt).isFunction(*rt)) {
        if (value.IsString()) {
          if (value.GetString() == kFunction) {
            callbackFunctions.push_back(arg->getObject(*rt).getFunction(*rt));
            return true;
          }
        }
      }
      return false;
    }
    case ValueKind::UndefinedKind: {
      if (value.IsString()) {
        if (value.GetString() == kUndefined) {
          return true;
        }
      }
      return false;
    }
    case ValueKind::NumberKind: {
      double js = arg->getNumber();
      if (value.IsDouble()) {
        if (abs(value.GetDouble() - js) < 0.0000001) {
          return true;
        }
      }

      if (value.IsInt()) {
        if (value.GetInt() == static_cast<int>(js)) {
          return true;
        }
      }

      if (value.IsString()) {
        if (value.GetString() == kNaN && std::isnan(js)) {
          return true;
        }
      }
      return false;
    }
    case ValueKind::NullKind: {
      if (value.IsNull()) {
        return true;
      }
      return false;
    }
    case ValueKind::BooleanKind: {
      if (value.IsBool()) {
        if (value.GetBool() == arg->getBool()) {
          return true;
        }
      }
      return false;
    }
    case ValueKind::SymbolKind: {
      return false;
    }
  }
}

bool ModuleTestBench::isSameArgs(Runtime *rt, const piper::Value *args,
                                 size_t count, rapidjson::Value &value) {
  for (unsigned int index = 0; index < count; index++) {
    if (!sameKernel(rt, (args + index), value[index])) {
      return false;
    }
  }
  return true;
}

bool ModuleTestBench::isSameMethod(const MethodMetadata &method, Runtime *rt,
                                   const piper::Value *args, size_t count,
                                   rapidjson::Value &value) {
  std::string cMethodName = value["Method Name"].GetString();
  std::string jMethodName = method.name;
  if (cMethodName != jMethodName) {
    return false;
  }

  size_t cArgc = value["Params"]["argc"].GetInt();
  size_t jArgc = method.argCount;
  if (cArgc != jArgc) {
    return false;
  }

  if (!isSameArgs(rt, args, count, value["Params"]["args"])) {
    return false;
  }

  return true;
}

piper::Value ModuleTestBench::getAttributeValue(Runtime *rt,
                                                std::string propName) {
  return Value();
}

void ModuleTestBench::buildLookupMap() {
  for (unsigned int index = 0; index < this->moduleData.Size(); index++) {
    std::string methodName = this->moduleData[index]["Method Name"].GetString();
    int count = this->moduleData[index]["Params"]["argc"].GetInt();
    auto moduleMetaData = std::make_shared<MethodMetadata>(count, methodName);
    methodMap_[methodName] = moduleMetaData;
  }
}

piper::Value ModuleTestBench::convertRapidJsonStringToJSIValue(
    Runtime &runtime, rapidjson::Value &value) {
  if (value.GetString() == kNaN) {
    return piper::Value(std::numeric_limits<double>::quiet_NaN());
  }
  return piper::String::createFromUtf8(runtime, value.GetString());
}

piper::Value ModuleTestBench::convertRapidJsonNumberToJSIValue(
    Runtime &runtime, rapidjson::Value &value) {
  double v = 0;
  if (value.IsInt()) {
    v = value.GetInt();
  } else if (value.IsFloat()) {
    v = value.GetDouble();
  } else if (value.IsDouble()) {
    v = value.GetDouble();
  } else if (value.IsInt64()) {
    v = value.GetInt64();
  } else if (value.IsUint()) {
    v = value.GetUint64();
  } else if (value.IsUint64()) {
    v = value.GetUint64();
  }
  return piper::Value(v);
}

piper::Value ModuleTestBench::convertRapidJsonObjectToJSIValue(
    Runtime &runtime, rapidjson::Value &value) {
  switch (value.GetType()) {
    case rapidjson::kStringType:
      return convertRapidJsonStringToJSIValue(runtime, value);
    case rapidjson::kNumberType:
      return convertRapidJsonNumberToJSIValue(runtime, value);
    case rapidjson::kNullType:
      return piper::Value::null();
    case rapidjson::kFalseType:
      return piper::Value(false);
    case rapidjson::kTrueType:
      return piper::Value(true);
    case rapidjson::kArrayType: {
      int length = value.Size();
      auto array_opt =
          piper::Array::createWithLength(runtime, static_cast<size_t>(length));
      if (!array_opt) {
        return piper::Value();
      }
      for (int index = 0; index < length; index++) {
        array_opt->setValueAtIndex(
            runtime, index,
            convertRapidJsonObjectToJSIValue(runtime, value[index]));
      }
      return piper::Value(*array_opt);
    }
    case rapidjson::kObjectType: {
      piper::Object v(runtime);
      for (auto p = value.GetObject().begin(); p != value.GetObject().end();
           p++) {
        v.setProperty(runtime, (*p).name.GetString(),
                      convertRapidJsonObjectToJSIValue(runtime, (*p).value));
      }
      return v;
    }
    default:
      return piper::Value::undefined();
  }
}

std::optional<piper::Value> ModuleTestBench::invokeMethod(
    const MethodMetadata &method, Runtime *rt, const piper::Value *args,
    size_t count) {
  if (this->moduleData.IsArray()) {
    for (unsigned int index = 0; index < moduleData.Size(); index++) {
      if (isSameMethod(method, rt, args, count, moduleData[index])) {
        rapidjson::Value &callbackValue = moduleData[index]["Callback"];
        if ((callbackValue.Size()) != 0 &&
            (callbackFunctions.size() == callbackValue.Size())) {
          unsigned int callbackIndex = 0;
          for (auto &callbackFunction : callbackFunctions) {
            piper::Value return_value = convertRapidJsonObjectToJSIValue(
                *rt, callbackValue[callbackIndex]["Value"]["returnValue"]);
            rapidjson::Value &delay_time =
                callbackValue[callbackIndex++]["Delay"];
            if (delay_time.GetType() == rapidjson::kNumberType) {
              int delay = delay_time.GetInt();
              delay = (delay < 0) ? 0 : delay;
              LOGI("Testbench Jsb match successful, callback id : "
                   << moduleData[index]["Label"].GetString());
              InvokeJsbCallback(std::move(callbackFunction),
                                std::move(return_value), delay);
            }
          }
        }
        callbackFunctions.clear();
        rapidjson::Value &reValue = moduleData[index]["Params"]["returnValue"];
        if (reValue.IsString() &&
            strcmp(reValue.GetString(), "undefined") == 0) {
          return piper::Value::undefined();
        }
        return convertRapidJsonObjectToJSIValue(*rt, reValue);
      }
    }
  }
  ActionsForJsbMatchFailed(rt, args, count);
  return piper::Value::undefined();
}

void ModuleTestBench::initModuleData(
    const rapidjson::Value &value, rapidjson::Value *value_ptr,
    rapidjson::Value *jsb_settings_ptr,
    rapidjson::Document::AllocatorType &allocator) {
  this->moduleData = rapidjson::Value(value, allocator);
  this->jsb_ignored_info_ = value_ptr;
  this->jsb_settings_ = jsb_settings_ptr;
  buildLookupMap();
}
}  // namespace piper
}  // namespace lynx
