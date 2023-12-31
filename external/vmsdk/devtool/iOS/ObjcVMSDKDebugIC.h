//
//  ObjcVMSDKDebugIC.h
//  vmsdk
//  ObjcVMSDKDebugICBase's derived class, to contain
//  id<VMSDKDebugInspectorClient> object Created by Huang Zongshan on 2022/8/15.
//
#ifndef OBJCVMSDKDEBUGIC_HEADER_H
#define OBJCVMSDKDEBUGIC_HEADER_H

#include "VMSDKDebugICBase.h"
#import "devtool/iOS/inspector_protocol.h"

namespace vmsdk {
namespace devtool {
namespace iOS {
class VMSDKDebugIC : public VMSDKDebugICBase {
 public:
  VMSDKDebugIC(id<VMSDKDebugInspectorClient> inspector_client)
      : _inspector_client(inspector_client) {}
  id<VMSDKDebugInspectorClient> getInspectorClient() {
    return _inspector_client;
  }
  ~VMSDKDebugIC() = default;

 private:
  id<VMSDKDebugInspectorClient> _inspector_client;
};
}  // namespace iOS
}  // namespace devtool
}  // namespace vmsdk
#endif  // OBJCVMSDKDEBUGIC_HEADER_H
