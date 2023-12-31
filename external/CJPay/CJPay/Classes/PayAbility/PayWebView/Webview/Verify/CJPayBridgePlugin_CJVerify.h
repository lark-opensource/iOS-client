//
//  CJPayBridgePlugin_CJVerify.h
//  CJPay
//
//  Created by liyu on 2020/7/12.
//

#import <TTBridgeUnify/TTBridgeRegister.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayBridgePlugin_CJVerify : TTBridgePlugin

TT_BRIDGE_EXPORT_HANDLER(CJVerify)
TT_BRIDGE_EXPORT_HANDLER(CJVerifyNotify)

@end

NS_ASSUME_NONNULL_END
