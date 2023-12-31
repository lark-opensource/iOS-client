//
//  IABRPlayStateSupplier.h
//  test
//
//  Created by guikunzhi on 2020/3/29.
//  Copyright © 2020 gkz. All rights reserved.
//

#ifndef IABRPlayStateSupplier_h
#define IABRPlayStateSupplier_h

#import "IVCABRBufferInfo.h"
#import "IVCABRModuleSpeedRecord.h"

@protocol IVCABRPlayStateSupplier <NSObject>

- (float)getPlaySpeed;
- (float)getSpeedConfidence;
- (float)getNetworkSpeed;
- (int)getNetworkState;
- (int)getLoaderType;
- (int)getCurrentDownloadVideoBitrate;
- (int)getCurrentDownloadAudioBitrate;
- (int)getCurrentPlaybackTime;
- (int)getMaxCacheVideoTime;
- (int)getMaxCacheAudioTime;
- (int)getPlayerVideoCacheTime;
- (int)getPlayerAudioCacheTime;
- (int64_t)getExpectedBitrate;
- (nullable NSArray<id<IVCABRModuleSpeedRecord>> *)getTimelineNetworkSpeed;
- (nullable NSDictionary<NSString *, id<IVCABRBufferInfo>> *)getVideoBufferInfo;
- (nullable NSDictionary<NSString *, id<IVCABRBufferInfo>> *)getAudioBufferInfo;


@end

#endif /* IABRPlayStateSupplier_h */
