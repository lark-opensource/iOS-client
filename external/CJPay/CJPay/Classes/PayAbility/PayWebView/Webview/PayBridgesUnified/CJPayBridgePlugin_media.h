//
//  CJPayBridgePlugin_media.h
//  Pods
//
//  Created by 孔伊宁 on 2021/10/26.
//

#import <TTBridgeUnify/TTBridgeRegister.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayBridgePlugin_media : TTBridgePlugin

TT_BRIDGE_EXPORT_HANDLER(chooseMedia)
TT_BRIDGE_EXPORT_HANDLER(uploadMedia)

@end

NS_ASSUME_NONNULL_END
