//
//  ARTEffectModelDownloadTask.h
//  ArtistOpenPlatformSDK
//
//  Created by wuweixin on 2020/10/20.
//

#import <Foundation/Foundation.h>
#import "ARTEffectBaseDownloadTask.h"

@class ARTManifestManager;
@protocol ARTEffectPrototype;

NS_ASSUME_NONNULL_BEGIN

@interface ARTEffectCommonDownloadTask : ARTEffectBaseDownloadTask
@property (nonatomic, strong) ARTManifestManager *manifestManager;
@property (nonatomic, strong, readonly) id<ARTEffectPrototype> effect;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithEffect:(id<ARTEffectPrototype>)effect destination:(NSString *)destination;

@end

NS_ASSUME_NONNULL_END
