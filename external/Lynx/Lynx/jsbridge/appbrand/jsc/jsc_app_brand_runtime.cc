// Copyright 2020 The Lynx Authors. All rights reserved.
// interface for lynx_v8.so for android

#include "jsbridge/appbrand/jsc/jsc_app_brand_runtime.h"

#include <utility>

namespace provider {
namespace jsc {

/// AppBrandRuntime
AppBrandRuntime::AppBrandRuntime(std::string group_name)
    : group_name_(std::move(group_name)) {}

std::shared_ptr<lynx::piper::VMInstance> AppBrandRuntime::createVM(
    const lynx::piper::StartupData*) const {
  auto ctx_group = std::make_shared<AppBrandContextGroupWrapper>(group_name_);
  ctx_group->InitContextGroup();
  return ctx_group;
}
std::shared_ptr<lynx::piper::JSIContext> AppBrandRuntime::createContext(
    std::shared_ptr<lynx::piper::VMInstance> vm) const {
  auto ctx = std::make_shared<AppBrandContextWrapper>(vm, group_name_);
  ctx->init();
  return ctx;
}

/// AppBrandContextGroupWrapper
AppBrandContextGroupWrapper::AppBrandContextGroupWrapper(std::string group_name)
    : lynx::piper::JSCContextGroupWrapper(),
      group_name_(std::move(group_name)) {}

/// AppBrandContextWrapper
AppBrandContextWrapper::AppBrandContextWrapper(
    std::shared_ptr<lynx::piper::VMInstance> vm, std::string group_name)
    : lynx::piper::JSCContextWrapper(vm), group_name_(std::move(group_name)) {}

AppBrandContextWrapper::~AppBrandContextWrapper() {
  ctx_ = nullptr;
  if (JSCProvider::Instance().UseNewApi()) {
    JSCProvider::Instance().GetCreator()->ReleaseContext(group_name_.c_str(),
                                                         this);
  } else {
    JSCProvider::creator()->ReleaseContext(group_name_.c_str(), this);
  }
}

void AppBrandContextWrapper::init() {
  if (JSCProvider::Instance().UseNewApi()) {
    ctx_ = JSCProvider::Instance().GetCreator()->GenerateContext(
        group_name_.c_str(), this);
  } else {
    ctx_ = JSCProvider::creator()->GenerateContext(group_name_.c_str(), this);
  }
}

const std::atomic<bool>& AppBrandContextWrapper::contextInvalid() const {
  return ctx_invalid_;
}

std::atomic<intptr_t>& AppBrandContextWrapper::objectCounter() const {
  return object_counter_;
}

JSGlobalContextRef AppBrandContextWrapper::getContext() const { return ctx_; }

/// JSCCreatorDelegate
void AppBrandContextWrapper::onSharedContextDestroyed() {
  ctx_invalid_ = true;
  ctx_ = nullptr;
}

}  // namespace jsc
}  // namespace provider
