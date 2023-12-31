//
//  ACCSecurityFramesCheck.m
//  AWEStudioService-Pods-Aweme
//
//  Created by lixingdong on 2021/4/12.
//

#import "ACCSecurityFramesCheck.h"
#import <CreationKitArch/ACCRecordInformationRepoModel.h>
#import <CameraClient/AWERepoContextModel.h>
#import <CreationKitArch/ACCRepoDraftModel.h>
#import <CameraClient/AWERepoVideoInfoModel.h>
#import <CameraClient/ACCRepoTextModeModel.h>
#import <CameraClient/ACCRepoSmartMovieInfoModel.h>
#import <CameraClient/ACCSmartMovieABConfig.h>
#import <CameraClient/ACCRepoKaraokeModelProtocol.h>
#import <CreationKitArch/AWEDraftUtils.h>
#import <CreativeKit/ACCMonitorToolProtocol.h>
#import <BDWebImage/BDImage.h>
#import <TTVideoEditor/IESInfoSticker.h>
#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreationKitArch/ACCRepoMVModel.h>
#import <CreativeKit/ACCMonitorProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import "ACCSecurityFramesUtils.h"
#import "AWEVideoFragmentInfo.h"
#import <CameraClient/ACCConfigKeyDefines.h>
#import <CameraClient/ACCRepoActivityModel.h>

static NSString * const ACCSecurityModuleOwner = @"raomengyun";

@implementation ACCSecurityFramesCheck

+ (void)checkAssetFrames:(NSArray *)frames publishModel:(AWEVideoPublishViewModel *)publishModel
{
    NSInteger currentCount = frames.count;
    NSInteger offsetAllowed = -1; // 因为录制一个是定时器，一个是时间轴计算方式，存在误差，这里添加一个允许的抽帧误差计算
    NSInteger assetFramesCount = [self expectedNumberOfAssetFramesInPublishModel:publishModel offsetAllowed:&offsetAllowed];
    
    BOOL isError = [[self class] isErrorWithExpectedCount:assetFramesCount realCount:currentCount offsetAllowed:offsetAllowed];
    NSString *text = [NSString stringWithFormat:@"[check] 视频/图片素材抽帧，预期帧数: %@，当前帧数: %@，误差最大值: %@", @(assetFramesCount), @(currentCount), @(offsetAllowed)];
    
    if (isError) {
        AWELogToolError(AWELogToolTagSecurity, text);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [ACCMonitorTool() showWithTitle:text
                                      error:nil
                                      extra:@{@"tag": @"frames"}
                                      owner:ACCSecurityModuleOwner
                                    options:ACCMonitorToolOptionModelAlert|ACCMonitorToolOptionReportToQiaoFu];
        });
    } else {
        AWELogToolInfo(AWELogToolTagSecurity, text);
    }

    [ACCSecurityFramesCheck trackerEvent:@"check_video_frames"
                                   count:currentCount
                           expectedCount:assetFramesCount
                                expected:isError?0:1
                            publishModel:publishModel];
}

+ (void)checkPropsFrames:(NSArray *)frames publishModel:(AWEVideoPublishViewModel *)publishModel
{
    NSInteger currentCount = frames.count;
    NSInteger propVideoFramesCount = [self expectedNumberOfPropFramesInPublishModel:publishModel];
    
    BOOL isError = [[self class] isErrorWithExpectedCount:propVideoFramesCount realCount:currentCount offsetAllowed:-1];
    NSString *text = [NSString stringWithFormat:@"[check] 道具抽帧，预期帧数: %@，当前帧数: %@", @(propVideoFramesCount), @(frames.count)];
    
    if (isError) {
        AWELogToolError(AWELogToolTagSecurity, text);

        dispatch_async(dispatch_get_main_queue(), ^{
            [ACCMonitorTool() showWithTitle:text
                                      error:nil
                                      extra:@{@"tag": @"frames"}
                                      owner:ACCSecurityModuleOwner
                                    options:ACCMonitorToolOptionModelAlert|ACCMonitorToolOptionReportToQiaoFu];
        });
    } else {
        AWELogToolInfo(AWELogToolTagSecurity, text);
    }

    [ACCSecurityFramesCheck trackerEvent:@"check_props_frames"
                                   count:currentCount
                           expectedCount:propVideoFramesCount
                                expected:isError?0:1
                            publishModel:publishModel];
}

