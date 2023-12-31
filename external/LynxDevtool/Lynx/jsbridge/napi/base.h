// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_JSBRIDGE_NAPI_BASE_H_
#define LYNX_JSBRIDGE_NAPI_BASE_H_

#include "base/log/logging.h"
#include "jsbridge/napi/shim/shim_napi.h"

namespace lynx {
namespace piper {

class ImplBase;

class BridgeBase : public Napi::ScriptWrappable {
 public:
  Napi::Object JsObject() { return weak_ref_.Value(); }
  Napi::Env Env() { return env_; }

  typedef Napi::Value (BridgeBase::*InstanceCallbackPtr)(
      const Napi::CallbackInfo& info);
  typedef Napi::Value (BridgeBase::*GetterCallbackPtr)(
      const Napi::CallbackInfo& info);
  typedef void (BridgeBase::*SetterCallbackPtr)(const Napi::CallbackInfo& info,
                                                const Napi::Value& value);
  typedef Napi::Value (*StaticMethodCallback)(const Napi::CallbackInfo& info);
  typedef void (*StaticSetterCallback)(const Napi::CallbackInfo& info,
                                       const Napi::Value& value);

 protected:
  BridgeBase(const Napi::CallbackInfo& info) : env_(info.Env()) {
    DCHECK(!info.This().IsUndefined());
    DCHECK(info.This().IsObject());
    weak_ref_.Reset(info.This().ToObject());
  }
  virtual ~BridgeBase() = default;

 private:
  Napi::ObjectReference weak_ref_;
  Napi::Env env_;
};

class ImplBase {
 public:
  Napi::Object JsObject() {
    DCHECK(IsWrapped());
    return bridge_->JsObject();
  }
  Napi::Env Env() {
    DCHECK(IsWrapped());
    return bridge_->Env();
  }
  Napi::ObjectReference ObtainStrongRef() { return Persistent(JsObject()); }
  bool IsWrapped() { return !!bridge_; }

  void AssociateWithWrapper(BridgeBase* bridge) {
    DCHECK(bridge);
    DCHECK(!bridge_);
    bridge_ = bridge;
    OnWrapped();
  }
  virtual void OnWrapped() {}

 protected:
  ImplBase() {}
  virtual ~ImplBase() = default;

 private:
  BridgeBase* bridge_ = nullptr;
};

}  // namespace piper
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_NAPI_BASE_H_
