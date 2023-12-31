// Copyright 2021 The Lynx Authors. All rights reserved.

#include "jsbridge/napi/napi_loader_js.h"

#include <utility>

#include "jsbridge/napi/shim/shim_napi.h"

namespace lynx {
namespace piper {

using Module = NapiEnvironment::Module;

NapiLoaderJS::NapiLoaderJS(const std::string& id) : id_(id) {}

static Napi::Value LoadLazyModule(const Napi::CallbackInfo& info) {
  if (info.Length() <= 1 || !info[0].IsString() || !info[1].IsObject()) {
    Napi::Error::New(
        info.Env(),
        "Invalid arguments, expecting: lynx.loadModule(<String>, <Object>)")
        .ThrowAsJavaScriptException();
    return Napi::Value();
  }

  Napi::String name = info[0].As<Napi::String>();
  Napi::Object target = info[1].As<Napi::Object>();
  auto* module =
      piper::NapiEnvironment::From(info.Env())->GetModule(name.Utf8Value());
  if (!module) {
    std::string msg("Module not registered: ");
    msg += name;
    LOGE("napi " << msg);
    return Napi::Value();
  }

  module->OnLoad(target);
  return Napi::Value();
}

static Napi::Value InstallNapiModules(const Napi::CallbackInfo& info) {
  // Install all instant modules on 'lynx' object.
  DCHECK(info.Length() > 0);
  Napi::Object lynx = info[0].As<Napi::Object>();
  NapiEnvironment::From(info.Env())->delegate()->LoadInstantModules(lynx);

  // Install lazy module hook.
  lynx["loadModule"] =
      Napi::Function::New(info.Env(), &LoadLazyModule, "loadModule");

  return Napi::Value();
}

void NapiLoaderJS::OnAttach(Napi::Env env) {
  napi_env raw_env = env;
  if (raw_env && raw_env->ctx) {
    LOGI("napi OnAttach env: " << raw_env << ", ctx: " << raw_env->ctx
                               << ", id: " << id_);
    Napi::HandleScope scope(env);
    std::string hook_name("installNapiModulesOnRT");
    hook_name += id_;
    env.Global()[hook_name.c_str()] =
        Napi::Function::New(env, &InstallNapiModules, hook_name.c_str());
  }
}

void NapiLoaderJS::OnDetach(Napi::Env env) {
  napi_env raw_env = env;
  if (raw_env && raw_env->ctx) {
    LOGI("napi OnDetach env: " << raw_env << ", ctx: " << raw_env->ctx
                               << ", id: " << id_);
  }
}

void NapiLoaderJS::RegisterModule(const std::string& name,
                                  std::unique_ptr<Module> module) {
  modules_[name] = std::move(module);
}

Module* NapiLoaderJS::GetModule(const std::string& name) {
  auto it = modules_.find(name);
  if (it != modules_.end()) {
    return it->second.get();
  }
  return nullptr;
}

void NapiLoaderJS::LoadInstantModules(Napi::Object& lynx) {
  if (loaded_) return;
  loaded_ = true;
  for (auto& m : modules_) {
    if (m.second->IsLazy()) {
      continue;
    }
    m.second->OnLoad(lynx);
  }
}

}  // namespace piper
}  // namespace lynx
