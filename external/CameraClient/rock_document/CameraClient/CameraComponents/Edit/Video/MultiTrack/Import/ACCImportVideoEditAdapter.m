//
//  ACCImportVideoEditAdapter.m
//  CameraClient-Pods-Aweme
//
//  Created by 饶骏华 on 2021/9/15.
//

#import "ACCImportVideoEditAdapter.h"

#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCServiceLocator.h>
#import <CreationKitArch/ACCVideoConfigProtocol.h>

#import <CameraClient/AWEAssetModel.h>
#import <CameraClient/ACCEditVideoDataFactory.h>

CGFloat kACCPhotoClipMaxSeconds = 3.0f;

@implementation ACCImportVideoEditAdapter

#pragma mark - 单轨道
/// create normal video data
/// @param sourceAssetArray assets array
+ (ACCEditVideoData *)createNormalVideoDataWithSourceAssetArray:(NSArray<AWEAssetModel *> *)sourceAssetArray cahceDirPath:( NSString *)dirPath {
    return [self createNormalVideoDataWithSourceAssetArray:sourceAssetArray isLimitDuration:YES isReset:NO cacheDirPath:dirPath];
}

/// create normal video data
/// @param sourceAssetArray assets array
/// @param isLimitDuration whether the video is used by clip page (video's length of clipping page is not limited by video Max Seconds）
+ (ACCEditVideoData *)createNormalVideoDataWithSourceAssetArray:(NSArray<AWEAssetModel *> *)sourceAssetArray isLimitDuration:(BOOL)isLimitDuration isReset:(BOOL)isReset cacheDirPath:( NSString *)dirPath {
    AWELogToolInfo2(@"resolution", AWELogToolTagAIClip, @"[new edit clip][create normal] isLimitDuration:%@, isReset: %@", @(isLimitDuration), @(isReset));
    ACCEditVideoData *videoData = [ACCEditVideoDataFactory videoDataWithCacheDirPath:dirPath];
    __block NSTimeInterval currentTotalDuration = 0.0;
    [sourceAssetArray enumerateObjectsUsingBlock:^(AWEAssetModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        AVURLAsset *urlAsset = (AVURLAsset *)obj.avAsset;
        CMTimeRange range = CMTimeRangeMake(kCMTimeZero, obj.avAsset.duration);
        HTSVideoSpeed speed = HTSVideoSpeedNormal;
        BOOL isAssetClipValid = obj.assetClipTimeRange && CMTimeCompare([obj.assetClipTimeRange CMTimeRangeValue].duration, kCMTimeZero) == 1;
        
        AWELogToolInfo2(@"resolution", AWELogToolTagAIClip, @"[new edit clip][create normal] avAsset.duration: %@, isAssetClipValid : %@", @(CMTimeGetSeconds(obj.avAsset.duration)), @(isAssetClipValid));
        if (isLimitDuration && isAssetClipValid && !isReset) {
            range = [obj.assetClipTimeRange CMTimeRangeValue];
            speed = obj.speed;
            
            AWELogToolInfo2(@"resolution", AWELogToolTagAIClip, @"[new edit clip][create normal] range: %@, speed : %@", [NSValue valueWithCMTimeRange:range], @(speed));
        }
        
        if (isReset) {
            obj.assetClipTimeRange = [NSValue valueWithCMTimeRange:range];
            obj.speed = speed;
        }

        NSTimeInterval duration = CMTimeGetSeconds(range.duration) * speed;
        AWELogToolInfo2(@"resolution", AWELogToolTagAIClip, @"[new edit clip][create normal] original index:%@, duration: %@", @(idx), @(duration));
        
        // 图片限制可裁剪范围为3s
        NSURL *frameImageURL = urlAsset.frameImageURL;
        if (frameImageURL && !(isLimitDuration && isAssetClipValid)) {
            duration = CMTimeGetSeconds(CMTimeMakeWithSeconds(kACCPhotoClipMaxSeconds, 10000.0)) * speed;
        }
        
        IESMMVideoDataClipRange *clipRange;
        if (isLimitDuration) {
            if (currentTotalDuration < [self videoMaxSeconds] && (currentTotalDuration + duration) <= [self videoMaxSeconds]) {
                clipRange = IESMMVideoDataClipRangeMake(CMTimeGetSeconds(range.start) *speed ,duration);
                currentTotalDuration += duration;
            } else if (currentTotalDuration < [self videoMaxSeconds] && (currentTotalDuration + duration) >= [self videoMaxSeconds]) {
                clipRange = IESMMVideoDataClipRangeMake(CMTimeGetSeconds(range.start) *speed ,[self videoMaxSeconds] - currentTotalDuration);
                currentTotalDuration = [self videoMaxSeconds];
            } else {
                clipRange = IESMMVideoDataClipRangeMake(CMTimeGetSeconds(range.start) *speed ,duration);
                clipRange.isDisable = YES;
            }
        } else {
            clipRange = IESMMVideoDataClipRangeMake(CMTimeGetSeconds(range.start) *speed ,duration);
        }
        
        AWELogToolInfo2(@"resolution", AWELogToolTagAIClip, @"[new edit clip][create normal] index:%@ isLimitDuration:%@, clipRange: %@", @(idx), @(isLimitDuration), clipRange);
        if (urlAsset) {
            urlAsset = (AVURLAsset *)[videoData addVideoWithAsset:urlAsset];
            if ([videoData.videoAssets containsObject:urlAsset]) {
                [videoData updateAssetRotationsInfoWithRotateType:[self degreeOfRotateType:obj.rotateType] asset:urlAsset];
                [videoData updateVideoTimeScaleInfoWithScale:@(obj.speed) asset:urlAsset];//设置速度
                [videoData updateVideoTimeClipInfoWithClipRange:clipRange asset:urlAsset];//设置裁剪
            }
            if (obj.avAsset.frameImageURL) {
                [videoData updatePhotoAssetInfoWithURL:obj.avAsset.frameImageURL asset:urlAsset];
            }
        }
    }];
    videoData.enableVideoAnimation = NO;
    videoData.isFastImport = YES;
    
    return videoData;
}

