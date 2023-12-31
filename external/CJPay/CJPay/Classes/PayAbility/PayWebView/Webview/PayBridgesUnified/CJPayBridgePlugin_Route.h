//
//  CJPayBridgePlugin_Route.h
//  CJPay
//
//  Created by liyu on 2020/1/14.
//

#import <TTBridgeUnify/TTBridgeRegister.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayBridgePlugin_Route : TTBridgePlugin

TT_BRIDGE_EXPORT_HANDLER(setWebviewInfo)
TT_BRIDGE_EXPORT_HANDLER(closeWebview)
TT_BRIDGE_EXPORT_HANDLER(goH5)

@end

NS_ASSUME_NONNULL_END
