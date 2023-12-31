// Copyright 2022 The Lynx Authors. All rights reserved.

#include "jsbridge/module/lynx_module.h"

#include <utility>

#include "base/debug/lynx_assert.h"
#include "base/no_destructor.h"

namespace lynx {
namespace piper {
namespace LynxModuleUtils {
std::string JSTypeToString(const piper::Value* arg) {
  if (!arg) {
    return "nullptr";
  }
  return arg->typeToString();
}

std::string ExpectedButGot(const std::string& expected,
                           const std::string& but_got) {
  return std::string{"expected: "}
      .append(expected)
      .append(", but got ")
      .append(but_got)
      .append(".");
}

std::string ExpectedButGotAtIndexError(const std::string& expected,
                                       const std::string& but_got,
                                       int arg_index) {
  auto message = std::string{" argument: "};
  message += std::to_string(arg_index);
  message += ", expected: ";
  message += expected;
  message += ", but got ";
  message += but_got;
  message += ".";
  return message;
}

std::string ExpectedButGotError(int expected, int but_got) {
  return " invoked with wrong number of arguments," +
         ExpectedButGot(std::to_string(expected), std::to_string(but_got));
}

}  // namespace LynxModuleUtils

// AllowList For Special Methods
// see issue: #1979
const std::unordered_set<std::string>& LynxModule::MethodAllowList() {
  static const base::NoDestructor<std::unordered_set<std::string>>
      method_allow_list({"splice", "then"});
  return *method_allow_list;
}

LynxModule::MethodMetadata::MethodMetadata(size_t count,
                                           const std::string& methodName)
    : argCount(count), name(methodName) {}

piper::Value LynxModule::get(Runtime* runtime, const PropNameID& prop) {
  std::string propNameUtf8 = prop.utf8(*runtime);
  auto p = methodMap_.find(propNameUtf8);

  if (p != methodMap_.end()) {
    auto& meta = p->second;
    return piper::Function::createFromHostFunction(
        *runtime, prop, static_cast<unsigned int>(meta->argCount),
        [this, meta, propNameUtf8](
            Runtime& rt, const Value& thisVal, const Value* args,
            size_t count) -> std::optional<piper::Value> {
          if (meta.get() == nullptr) {
            LOGE("LynxModule, module: "
                 << name_ << " failed in invokeMethod(), method is a nullptr");
            return piper::Value::undefined();
          }
          if (interceptor_) {
            auto pair = interceptor_->InterceptModuleMethod(
                this, meta.get(), &rt, delegate_, args, count);
            if (pair.handled) {
              return std::move(pair.result);
            }
          }
          return this->invokeMethod(*(meta.get()), &rt, args, count);
        });
  } else {
    // AllowList For Special Methods
    // see issue: #1979
    if (!MethodAllowList().count(propNameUtf8)) {
      LOGI("module: " << name_ << ", method: " << propNameUtf8
                      << " cannot be found in the method map");
      delegate_->OnMethodInvoked(name_, propNameUtf8,
                                 LYNX_ERROR_CODE_MODULE_FUNC_NOT_EXIST);
    }
    return piper::Value::undefined();
  }

  // TODO: All these code related to LynxAttribute are dead code, can be
  // removed.
  return this->getAttributeValue(runtime, propNameUtf8);
}
}  // namespace piper
}  // namespace lynx
