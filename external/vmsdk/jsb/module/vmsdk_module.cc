
#include "jsb/module/vmsdk_module.h"

#include "basic/vmsdk_exception_common.h"

namespace vmsdk {
namespace piper {
namespace VmsdkModuleUtils {
std::string JSTypeToString(const Napi::Value arg) {
  if (arg.IsUndefined()) {
    return "Undefinded";
  } else if (arg.IsNull()) {
    return "Null";
  } else if (arg.IsNumber()) {
    return "Number";
  } else if (arg.IsSymbol()) {
    return "Symbol";
  } else if (arg.IsString()) {
    return "String";
  } else if (arg.IsObject()) {
    return "Object";
  } else {
    return "Unknown";
  }
}

std::string ExpectedButGot(const std::string &expected,
                           const std::string &but_got) {
  return std::string{"expected: "}
      .append(expected)
      .append(", but got ")
      .append(but_got)
      .append(".");
}

std::string ExpectedButGotAtIndexError(const std::string &expected,
                                       const std::string &but_got,
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

}  // namespace VmsdkModuleUtils

// AllowList For Special Methods
// see issue: #1979
const std::unordered_set<std::string> &VmsdkModule::MethodAllowList() {
  static const std::unordered_set<std::string> method_allow_list = {"splice",
                                                                    "then"};
  return method_allow_list;
}

VmsdkModule::MethodMetadata::MethodMetadata(size_t count,
                                            const std::string &methodName,
                                            VmsdkModule *module)
    : argCount(count), name(methodName), module(module) {}

VmsdkModuleWrap::VmsdkModuleWrap(const Napi::CallbackInfo &info) {
  Napi::External value = info[0].As<Napi::External>();
  module_ = reinterpret_cast<VmsdkModule *>(value.Data());
}

Napi::Value VmsdkModuleWrap::CreateFromVmsdkModule(Napi::Env env,
                                                   VmsdkModule *module) {
  Napi::EscapableHandleScope scop(env);
  Napi::External v = Napi::External::New(env, module, nullptr, nullptr);
  Napi::Value modulePtr = Napi::Value::From(env, v);

  if (!module->constructor_.IsEmpty()) {
    Napi::Value cst = module->constructor_.Value();
    if (cst.IsFunction()) {
      return scop.Escape(cst.As<Napi::Function>().New({modulePtr}));
    }
  }

  // create Napi Class to descript the VmsdkModule
  using Wrapped = Napi::ObjectWrap<VmsdkModuleWrap>;
  std::vector<Wrapped::PropertyDescriptor> props;
  auto methodMap = module->methodMap_;
  for (auto it : methodMap) {
    Wrapped::PropertyDescriptor accessor = Wrapped::InstanceAccessor(
        Napi::String::New(env, it.first.c_str()), &VmsdkModuleWrap::Getter,
        nullptr, napi_default, it.second.get());
    props.push_back(accessor);
  }

  Napi::Function moduleConstructor =
      Wrapped::DefineClass(env, "VmsdkModuleWrap", props).Get(env);

  module->constructor_ = Napi::Persistent(moduleConstructor);
  return scop.Escape(moduleConstructor.New({modulePtr}));
}

Napi::Value VmsdkModuleWrap::Getter(const Napi::CallbackInfo &info) {
  Napi::Env env = info.Env();
  Napi::Function callback = Napi::Function::New(
      env,
      [](const Napi::CallbackInfo &info) -> Napi::Value {
        VmsdkModule::MethodMetadata *meta =
            reinterpret_cast<VmsdkModule::MethodMetadata *>(info.Data());
        return meta->module->invokeMethod(info);
      },
      "VmsdkMoudleCallBack", info.Data());
  return Napi::Value::From(env, callback);
}

void VmsdkModule::OnJSBridgeInvoked(const std::string &method_name,
                                    const std::string &param_str) {
  // delegate_->OnJSBridgeInvoked(name_, method_name, param_str);
}

}  // namespace piper
}  // namespace vmsdk
