// Copyright 2021 The vmsdk Authors. All rights reserved.

#include "jsb/devtool/inspector_factory.h"

namespace vmsdk {
namespace devtool {

// static
void InspectorFactory::SetInstance(InspectorFactory *instance) {
  GetOrSetInstance(instance);
}

// static
InspectorFactory *InspectorFactory::GetInstance() { return GetOrSetInstance(); }

// static
InspectorFactory *InspectorFactory::GetOrSetInstance(
    InspectorFactory *instance) {
  static InspectorFactory *sInstance = nullptr;
  if (instance) {
    sInstance = instance;
  }
  return sInstance;
}

}  // namespace devtool
}  // namespace vmsdk