+ (void)checkCustomStickerFrames:(NSArray *)frames publishModel:(AWEVideoPublishViewModel *)publishModel
{
    NSInteger currentCount = frames.count;
    NSInteger customStickerFramesCount = [self expectedNumberOfCustomStickerFramesInPublishModel:publishModel];
    
    BOOL isError = [[self class] isErrorWithExpectedCount:customStickerFramesCount realCount:currentCount offsetAllowed:-1];
    NSString *text = [NSString stringWithFormat:@"[check] 自定义贴纸抽帧，预期帧数: %@，当前帧数: %@", @(customStickerFramesCount), @(frames.count)];

    if (isError) {
        AWELogToolError(AWELogToolTagSecurity, text);

        dispatch_async(dispatch_get_main_queue(), ^{
            [ACCMonitorTool() showWithTitle:text
                                      error:nil
                                      extra:@{@"tag": @"frames"}
                                      owner:ACCSecurityModuleOwner
                                    options:ACCMonitorToolOptionModelAlert|ACCMonitorToolOptionReportToQiaoFu];
        });
    } else {
        AWELogToolInfo(AWELogToolTagSecurity, text);
    }

    [ACCSecurityFramesCheck trackerEvent:@"check_sticker_frames"
                                   count:currentCount
                           expectedCount:customStickerFramesCount
                                expected:isError?0:1
                            publishModel:publishModel];
}

// 走兜底逻辑校验
+ (void)checkExceptionForFallback:(BOOL)isFallback
{
    if (isFallback) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [ACCMonitorTool() showWithTitle:@"异常，进入了兜底策略"
                                      error:nil
                                      extra:@{@"tag": @"frames"}
                                      owner:ACCSecurityModuleOwner
                                    options:ACCMonitorToolOptionModelAlert|ACCMonitorToolOptionReportToQiaoFu];
        });
    }
}

// offsetAllowed -1 表示一个未设置的值，按照1来
+ (BOOL)isErrorWithExpectedCount:(NSInteger)expectedCount realCount:(NSInteger)realCount offsetAllowed:(NSInteger)offsetAllowed
{
    BOOL error = YES;
    if (offsetAllowed < 0) {
        offsetAllowed = 1;
    }

    do {
        // 如果计算预期抽帧数量返回就是负数的话，表示已经异常了
        if (expectedCount < 0) {
            break;
        }
        
        // 如果预期抽帧数量大于0，但是实际为0，表示为异常
        if (expectedCount > 0 && realCount == 0) {
            break;
        }
        
        // 如果预期抽帧数量等于0，但实际大于0，也表示为异常。要么多抽了，要么预期抽帧数量错了
        if (expectedCount == 0 && realCount > 0) {
            break;
        }

        // 否则如果差异大于1张就表示异常（这里不是很精确，后续看看实际情况）
        if (ABS(expectedCount-realCount) > offsetAllowed) {
            break;
        }

        error = NO;
    } while (NO);

    return error;
}

#pragma mark - check frames

