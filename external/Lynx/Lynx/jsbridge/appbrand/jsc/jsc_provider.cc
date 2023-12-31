// Copyright 2020 The Lynx Authors. All rights reserved.

#include "jsbridge/appbrand/jsc/jsc_provider.h"

#include <string>
#include <unordered_map>
#include <utility>

#include "base/no_destructor.h"
#include "jsbridge/appbrand/jsc/jsc_app_brand_runtime.h"

namespace provider {
namespace jsc {

std::shared_ptr<JSCCreator> JSCProvider::creator_;

class JSCCreatorLynx : public JSCCreator {
 public:
  JSCCreatorLynx() = default;
  virtual ~JSCCreatorLynx() = default;

  JSGlobalContextRef GenerateContext(const char* name,
                                     JSCCreatorObserver* observer) override;
  void ReleaseContext(const char* name, JSCCreatorObserver* observer) override;

 private:
  std::unordered_map<std::string, JSGlobalContextRef> contexts_;
};

void JSCCreator::AddObserver(JSCCreatorObserver* observer) {
  if (!observer) {
    return;
  }
  observers_.push_back(observer);
}

void* JSCCreator::CreateJSCRuntime(const char* name) {
  return new provider::jsc::AppBrandRuntime(name);
}

void JSCCreator::RemoveObserver(JSCCreatorObserver* observer) {
  if (!observer) {
    return;
  }
  auto it = std::find(observers_.begin(), observers_.end(), observer);
  if (it != observers_.end()) {
    observers_.erase(it);
  }
}

void JSCCreator::OnSharedContextDestroyed(const char* name) {
  for (auto* it : observers_) {
    if (strcmp(name, it->context_name()) == 0) {
      it->onSharedContextDestroyed();
    }
  }
}

bool JSCProvider::UseNewApi() { return use_new_api_; }

void JSCProvider::SetUseNewApi(bool newapi) { use_new_api_ = newapi; }

std::shared_ptr<JSCCreator> JSCProvider::creator() {
  if (!creator_) {
    creator_ = std::make_shared<JSCCreatorLynx>();
  }
  return creator_;
}

void JSCProvider::set_creator(std::shared_ptr<JSCCreator> creator) {
  creator_ = creator;
}

JSCProvider& JSCProvider::Instance() {
  static lynx::base::NoDestructor<JSCProvider> provider_instance;
  return *provider_instance;
}

std::shared_ptr<JSCCreator>& JSCProvider::GetCreator() {
  if (!creator_instance_) {
    creator_instance_ = std::make_shared<JSCCreatorLynx>();
  }
  return creator_instance_;
}

void JSCProvider::SetCreator(std::shared_ptr<JSCCreator> creator) {
  creator_instance_ = creator;
}

JSGlobalContextRef JSCCreatorLynx::GenerateContext(
    const char* name, JSCCreatorObserver* observer) {
  AddObserver(observer);

  auto context = JSGlobalContextCreate(nullptr);
  auto js_name = JSStringCreateWithUTF8CString(name);
  JSGlobalContextSetName(context, js_name);
  JSStringRelease(js_name);

  contexts_.insert(std::make_pair(name, context));

  return context;
}

void JSCCreatorLynx::ReleaseContext(const char* name,
                                    JSCCreatorObserver* observer) {
  RemoveObserver(observer);
  auto it = contexts_.find(name);
  if (it != contexts_.end()) {
    JSGlobalContextRelease(it->second);
    contexts_.erase(it);
  }
}

}  // namespace jsc
}  // namespace provider
