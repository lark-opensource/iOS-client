//
//  CJPayBridgePlugin_loading.h
//  CJPay
//
//  Created by liyu on 2020/1/13.
//

#import <TTBridgeUnify/TTBridgeRegister.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayBridgePlugin_loading : TTBridgePlugin

TT_BRIDGE_EXPORT_HANDLER(showLoading)
TT_BRIDGE_EXPORT_HANDLER(hideLoading)

@end

NS_ASSUME_NONNULL_END