+ (NSInteger)expectedNumberOfAssetFramesInPublishModel:(AWEVideoPublishViewModel *)publishModel offsetAllowed:(NSInteger *)offsetAllowed {
    *offsetAllowed = 0;
    
    // 单图，照片模式
    if (publishModel.repoContext.isPhoto || publishModel.repoContext.isAudioRecord) {
        return 1;
    }
    
    // 如果是文字模式，不需要对原视频抽帧，如果抽的话是一张背景图
    ACCRepoTextModeModel *textModel = [publishModel extensionModelOfClass:ACCRepoTextModeModel.class];
    if (textModel.isTextMode) {
        return 0;
    }
    
    if ([ACCSmartMovieABConfig isOn] && [publishModel.repoSmartMovie isSmartMovieMode]) {
        return publishModel.repoSmartMovie.assetPaths.count;
    }
    
    // K歌自定义背景，预期视频抽帧数就是自定义背景数量
    id<ACCRepoKaraokeModelProtocol> repoKaraokeModel = [publishModel extensionModelOfProtocol:@protocol(ACCRepoKaraokeModelProtocol)];
    if (repoKaraokeModel.recordMode == ACCKaraokeRecordModeAudio) {
        return repoKaraokeModel.editModel.audioBGImages.count;
    }

    __block NSUInteger result = 0;
    
    // 经典影集，目前只支持照片，如果可以支持视频，这个逻辑就需要修改了
    if (publishModel.repoMV.templateMaterials.count > 0) {
        return publishModel.repoMV.templateMaterials.count;
    }

    // 其它情况视频或者图片都用 fragmentInfo 表示了
    NSArray<AWEVideoFragmentInfo *> *fragmentInfoList = publishModel.repoVideoInfo.fragmentInfo;
    [fragmentInfoList enumerateObjectsUsingBlock:^(AWEVideoFragmentInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        // 元素是图片，抽帧数量+1
        if (obj.imageAssetURL) {
            result++;
            return;
        }

        // 如果是视频，先看range
        CMTimeRange range = obj.clipTimeRange.CMTimeRangeValue;
        if (CMTIMERANGE_IS_INVALID(range) || ACC_FLOAT_EQUAL_ZERO(CMTimeGetSeconds(range.duration))) {
            if (publishModel.repoContext.isRecord) {
                range = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(obj.recordDuration, 10000));
            } else {
                AVURLAsset *avAsset = [AVURLAsset assetWithURL:obj.avAssetURL];
                range = CMTimeRangeMake(kCMTimeZero, avAsset.duration);
            }
        }

        CMTime duration = range.duration;
        CMTime start = range.start;
        CMTime end = CMTimeAdd(start, duration);
        CMTimeValue increment;

        AWEVideoFragmentSourceType sourceType = obj.sourceType;
        if (sourceType == AWEVideoFragmentSourceTypeRecord) {
            (*offsetAllowed)++;
            
            increment = duration.timescale * [ACCSecurityFramesUtils recordFramesInterval];
        } else {
            increment = duration.timescale * [ACCSecurityFramesUtils uploadFramesInterval];
        }

        CMTimeValue currentValue = start.value;
        do {
            currentValue += increment;
            result++;
        } while (currentValue <= end.value && increment > kCMTimeZero.value);

        // 有高清帧的情况，如果大于4s，1帧，如果大于8s，2帧
        if (ACCConfigBool(kConfigBool_enable_hq_vframe) && publishModel.repoContext.isRecord) {
            CGFloat seconds = CMTimeGetSeconds(duration);
            if (seconds >= 8.f) {
                result = result + 2;
            } else if (seconds >= 4.f){
                result = result + 1;
            }
        }
    }];
    
    return result;
}

