//
//  HTSVideoData+AWEAddtions.h
//  AWEStudio
//
//  Created by 郝一鹏 on 2018/4/9.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <TTVideoEditor/HTSVideoData.h>
#import "ACCEditVideoData.h"

@interface HTSVideoData (AWEAddtions)

- (void)acc_getRestoreVideoDurationWithSegmentCompletion:(void(^)(CMTime segmentDuration))segmentCompletion;

- (BOOL)acc_videoAssetEqualTo:(ACCEditVideoData *)anotherVideoData;

- (BOOL)acc_audioAssetEqualTo:(ACCEditVideoData *)anotherVideoData;

- (Float64)acc_totalVideoDuration;

- (void)acc_convertCanvasSizeFromSize:(CGSize)fromSize toSize:(CGSize)toSize;

/**
 *@brief 安全访问 AudioTimeClipInfo
 */
- (IESMMVideoDataClipRange *)acc_safeAudioTimeClipInfo:(AVAsset *)asset;

- (AVAsset *)acc_videoAssetAtIndex:(NSUInteger)index;

@end
