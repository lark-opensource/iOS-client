// Copyright 2020 The Lynx Authors. All rights reserved.

#ifndef LYNX_JSBRIDGE_APPBRAND_JSC_JSC_PROVIDER_H_
#define LYNX_JSBRIDGE_APPBRAND_JSC_JSC_PROVIDER_H_

#include <list>
#include <memory>

#include "JavaScriptCore/JavaScript.h"

#ifndef PROVIDER_EXPORT
#define PROVIDER_EXPORT __attribute__((visibility("default")))
#endif

namespace provider {
namespace jsc {

class JSCCreatorObserver {
 public:
  virtual const char* context_name() const = 0;
  virtual void onSharedContextDestroyed() = 0;
};

class PROVIDER_EXPORT JSCCreator {
 public:
  virtual ~JSCCreator() = default;

  virtual JSGlobalContextRef GenerateContext(const char* name,
                                             JSCCreatorObserver* observer) = 0;
  virtual void ReleaseContext(const char* name,
                              JSCCreatorObserver* delegate) = 0;
  void OnSharedContextDestroyed(const char* name);

  void* CreateJSCRuntime(const char* name);

 protected:
  JSCCreator() = default;

  void AddObserver(JSCCreatorObserver* delegate);
  void RemoveObserver(JSCCreatorObserver* delegate);

  std::list<JSCCreatorObserver*> observers_;
};

class PROVIDER_EXPORT JSCProvider {
 public:
  JSCProvider() = default;
  static JSCProvider& Instance();

  //[[deprecated("Use Instance::SetCreator() instead.")]]
  static std::shared_ptr<JSCCreator> creator();
  //[[deprecated("Use Instance::GetCreator() instead.")]]
  static void set_creator(std::shared_ptr<JSCCreator> creator);

  bool UseNewApi();
  void SetUseNewApi(bool newapi);

  std::shared_ptr<JSCCreator>& GetCreator();
  void SetCreator(std::shared_ptr<JSCCreator> creator);

 protected:
  // Deprecated
  static std::shared_ptr<JSCCreator> creator_;
  bool use_new_api_ = false;
  JSCProvider(const JSCProvider&) = delete;
  JSCProvider& operator=(const JSCProvider&) = delete;
  std::shared_ptr<JSCCreator> creator_instance_;
};

}  // namespace jsc
}  // namespace provider

#undef PROVIDER_EXPORT
#endif  // LYNX_JSBRIDGE_APPBRAND_JSC_JSC_PROVIDER_H_
