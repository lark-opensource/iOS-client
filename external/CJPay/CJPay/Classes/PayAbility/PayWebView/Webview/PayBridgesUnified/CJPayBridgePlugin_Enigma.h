//
//  CJPayBridgePlugin_Enigma.h
//  CJPay
//
//  Created by liyu on 2020/1/14.
//

#import <TTBridgeUnify/TTBridgeRegister.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayBridgePlugin_Enigma : TTBridgePlugin

TT_BRIDGE_EXPORT_HANDLER(encrypt)
TT_BRIDGE_EXPORT_HANDLER(decrypt)

@end

NS_ASSUME_NONNULL_END
