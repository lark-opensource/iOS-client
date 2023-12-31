//
//  HTSVideoData+AWEAddtions.m
//  AWEStudio
//
//  Created by 郝一鹏 on 2018/4/9.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import "HTSVideoData+AWEAddtions.h"
#import <CreationKitInfra/ACCLogProtocol.h>
#import <TTVideoEditor/HTSVideoData+InfoSticker.h>
#import <TTVideoEditor/IESInfoSticker.h>
#import <CreativeKit/ACCMacros.h>

@implementation HTSVideoData (AWEAddtions)

- (void)acc_getRestoreVideoDurationWithSegmentCompletion:(void(^)(CMTime segmentDuration))segmentCompletion
{
    AWELogToolInfo(AWELogToolTagRecord, @"%@", [NSString stringWithFormat:@"Record restore segmentDuration type: %@", self.videoDuration.count ? @"has videoDuration" : @"no videoDuration"]);
    
    CGFloat scale = 1;
    if (self.videoDuration.count) {
        for (AVURLAsset *asset in self.videoAssets) {
            IESDurationInfo *durationInfo = self.videoDuration[asset];
            CMTime assetFragmentDuration = durationInfo.duration;
            if ([self.videoTimeScaleInfo[asset] isKindOfClass:[NSNumber class]]) {
                scale = [((NSNumber*)self.videoTimeScaleInfo[asset]) floatValue];
                if (isnan(scale)) {
                    scale = 1.0;
                }
                assetFragmentDuration = CMTimeMultiplyByFloat64(assetFragmentDuration, 1.0 / scale);
            }
            segmentCompletion(assetFragmentDuration);
        }
    } else {
        [self.videoAssets enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            AVAsset *asset = obj;
            CMTimeRange clipRange = [self videoTimeClipRangeForAsset:asset];
            CGFloat rate = [self videoRateForAsset:asset];
            if (isnan(rate)) {
                rate = 1.0;
            }
            CMTime duration = kCMTimeZero;
            if (clipRange.duration.timescale != 0) {
                duration = CMTimeMake(clipRange.duration.value / rate, clipRange.duration.timescale);
            }
            segmentCompletion(duration);
        }];
    }
}

- (BOOL)acc_videoAssetEqualTo:(ACCEditVideoData *)anotherVideoData
{
    if (self.videoAssets.count != anotherVideoData.videoAssets.count) {
        return NO;
    }
    
    for (NSInteger i = 0; i < self.videoAssets.count; i++) {
        if (![self assetA:self.videoAssets[i] isSameLocalResourceWithAssetB:anotherVideoData.videoAssets[i]]) {
            return NO;
        }
    }
    return YES;
}

- (BOOL)acc_audioAssetEqualTo:(ACCEditVideoData *)anotherVideoData
{
    if (self.audioAssets.count != anotherVideoData.audioAssets.count) {
        return NO;
    }
    
    for (NSInteger i = 0; i < self.audioAssets.count; i++) {
        if (![self assetA:self.audioAssets[i] isSameLocalResourceWithAssetB:anotherVideoData.audioAssets[i]]) {
            return NO;
        }
    }
    return YES;
}

- (BOOL)assetA:(AVAsset *)assetA isSameLocalResourceWithAssetB:(AVAsset *)assetB {
    if ([assetA isKindOfClass:[AVURLAsset class]] && [assetB isKindOfClass:[AVURLAsset class]]) {
        return [((AVURLAsset *)assetA).URL.path isEqualToString:((AVURLAsset *)assetB).URL.path];
    } else {
        return assetA == assetB;
    }
}

- (Float64)acc_totalVideoDuration {
    __block CMTime totalDuration = kCMTimeZero;
    [self acc_getRestoreVideoDurationWithSegmentCompletion:^(CMTime segmentDuration) {
        totalDuration = CMTimeAdd(totalDuration, segmentDuration);
    }];
    return CMTimeGetSeconds(totalDuration);
}

- (void)acc_convertCanvasSizeFromSize:(CGSize)fromSize toSize:(CGSize)toSize
{
    if (ACC_FLOAT_EQUAL_ZERO(fromSize.width) || ACC_FLOAT_EQUAL_ZERO(fromSize.height)) {
        return;
    }
    
    if (ACC_FLOAT_EQUAL_ZERO(toSize.width) || ACC_FLOAT_EQUAL_ZERO(toSize.height)) {
        return;
    }
    
    CGSize lastCanvasSize = fromSize;
    CGSize newCanvasSize = toSize;
    if (!CGSizeEqualToSize(CGSizeZero,lastCanvasSize)) {
        CGFloat lastAspect = lastCanvasSize.width / lastCanvasSize.height;
        CGFloat newAspect = newCanvasSize.width / newCanvasSize.height;
        //画幅变化的情况下，贴纸的位置要发现改变
        if (ABS(newAspect - lastAspect) > 0.001) {
            //归一化的情况下，宽撑满，保持宽度不变，画幅变化的情况下，对原来的高度做裁切或者补齐。
            CGFloat scale = lastCanvasSize.height / lastCanvasSize.width * newAspect;
            AWELogToolInfo2(@"canvasSize", AWELogToolTagAIClip, @"reset canvas size from %@ to %@ ,sticker count = %@ , y:%@", [NSValue valueWithCGSize:lastCanvasSize], [NSValue valueWithCGSize:newCanvasSize], @(self.infoStickers.count),@(scale));
            for (IESInfoSticker *sticker in self.infoStickers) {
                [self setSticker:sticker.stickerId offsetX:sticker.param.offsetX offsetY:sticker.param.offsetY * scale];
            }
        } else {
            AWELogToolInfo2(@"resolution", AWELogToolTagAIClip, @"reset canvas size same aspect pass");
        }
    }
}

- (IESMMVideoDataClipRange *)acc_safeAudioTimeClipInfo:(AVAsset *)asset
{
    if (!asset) {
        return nil;
    }
    __block IESMMVideoDataClipRange *clipRange = nil;
    [self runSync:^{
        clipRange = self.audioTimeClipInfo[asset];
    }];
    return clipRange;
}

- (AVAsset *)acc_videoAssetAtIndex:(NSUInteger)index
{
    __block AVAsset *theAsset = nil;
    [self runSync:^{
        if (index < self.videoAssets.count) {
            theAsset = [self.videoAssets objectAtIndex:index];
        }
    }];
    return theAsset;
}

@end
