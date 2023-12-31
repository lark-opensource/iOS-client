//
//  CJPayBridgePlugin_bio.h
//  CJPay
//
//  Created by liyu on 2020/2/27.
//

#import <TTBridgeUnify/TTBridgeRegister.h>


NS_ASSUME_NONNULL_BEGIN

@interface CJPayBridgePlugin_bio : TTBridgePlugin

TT_BRIDGE_EXPORT_HANDLER(bioPaymentShowState)
TT_BRIDGE_EXPORT_HANDLER(switchBioPaymentState)

@end

NS_ASSUME_NONNULL_END
