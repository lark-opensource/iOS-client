// Copyright 2021 The vmsdk Authors. All rights reserved.

#ifndef DEVTOOL_ANDROID_INSPECTOR_BRIDGE_IOS_H
#define DEVTOOL_ANDROID_INSPECTOR_BRIDGE_IOS_H

// Please don't import Foundation in this file, because inspector_impl.cc
// include this file.

#include <string>

#include "VMSDKDebugICBase.h"  // for use vmsdk::devtool::VMSDKDebugICBase

namespace vmsdk {
namespace devtool {

class InspectorImpl;

namespace iOS {

class InspectorBridgeiOS {
 public:
  InspectorBridgeiOS(std::shared_ptr<VMSDKDebugICBase> inspector_client,
                     std::shared_ptr<InspectorImpl> devtool);
  ~InspectorBridgeiOS();

  void DispatchMessage(const std::string &message);
  void SendResponseMessage(const std::string &message);

  std::weak_ptr<InspectorImpl> inspector_impl_;
  std::shared_ptr<VMSDKDebugICBase> inspector_client_;
};

}  // namespace iOS
}  // namespace devtool
}  // namespace vmsdk
#endif  // DEVTOOL_ANDROID_INSPECTOR_BRIDGE_IOS_H
