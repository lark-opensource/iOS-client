// Copyright 2020 The Lynx Authors. All rights reserved.

#include "jsbridge/appbrand/runtime_provider.h"

#include "base/log/logging.h"

namespace provider {
namespace piper {
RuntimeProvider* RuntimeProviderGenerator::provider_ = nullptr;

void RuntimeProviderGenerator::SetProvider(RuntimeProvider* provider) {
  DCHECK(provider != nullptr);
  provider_ = provider;
}

RuntimeProvider& RuntimeProviderGenerator::Provider() {
  DCHECK(provider_ != nullptr);
  return *provider_;
}
}  // namespace piper
}  // namespace provider
