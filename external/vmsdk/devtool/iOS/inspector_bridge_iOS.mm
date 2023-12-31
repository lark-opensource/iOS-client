// Copyright 2021 The vmsdk Authors. All rights reserved.

#include "devtool/iOS/inspector_bridge_iOS.h"
#import <Foundation/Foundation.h>
#include <string>
#import "devtool/iOS/inspector_protocol.h"

#include "ObjcVMSDKDebugIC.h"  // for use vmsdk::devtool::ObjcVMSDKDebugIC & VMSDKDebugICBase
#include "basic/log/logging.h"
#include "devtool/inspector_impl.h"

@interface InspectorBridgeiOSInternal : NSObject <VMSDKDebugInspector> {
 @public
  std::shared_ptr<vmsdk::devtool::iOS::InspectorBridgeiOS> bridge_;
}

@end

@implementation InspectorBridgeiOSInternal

- (void)dispatchMessage:(NSString *)message {
  if (bridge_) {
    bridge_->DispatchMessage([message UTF8String]);
  }
}

@end

namespace vmsdk {
namespace devtool {

/**
 * create InspectorBridgeiOS for InspectorImpl, called by InspectorImpl(C++)
 * @param inspector_client shared_ptr of VMSDKDebugICBase(in OC class create VMSDKDebugICBase's
 * derived class VMSDKDebugIC class, to obtain id<VMSDKDebugInspectorClient>)
 * @return InspectorBridgeiOS object's shared_ptr
 */
std::shared_ptr<iOS::InspectorBridgeiOS> createInspectorBridge(
    std::shared_ptr<iOS::VMSDKDebugICBase> inspector_client,
    std::shared_ptr<InspectorImpl> devtool) {
  // use constructor to create BridgeiOS
  auto bridge = std::make_shared<iOS::InspectorBridgeiOS>(inspector_client, devtool);

  InspectorBridgeiOSInternal *inspector = [InspectorBridgeiOSInternal new];
  inspector->bridge_ = bridge;
  // from inspector_client to get id<VMSDKDebugInspectorClient> _inspector_client
  auto client = std::dynamic_pointer_cast<vmsdk::devtool::iOS::VMSDKDebugIC>(inspector_client)
                    ->getInspectorClient();
  [client bindInspector:inspector];

  return bridge;
}

namespace iOS {
InspectorBridgeiOS::InspectorBridgeiOS(std::shared_ptr<iOS::VMSDKDebugICBase> inspector_client,
                                       std::shared_ptr<InspectorImpl> devtool)  // called by C++
    : inspector_impl_(devtool) {
  VLOGD("New InspectorBridgeiOS");
  this->inspector_client_ = inspector_client;
}

InspectorBridgeiOS::~InspectorBridgeiOS() { VLOGD("~InspectorBridgeiOS"); }

void InspectorBridgeiOS::DispatchMessage(const std::string &message) {
  VLOGD("[Devtool] Dispatch message: %s.", message.c_str());
  std::shared_ptr<InspectorImpl> ptr_impl = inspector_impl_.lock();
  ptr_impl->DispatchMessage(message);
}

void InspectorBridgeiOS::SendResponseMessage(const std::string &message) {
  VLOGD("[Devtool] Send response: %s.", message.c_str());
  NSString *str = [NSString stringWithCString:message.c_str() encoding:NSUTF8StringEncoding];

  auto ic = std::dynamic_pointer_cast<vmsdk::devtool::iOS::VMSDKDebugIC>(this->inspector_client_);
  auto client = ic->getInspectorClient();

  [client sendResponseMessage:str];
}

}  // namespace iOS
}  // namespace devtool
}  // namespace vmsdk
