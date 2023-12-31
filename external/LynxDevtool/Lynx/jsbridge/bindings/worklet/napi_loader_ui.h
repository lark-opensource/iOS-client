// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_JSBRIDGE_BINDINGS_WORKLET_NAPI_LOADER_UI_H_
#define LYNX_JSBRIDGE_BINDINGS_WORKLET_NAPI_LOADER_UI_H_

#include <unordered_map>

#include "jsbridge/napi/napi_environment.h"
#include "jsbridge/napi/shim/shim_napi.h"
#include "lepus/quick_context.h"

namespace lynx {
namespace worklet {

class LepusLynx;

class NapiLoaderUI : public piper::NapiEnvironment::Delegate {
 public:
  NapiLoaderUI(lepus::QuickContext* context);

  void OnAttach(Napi::Env env) override;
  void OnDetach(Napi::Env env) override;
  lynx::worklet::LepusLynx* lepus_lynx() { return lynx_; }
  void InvokeLepusBridge(const int32_t callback_id, const lepus::Value& data);

  static lepus::QuickContext* GetQuickContextFromNapiEnv(Napi::Env env);

 private:
  static std::unordered_map<napi_env, lepus::QuickContext*>&
  NapiEnvToContextMap();
  void SetNapiEnvToLEPUSContext(Napi::Env env);

  lynx::worklet::LepusLynx* lynx_ = nullptr;
  lepus::QuickContext* context_ = nullptr;
};

}  // namespace worklet
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_BINDINGS_WORKLET_NAPI_LOADER_UI_H_
