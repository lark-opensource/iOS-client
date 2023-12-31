//
//  CJPayBridgePlugin_sendDeviceInfo.h
//  Pods
//
//  Created by 易培淮 on 2021/9/13.
//

#import <TTBridgeUnify/TTBridgeRegister.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayBridgePlugin_sendDeviceInfo : TTBridgePlugin

TT_BRIDGE_EXPORT_HANDLER(sendDeviceInfo)
TT_BRIDGE_EXPORT_HANDLER(setDeviceInfo)

@end

NS_ASSUME_NONNULL_END
