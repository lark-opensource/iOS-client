// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_JSBRIDGE_RENDERKIT_MODULE_MANAGER_RENDERKIT_H_
#define LYNX_JSBRIDGE_RENDERKIT_MODULE_MANAGER_RENDERKIT_H_

#include <memory>
#include <string>
#include <type_traits>
#include <unordered_map>
#include <utility>

#include "jsbridge/module/lynx_module_manager.h"
#include "jsbridge/renderkit/lynx_module_renderkit.h"
#include "third_party/renderkit/include/rk_modules.h"

namespace lynx {
namespace piper {

class ModuleManagerRenderkitImpl {
 public:
  explicit ModuleManagerRenderkitImpl(void* renderkit_impl);
  ~ModuleManagerRenderkitImpl();

  std::shared_ptr<LynxModuleRenderkit> GetModule(
      const std::string& name, const std::shared_ptr<ModuleDelegate>& delegate);

  void Destroy();

 private:
  RKLynxModuleManagerRef rk_manager_ = nullptr;
  std::unordered_map<std::string, std::shared_ptr<LynxModuleRenderkit>>
      modules_;
};

template <class T>
class ModuleManagerRenderkit : public T {
 public:
  template <typename... Args>
  ModuleManagerRenderkit(void* renderkit_impl, Args&&... args)
      : T(std::forward<Args>(args)...),
        impl_(renderkit_impl ? new ModuleManagerRenderkitImpl(renderkit_impl)
                             : nullptr) {
    static_assert(std::is_base_of<LynxModuleManager, T>::value,
                  "T has to been subclass of LynxModuleManager.");
  }

  ~ModuleManagerRenderkit() override = default;

  void Destroy() override {
    T::Destroy();
    impl_->Destroy();
  }

  void SetRenderkitImpl(void* renderkit_impl) {
    if (renderkit_impl)
      impl_.reset(new ModuleManagerRenderkitImpl(renderkit_impl));
  }

  void initBindingPtr(std::weak_ptr<ModuleManagerRenderkit> weak_manager,
                      const std::shared_ptr<ModuleDelegate>& delegate) {
    auto* ptr = static_cast<LynxModuleManager*>(this);
    LynxModuleProviderFunction fallback =
        T::BindingFunc(weak_manager, delegate);
    ptr->bindingPtr = std::make_shared<lynx::piper::LynxModuleBinding>(
        [weak_manager, delegate,
         fallback](const std::string& name) -> std::shared_ptr<LynxModule> {
          auto manager = weak_manager.lock();
          if (manager) {
            std::shared_ptr<LynxModuleRenderkit> lynx_module =
                manager->impl_->GetModule(name, delegate);
            if (lynx_module) {
              return lynx_module;
            }
          }
          return fallback(name);
        });
  }

 private:
  std::unique_ptr<ModuleManagerRenderkitImpl> impl_;
};

}  // namespace piper
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_RENDERKIT_MODULE_MANAGER_RENDERKIT_H_
