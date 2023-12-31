//
//  BDJSBridgeAuthenticator.h
//  BDJSBridgeCore
//
//  Created by 李琢鹏 on 2019/12/30.
//

#import "BDJSBridgeCoreDefines.h"

NS_ASSUME_NONNULL_BEGIN

@protocol BDJSBridgeAuthenticator <NSObject>

@required

+ (void)registerBridge:(NSString *)bridgeName authType:(BDJSBridgeAuthType)authType namespace:(NSString *)namespace;
+ (void)unregisterBridge:(NSString *)bridgeName namespace:(NSString *)namespace;
+ (BOOL)isAuthorizedBridge:(NSString *)bridgeName inURLString:(NSString *)domain namespace:(NSString *)namespace;

@end

NS_ASSUME_NONNULL_END
