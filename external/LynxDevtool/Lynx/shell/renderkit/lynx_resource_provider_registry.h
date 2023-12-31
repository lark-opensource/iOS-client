// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef LYNX_SHELL_RENDERKIT_LYNX_RESOURCE_PROVIDER_REGISTRY_H_
#define LYNX_SHELL_RENDERKIT_LYNX_RESOURCE_PROVIDER_REGISTRY_H_

#include <map>
#include <memory>
#include <string>

#include "shell/renderkit/public/lynx_resource_provider.h"

namespace lynx {
class LynxProviderRegistry {
 public:
  LynxProviderRegistry() = default;
  ~LynxProviderRegistry();

  void AddLynxResourceProvider(const std::string& key,
                               lynx::LynxResourceProvider* provider);
  lynx::LynxResourceProvider* GetResourceProviderByKey(
      const std::string& key) const;

 private:
  std::map<std::string, lynx::LynxResourceProvider*> resource_providers_;
};

}  // namespace lynx
#endif  // LYNX_SHELL_RENDERKIT_LYNX_RESOURCE_PROVIDER_REGISTRY_H_
