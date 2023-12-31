//
//  LVEffectPlatformSDKProxy.h
//  VideoTemplate
//
//  Created by wuweixin on 2020/10/23.
//

#import <Foundation/Foundation.h>
#import "LVEffectPlatformBridgeHeader.h"
@class EffectPlatform;

NS_ASSUME_NONNULL_BEGIN

@interface LVEffectPlatformSDKProxy : NSObject<LVEffectDownloadProxyDelegate>

@property(nonatomic, strong, readonly) EffectPlatform *effectPlatform;

-(instancetype)init NS_UNAVAILABLE;
-(instancetype)initWithEffectPlatform:(EffectPlatform *)effectPlatform;

@end

NS_ASSUME_NONNULL_END
