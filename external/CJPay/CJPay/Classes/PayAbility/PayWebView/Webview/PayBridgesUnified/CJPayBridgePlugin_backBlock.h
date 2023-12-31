//
//  CJPayBridgePlugin_backBlock.h
//  CJPay
//
//  Created by liyu on 2020/1/15.
//

#import <TTBridgeUnify/TTBridgeRegister.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayBridgePlugin_backBlock : TTBridgePlugin

TT_BRIDGE_EXPORT_HANDLER(backBlock)
TT_BRIDGE_EXPORT_HANDLER(blockNativeBack)

@end

NS_ASSUME_NONNULL_END
