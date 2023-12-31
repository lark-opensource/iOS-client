//
//  NLEResourceAV_OC+DVE.h
//  NLEPlatform
//
//  Created by bytedance on 2021/4/14.
//

#import <NLEPlatform/NLEResourceAV+iOS.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NLEResourceAV_OC (DVE)

- (void)dve_setupForVideo:(AVURLAsset *)asset;

- (void)dve_setupForVideo:(AVURLAsset *)asset
         resourceFilePath:(NSString *)resourceFilePath;

- (void)dve_setupForPhoto:(NSString *)photoPath
                 duration:(CMTime)duration;

- (void)dve_setupForPhoto:(NSString *)photoPath
                    width:(uint32_t)width
                   height:(uint32_t)height
                 duration:(CMTime)duration;

- (void)dve_setupForAudio:(AVURLAsset *)asset;

- (void)dve_setupForRecord:(AVURLAsset *)asset;

@end

NS_ASSUME_NONNULL_END