#pragma mark - 多轨道

/// 生成一个支持多轨道编辑VideoData，支持主轨道和附轨道各一个片段素材
/// @param MainTrackAssetArray 主轨道视频的素材 subTrackAssetArray:副轨道视频的素材
+ (ACCEditVideoData *)createMultiTrackNormalVideoDataWithMainTrackAssetArray:(NSArray<AWEAssetModel *> *)mainAssetArray
                                                          subTrackAssetArray:(NSArray<AWEAssetModel *> *)subAssetArray
                                                                cahceDirPath:( NSString *)dirPath {
    ACCEditVideoData *videoData = [ACCEditVideoDataFactory videoDataWithCacheDirPath:dirPath];
    
    // 主轨道片段
    __block NSTimeInterval currentTotalDuration = 0.0;
    [mainAssetArray enumerateObjectsUsingBlock:^(AWEAssetModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        IESMMVideoDataClipRange *clipRange = [self configLimitDuration:YES isReset:NO currentTotalDuration:&currentTotalDuration withAsset:obj];
        if (obj.avAsset) {
            AVURLAsset *urlAsset;
            urlAsset = (AVURLAsset *)obj.avAsset;
            urlAsset = (AVURLAsset *)[videoData addVideoWithAsset:urlAsset];
            if ([videoData.videoAssets containsObject:urlAsset]) {
                [videoData updateAssetRotationsInfoWithRotateType:[self degreeOfRotateType:obj.rotateType] asset:urlAsset];
                [videoData updateVideoTimeScaleInfoWithScale:@(obj.speed) asset:urlAsset];//设置速度
                [videoData updateVideoTimeClipInfoWithClipRange:clipRange asset:urlAsset];//设置裁剪
            }
            if (obj.avAsset.frameImageURL) {
                [videoData updatePhotoAssetInfoWithURL:obj.avAsset.frameImageURL asset:urlAsset];
            }
        } else {
            AWELogToolError2(@"multiTrack", AWELogToolTagImport, @"mainTrack asset is nil.");
        }
    }];
    
    // 副轨道片段
    __block NSTimeInterval currentSubTrackTotalDuration = 0.0;
    [subAssetArray enumerateObjectsUsingBlock:^(AWEAssetModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        IESMMVideoDataClipRange *clipRange = [self configLimitDuration:YES isReset:NO currentTotalDuration:&currentSubTrackTotalDuration withAsset:obj];
        if (obj.avAsset) {
            AVURLAsset *urlAsset;
            urlAsset = (AVURLAsset *)obj.avAsset;
            urlAsset = (AVURLAsset *)[videoData addSubTrackWithAsset:urlAsset];
            if ([videoData.subTrackVideoAssets containsObject:urlAsset]) {
                [videoData updateAssetRotationsInfoWithRotateType:[self degreeOfRotateType:obj.rotateType] asset:urlAsset];
                [videoData updateVideoTimeScaleInfoWithScale:@(obj.speed) asset:urlAsset];//设置速度
                [videoData updateVideoTimeClipInfoWithClipRange:clipRange asset:urlAsset];//设置裁剪
            }
            if (obj.avAsset.frameImageURL) {
                [videoData updatePhotoAssetInfoWithURL:obj.avAsset.frameImageURL asset:urlAsset];
            }
        } else {
            AWELogToolError2(@"multiTrack", AWELogToolTagImport, @"subTrack asset is nil.");
        }
    }];
    
    return videoData;
}
    
