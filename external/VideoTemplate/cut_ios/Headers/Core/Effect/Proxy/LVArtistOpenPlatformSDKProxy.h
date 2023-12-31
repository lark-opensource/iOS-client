//
//  LVArtistOpenPlatformSDKProxy.h
//  VideoTemplate
//
//  Created by wuweixin on 2020/10/23.
//

#import <Foundation/Foundation.h>
#import <ArtistOpenPlatformSDK/ARTEffectHeader.h>
#import "LVEffectPlatformBridgeHeader.h"

NS_ASSUME_NONNULL_BEGIN

@interface LVArtistOpenPlatformSDKProxy : NSObject<LVEffectDownloadProxyDelegate, LVEffectNotFoundEstimatable>

@property(nonatomic, strong, readonly) ARTEffectManager *manager;

-(instancetype)init NS_UNAVAILABLE;
-(instancetype)initWithEffectManager:(ARTEffectManager *)manager;

@end

NS_ASSUME_NONNULL_END