+ (NSInteger)expectedNumberOfPropFramesInPublishModel:(AWEVideoPublishViewModel *)publishModel {
    // 说明：下面这些计算帧数的代码和绿幕视频抽帧的逻辑基本一致，但不算是胶水代码，这样做就是为了保持两侧逻辑的独立，相互验证
    __block NSUInteger result = 0;
    
    NSArray<AWEVideoFragmentInfo *> *fragmentInfoList = publishModel.repoVideoInfo.fragmentInfo;

    // 多个连续的fragmentInfo可能对应同一个道具视频/图片，所以需要做一个asset和时间区域的聚合
    NSMutableSet<NSString *> *propImageFilePaths = [NSMutableSet set]; // 不需要读成Asset
    
    NSMutableArray<AVURLAsset *>* propVideoAssets = [@[] mutableCopy];
    NSMutableArray<NSNumber *>* propVideoAssetDurations = [@[] mutableCopy];
    __block NSURL* lastStickerAsset = nil;
    __block CGFloat lastStickerPlayedPercent = 0;
    [fragmentInfoList enumerateObjectsUsingBlock:^(AWEVideoFragmentInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        // 需要导入视频的道具
        NSURL* stickerVideoAssetURL = obj.stickerVideoAssetURL;
        if (stickerVideoAssetURL != nil) {
            AVURLAsset* asset = [AVURLAsset assetWithURL:stickerVideoAssetURL];
            if (asset) {
                if ([lastStickerAsset.absoluteString isEqualToString:stickerVideoAssetURL.absoluteString]) {
                    if (obj.stickerBGPlayedPercent > lastStickerPlayedPercent) {
                        lastStickerPlayedPercent = obj.stickerBGPlayedPercent;
                    }

                    [propVideoAssetDurations removeLastObject];
                    [propVideoAssetDurations addObject:@(lastStickerPlayedPercent * CMTimeGetSeconds(asset.duration))];
                } else {
                    [propVideoAssets addObject:asset];
                    [propVideoAssetDurations addObject:@(obj.stickerBGPlayedPercent * CMTimeGetSeconds(asset.duration))];
                }

                lastStickerAsset = stickerVideoAssetURL;
            } else {
                // 道具素材读取失败了
                AWELogToolError(AWELogToolTagSecurity, @"[check][props video] 道具需要视频抽帧，素材读取失败，道具id: %@", obj.stickerId);

                result = -1;
            }
        }
        
        // 需要导入图片的道具
        [obj.stickerImageAssetPaths enumerateObjectsUsingBlock:^(NSString * _Nonnull path, NSUInteger idx, BOOL * _Nonnull stop) {
            if (!ACC_isEmptyString(path)) {
                NSString *fullFilePath = [AWEDraftUtils absolutePathFrom:path taskID:publishModel.repoDraft.taskID];
                if ([[NSFileManager defaultManager] fileExistsAtPath:fullFilePath]) {
                    [propImageFilePaths addObject:path];
                } else {
                    // 道具素材读取失败了
                    AWELogToolError(AWELogToolTagSecurity, @"[check][props video] 道具需要图片抽帧，素材读取失败，道具id: %@，路径:%@", obj.stickerId, fullFilePath);

                    result = -1;
                }
            }
        }];

        if (result == -1) {
            *stop = YES;
            return;
        }
    }];
    
    if (result == -1) {
        return result;
    }

    // 计算道具视频元素的抽帧数量
    [propVideoAssets enumerateObjectsUsingBlock:^(AVURLAsset * _Nonnull asset, NSUInteger idx, BOOL * _Nonnull stop) {
        CMTime duration = asset.duration;
        CMTime startTime = kCMTimeZero;

        if (propVideoAssetDurations.count > 0 && idx < propVideoAssetDurations.count ) {
            duration = CMTimeMake(propVideoAssetDurations[idx].integerValue * duration.timescale, duration.timescale);
        }
        
        CGFloat seconds = CMTimeGetSeconds(duration);
        NSInteger count = seconds / [ACCSecurityFramesUtils uploadFramesInterval];
        CMTimeValue increment = duration.value / (count > 0 ? count : 1.0 / [ACCSecurityFramesUtils uploadFramesInterval]);
        CMTimeValue currentValue = startTime.value;

        while (currentValue <= duration.value && increment > kCMTimeZero.value) {
            result++;
            currentValue += increment;
        }
    }];

    // 计算道具图片元素的抽帧数量
    result += propImageFilePaths.count;
    
    return result;
}