#pragma mark - Private

+ (IESMMVideoDataClipRange *)configLimitDuration:(BOOL)isLimitDuration
                    isReset:(BOOL)isReset
       currentTotalDuration:(NSTimeInterval *)currentTotalDuration
                  withAsset:(AWEAssetModel * _Nonnull)obj {
    AVAsset *urlAsset = obj.avAsset;
    // 1.配置默认的限制速率和时长
    CMTimeRange range = CMTimeRangeMake(kCMTimeZero, obj.avAsset.duration);
    HTSVideoSpeed speed = HTSVideoSpeedNormal;
    BOOL isAssetClipValid = obj.assetClipTimeRange && CMTimeCompare([obj.assetClipTimeRange CMTimeRangeValue].duration, kCMTimeZero) == 1;
    AWELogToolInfo2(@"multiTrack", AWELogToolTagImport, @"[multiTrack][create normal] avAsset.duration: %@, isAssetClipValid : %@", @(CMTimeGetSeconds(obj.avAsset.duration)), @(isAssetClipValid));
    
    if (isLimitDuration && isAssetClipValid && !isReset) { // 限制最大时长&裁减合法&非重置默认
        range = [obj.assetClipTimeRange CMTimeRangeValue];
        speed = obj.speed;
        AWELogToolInfo2(@"multiTrack", AWELogToolTagImport, @"[multiTrack][create normal] range: %@, speed : %@", [NSValue valueWithCMTimeRange:range], @(speed));
    }
    
    if (isReset) {
        obj.assetClipTimeRange = [NSValue valueWithCMTimeRange:range];
        obj.speed = speed;
    }
    
    NSTimeInterval duration = CMTimeGetSeconds(range.duration) * speed;
    AWELogToolInfo2(@"multiTrack", AWELogToolTagImport, @"[multiTrack][create normal] duration: %@",  @(duration));
    
    NSURL *frameImageURL = urlAsset.frameImageURL;
    if (frameImageURL && !(isLimitDuration && isAssetClipValid)) { // 图片限制可裁剪范围为3s
        duration = CMTimeGetSeconds(CMTimeMakeWithSeconds(kACCPhotoClipMaxSeconds, 10000.0)) * speed;
    }
    
    IESMMVideoDataClipRange *clipRange;
    if (isLimitDuration) {
        if (*currentTotalDuration < [self videoMaxSeconds] && (*currentTotalDuration + duration) <= [self videoMaxSeconds]) {
            clipRange = IESMMVideoDataClipRangeMake(CMTimeGetSeconds(range.start) *speed ,duration);
            *currentTotalDuration += duration;
        } else if (*currentTotalDuration < [self videoMaxSeconds] && (*currentTotalDuration + duration) >= [self videoMaxSeconds]) {
            clipRange = IESMMVideoDataClipRangeMake(CMTimeGetSeconds(range.start) *speed ,[self videoMaxSeconds] - *currentTotalDuration);
            *currentTotalDuration = [self videoMaxSeconds];
        } else {
            clipRange = IESMMVideoDataClipRangeMake(CMTimeGetSeconds(range.start) *speed ,duration);
            clipRange.isDisable = YES;
        }
    } else {
        clipRange = IESMMVideoDataClipRangeMake(CMTimeGetSeconds(range.start) *speed ,duration);
    }
    
    AWELogToolInfo2(@"multiTrack", AWELogToolTagImport, @"[multiTrack][create normal] isLimitDuration:%@, clipRange: %@", @(isLimitDuration), clipRange);
    return clipRange;
}

#pragma mark - Utils

+ (CGFloat)videoMaxSeconds {
    let config = IESAutoInline(ACCBaseServiceProvider(), ACCVideoConfigProtocol);
    return config.videoUploadMaxSeconds;
}

+ (CGFloat)videoMinSeconds {
    let config = IESAutoInline(ACCBaseServiceProvider(), ACCVideoConfigProtocol);
    return config.videoMinSeconds;
}

+ (NSNumber *)degreeOfRotateType:(AWEVideoCompositionRotateType)rotateType {
    NSInteger degree = 90 * rotateType;
    while (degree < 0) {
        degree += 360;
        degree %= 360;
    }
    return @(degree);
}

@end
