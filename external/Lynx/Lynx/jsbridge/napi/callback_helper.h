// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_JSBRIDGE_NAPI_CALLBACK_HELPER_H_
#define LYNX_JSBRIDGE_NAPI_CALLBACK_HELPER_H_

#include <memory>
#include <unordered_map>
#include <utility>

#include "base/base_export.h"
#include "jsbridge/napi/shim/shim_napi.h"

namespace lynx {
namespace piper {

class CallbackHelper {
 public:
  CallbackHelper() = default;
  CallbackHelper(const CallbackHelper&) = delete;
  CallbackHelper& operator=(const CallbackHelper&) = delete;

  BASE_EXPORT static void ReportException(Napi::Object error);

  // Used by callback functions.
  BASE_EXPORT static void Invoke(const Napi::FunctionReference& cb,
                                 Napi::Value& result,
                                 std::function<void(Napi::Env)> handler,
                                 const std::initializer_list<napi_value>& args);

  BASE_EXPORT bool PrepareForCall(Napi::Function& callback_function);

  BASE_EXPORT bool PrepareForCall(Napi::Object& callback_interface,
                                  const char* property_name,
                                  bool single_operation = false);

  BASE_EXPORT Napi::Value Call(const std::initializer_list<napi_value>& args);
  BASE_EXPORT Napi::Value CallWithThis(
      napi_value recv, const std::initializer_list<napi_value>& args);

 private:
  Napi::FunctionReference function_;
};

class HolderStorage;

class InstanceGuard {
 public:
  InstanceGuard(HolderStorage* ptr) : ptr_(ptr) {}
  static std::shared_ptr<InstanceGuard> CreateSharedGuard(HolderStorage* ptr) {
    return std::make_shared<InstanceGuard>(ptr);
  }
  HolderStorage* Get() { return ptr_; }

 private:
  HolderStorage* ptr_;
};

class HolderStorage {
 public:
  HolderStorage() : instance_guard_(InstanceGuard::CreateSharedGuard(this)){};

  Napi::FunctionReference PopHolder(uintptr_t key) {
    auto ret = std::move(reference_holder_map_[key]);
    reference_holder_map_.erase(key);
    return ret;
  }

  const Napi::FunctionReference& PeekHolder(uintptr_t key) {
    return reference_holder_map_[key];
  }

  void PushHolder(uintptr_t key, Napi::FunctionReference holder) {
    reference_holder_map_[key] = std::move(holder);
  }

  std::weak_ptr<InstanceGuard> instance_guard() { return instance_guard_; }

 private:
  std::shared_ptr<InstanceGuard> instance_guard_;
  std::unordered_map<uintptr_t, Napi::FunctionReference> reference_holder_map_;
};

}  // namespace piper
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_NAPI_CALLBACK_HELPER_H_