// 自定义贴纸中预期返回的抽帧张数，返回-1表示异常
+ (NSInteger)expectedNumberOfCustomStickerFramesInPublishModel:(AWEVideoPublishViewModel *)publishModel {
    __block NSInteger result = 0;
    
    if (publishModel.repoContext.videoType == AWEVideoTypeNewYearWish) {
        // 许愿需要打入处理后的头像图片，但实际送审的是原图，需要特别处理一下
        return [publishModel.repoActivity uploadFramePathes].count;
    }
    
    NSArray<IESInfoSticker *> *infoStickers = publishModel.repoVideoInfo.video.infoStickers;
    [infoStickers enumerateObjectsUsingBlock:^(IESInfoSticker * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        BOOL isCustomSticker = [obj.userinfo[@"isCustomSticker"] boolValue];
        if (!isCustomSticker) {
            return;
        }
        
        NSString *resourceFilePath = [obj.userinfo[@"customStickerFilePath"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSString *fullFilePath = [AWEDraftUtils absolutePathFrom:resourceFilePath taskID:publishModel.repoDraft.taskID];

        if (!ACC_isEmptyString(fullFilePath) && ![[NSFileManager defaultManager] fileExistsAtPath:fullFilePath]) {
            // 道具素材读取失败了
            AWELogToolError(AWELogToolTagSecurity, @"[check][video custom sticker] 自定义素材读取失败，文件不存在，路径:%@", fullFilePath);
            
            result = -1;
            *stop = YES;
            return ;
        }

        BDImage *image = [BDImage imageWithContentsOfFile:fullFilePath];
        NSInteger numberInOneSticker = 0;

        if (image == nil) {
            // 道具素材读取失败了
            AWELogToolError(AWELogToolTagSecurity, @"[check][video custom sticker] 自定义素材读取失败，将文件读取为图片失败，路径:%@", fullFilePath);
            numberInOneSticker = -1;
        } else {
            if([image isKindOfClass:BDImage.class] && [image frameCount] > 1) { // 动态图
                if (image.frameCount == 1) {
                    numberInOneSticker = 1;
                } else if (image.frameCount == 0) {
                    // 道具素材读取失败了
                    AWELogToolError(AWELogToolTagSecurity, @"[check][video custom sticker] 自定义素材读取失败，动图中图片张数为0，路径:%@", fullFilePath);

                    numberInOneSticker = -1;
                } else {
                    // 这块计算逻辑直接使用gif贴纸抽帧的逻辑
                    CGFloat duration = 0;
                    CGFloat step = 0;
                    for (int i = 0 ; i < image.frameCount; i++) {
                        NSTimeInterval frameDur = [image frameAtIndex:i].nextFrameTime;
                        if(i == 0 || (duration <= step && duration+frameDur >= step)) {
                            numberInOneSticker++;
                            step += 2;
                        }

                        duration += frameDur;
                    }
                }
            } else {
                numberInOneSticker = 1; // 静态图
            }
        }

        if (numberInOneSticker < 0) {
            result = -1;
            *stop = YES;
            
            return ;
        }
        
        result += numberInOneSticker;
    }];

    return result;
}

#pragma mark - Tracker

+ (void)trackerEvent:(NSString *)event
               count:(NSInteger)count
       expectedCount:(NSInteger)expectedCount
            expected:(NSInteger)expected
        publishModel:(AWEVideoPublishViewModel *)publishModel
{
    NSDictionary *params = @{
        @"aweme_type":@(publishModel.repoContext.feedType),
        @"task_id":publishModel.repoDraft.taskID ?: @"",
        @"count":@(count),
        @"expected_count":@(expectedCount),
        @"success":@(expected)
    };

    NSString *info = [NSString stringWithFormat:@"(isDraft:%@, videoType:%@, videoSource:%@, awemeType: %@)", @(publishModel.repoDraft.isDraft), @(publishModel.repoContext.videoType), @(publishModel.repoContext.videoSource), @(publishModel.repoContext.feedType)];
    if (expected) {
        AWELogToolInfo(AWELogToolTagSecurity, @"[check][%@] expected:%@，real:%@，model info: %@", event, @(expectedCount),@(count), info);
    } else {

        AWELogToolError(AWELogToolTagSecurity, @"[check][%@] expected:%@，real:%@，model info: %@", event, @(expectedCount),@(count), info);
    }

    [ACCMonitor() trackService:event status:expected extra:params];
    [ACCTracker() trackEvent:event params:params];
}

@end


