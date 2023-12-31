//
//  VMSDKDebugICBase.h
//  vmsdk
//  base for class VMSDKDebugIC, only have .h file
//  use it for id<VMSDKDebugInspectorClient> transporting in C++ files to
//  forward HDT message
//
//  Created by Huang Zongshan on 2022/8/16.
//
#ifndef VMSDKDEBUGICBASE_HEADER_H
#define VMSDKDEBUGICBASE_HEADER_H

namespace vmsdk {
namespace devtool {
namespace iOS {
/**
 * in OC file, the way to get OC pointer from
 * std::shared_ptr<iOS::VMSDKDebugICBase> inspector_client: auto client =
 * std::dynamic_pointer_cast<vmsdk::devtool::iOS::VMSDKDebugIC>(inspector_client)->getInspectorClient();
 *
 * use OC pointer (example):
 * [client bindInspector:xxx];
 */
class VMSDKDebugICBase {
 public:
  VMSDKDebugICBase() = default;
  virtual ~VMSDKDebugICBase() = default;
};
}  // namespace iOS
}  // namespace devtool
}  // namespace vmsdk

#endif  // VMSDKDEBUGICBASE_HEADER_H
