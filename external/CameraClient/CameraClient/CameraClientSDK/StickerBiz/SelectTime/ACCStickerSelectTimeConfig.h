//
//  ACCStickerSelectTimeConfig.h
//  CameraClient-Pods-Aweme
//
//  Created by guochenxiang on 2020/8/25.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVAsset.h>
#import <CreationKitArch/AWEVideoPublishViewModelDefine.h>
#import "ACCEditVideoData.h"

NS_ASSUME_NONNULL_BEGIN

@class IESMMVideoDataClipRange;

@protocol ACCStickerSelectTimeConfig <NSObject>

@property (nonatomic, strong, readonly) NSDictionary *referExtra;

- (NSMutableDictionary<NSString *, IESMMVideoDataClipRange *> *)textReadingRanges;

- (NSValue *)sizeOfVideo; // 视频的实际大小

- (AWEVideoSource)videoSource;

- (CGFloat)maxDuration;

- (ACCEditVideoData *)video;

- (AVAsset *)audioAssetInVideoDataWithKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
