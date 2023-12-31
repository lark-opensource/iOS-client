// Copyright 2020 The Lynx Authors. All rights reserved.

#include "jsbridge/appbrand/js_thread_provider.h"

#include "base/log/logging.h"

namespace provider {
namespace piper {

JSThreadProvider* JSThreadProviderGenerator::provider_ = nullptr;

JSThreadProvider& JSThreadProviderGenerator::Provider() {
  DCHECK(provider_ != nullptr);
  return *provider_;
}

void JSThreadProviderGenerator::SetProvider(JSThreadProvider* provider) {
  provider_ = provider;
}
}  // namespace piper
}  // namespace provider
