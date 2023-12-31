// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_SHELL_RENDERKIT_CORE_JS_LOADER_MANAGER_H_
#define LYNX_SHELL_RENDERKIT_CORE_JS_LOADER_MANAGER_H_

#include <memory>

namespace lynx {
class ICoreJsLoader {
 public:
  virtual ~ICoreJsLoader();

  virtual const char* GetCoreJs() = 0;
  virtual bool JsCoreUpdated() = 0;
  virtual void CheckUpdate() = 0;
};

class CoreJsLoaderManager {
 public:
  static CoreJsLoaderManager* GetInstance();

  ICoreJsLoader* GetLoader();
  void SetLoader(std::unique_ptr<ICoreJsLoader> loader);

  CoreJsLoaderManager() = default;

  CoreJsLoaderManager(const CoreJsLoaderManager&) = delete;
  CoreJsLoaderManager& operator=(const CoreJsLoaderManager&) = delete;
  CoreJsLoaderManager(CoreJsLoaderManager&&) = delete;
  CoreJsLoaderManager& operator=(CoreJsLoaderManager&&) = delete;

 private:
  std::unique_ptr<ICoreJsLoader> loader_;
};
}  // namespace lynx

#endif  // LYNX_SHELL_RENDERKIT_CORE_JS_LOADER_MANAGER_H_
