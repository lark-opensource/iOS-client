//
//  ACCSecurityFramesExporter.m
//  AWEStudioService-Pods-Aweme
//
//  Created by lixingdong on 2021/3/31.
//

#import "ACCSecurityFramesExporter.h"
#import <CreationKitArch/ACCRepoDraftModel.h>
#import <CreationKitArch/AWEEffectFilterDataManager.h>
#import <CreationKitArch/ACCRecordInformationRepoModel.h>
#import <TTVideoEditor/IESInfoSticker.h>
#import <CreativeKit/UIImage+ACC.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreationKitArch/AWEDraftUtils.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <VideoTemplate/AVAssetImageGenerator+LV.h>

#import "ACCSecurityFramesSaver.h"
#import "ACCSecurityFramesUtils.h"
#import "ACCSecurityFramesCheck.h"
#import <CameraClient/ACCRepoSecurityInfoModel.h>
#import <CameraClient/ACCRepoTextModeModel.h>
#import <CameraClient/ACCRepoAudioModeModel.h>
#import <CreationKitArch/ACCRepoUploadInfomationModel.h>
#import <CreationKitArch/ACCRepoMVModel.h>
#import <CameraClient/AWERepoVideoInfoModel.h>
#import <CameraClient/AWERepoContextModel.h>
#import <CameraClient/ACCRepoSmartMovieInfoModel.h>
#import <CameraClient/ACCRepoActivityModel.h>
#import <BDWebImage/BDImage.h>
#import "AWEVideoFragmentInfo.h"
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CreativeKit/ACCMonitorProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>

static NSString * const ACCSecurityMonitorAssetPathAccessService = @"export_asset_path_access_rate";
static NSString * const ACCSecurityMonitorFallbackEvent = @"export_asset_path_fallback_rate";

@implementation ACCSecurityFramesExporter

+ (dispatch_queue_t)securityExportQueue
{
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("com.AWEStudio.queue.securityExport", DISPATCH_QUEUE_SERIAL);
    });
    
    return queue;
}

+ (void)exportVideoFramesWithPublishModel:(AWEVideoPublishViewModel *)publishModel
                                  awemeId:(NSString *)awemeId
                               completion:(void (^)(NSArray *framePaths, NSError *error))completion
{
    // 如果是K歌和许愿的官方背景视频，不需要对原视频抽帧
    if (publishModel.repoContext.isKaraokeOfficialBGVideo || publishModel.repoContext.isWishOfficialBGVideo) {
        ACCBLOCK_INVOKE(completion, @[], nil);
        return;
    }
    
    // 如果是文字模式，不需要对原视频抽帧，如果抽的话是一张背景图
    ACCRepoTextModeModel *textModel = [publishModel extensionModelOfClass:ACCRepoTextModeModel.class];
    if (textModel.isTextMode) {
        ACCBLOCK_INVOKE(completion, @[], nil);
        return;
    }

    acc_dispatch_queue_async_safe([self securityExportQueue], ^{
        // 拍照，使用拍摄过程的原始图片作为审核帧
        if (publishModel.repoContext.isPhoto) {
            [self p_exportFramesForTakePhotoWithPublishModel:publishModel awemeId:awemeId completion:completion];
            return;
        }
        
        // 语音模式 使用用户头像素材作为审核内容 不需要对视频抽帧
        if (publishModel.repoAudioMode.isAudioMode) {
            [self p_exportFramesForAudioModeWithPublishModel:publishModel awemeId:awemeId completion:completion];
            return;
        }

        // 拍摄视频，直接使用拍摄过程抽的帧作为审核帧
        if (publishModel.repoContext.isRecord &&
            publishModel.repoContext.videoType != AWEVideoTypeNewYearWish &&
            !publishModel.repoContext.isKaraokeAudio && // karaoke audio bg images will be exported in the following methods
            !ACC_isEmptyArray(publishModel.repoVideoInfo.originalFrameNamesArray)) {
            [self p_exportFramesForRecordVideoWithPublishModel:publishModel awemeId:awemeId completion:completion];
            return;
        }

        // 上传类、模板类视频，使用原始AVAsset进行抽帧送审核
        [self p_exportFramesForUploadVideoWithPublishModel:publishModel
                                                   awemeId:awemeId
                                                completion:^(NSArray *framePaths, NSError *error) {
            NSMutableArray *resultPaths = [framePaths mutableCopy];
            
            if (!publishModel.repoContext.isKaraokeAudio && publishModel.repoContext.videoType != AWEVideoTypeNewYearWish) {
                // 兼容老版本模板类视频将帧信息带入到新创建的fragment的case
                NSArray<NSString *> *framePaths = publishModel.repoVideoInfo.originalFrameNamesArray;
                [framePaths enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if (![resultPaths containsObject:obj]) {
                        [resultPaths addObject:obj];
                    }
                }];
            }
            
            ACCBLOCK_INVOKE(completion, resultPaths.copy, error);
        }];
    });
}

+ (void)exportCustomStickerFramesWithPublishModel:(AWEVideoPublishViewModel *)publishModel
                                       completion:(void (^)(NSArray *framePaths, NSError *error))completion
{
    dispatch_async([self securityExportQueue], ^{
        NSMutableArray *extractFrames = [NSMutableArray new];
        
        dispatch_group_t group = dispatch_group_create();
        
        if (publishModel.repoContext.videoType == AWEVideoTypeNewYearWish) {
            // 许愿需要打入处理后的头像图片，但实际送审的是原图，需要特别处理一下
            [[publishModel.repoActivity uploadFramePathes] acc_forEach:^(NSString * _Nonnull obj) {
                dispatch_group_enter(group);
                BDImage *image = [BDImage imageWithContentsOfFile:obj];
                [ACCSecurityFramesSaver saveImage:image
                                             type:ACCSecurityFrameTypeCustomSticker
                                           taskId:publishModel.repoDraft.taskID
                                       completion:^(NSString * _Nonnull path, BOOL success, NSError * _Nonnull error) {
                    if (path.length) {
                        [extractFrames acc_addObject:path];
                    }
                    dispatch_group_leave(group);
                }];
            }];
            dispatch_group_notify(group, dispatch_get_main_queue(), ^{
                ACCBLOCK_INVOKE(completion, extractFrames.copy, nil);
            });
            return;
        }
    
        [publishModel.repoVideoInfo.video.infoStickers enumerateObjectsUsingBlock:^(IESInfoSticker * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop){
            @autoreleasepool {
                NSString *customStickerFilePath = ACCDynamicCast(obj.userinfo[@"customStickerFilePath"], NSString);
                NSString *fullCustomStickerFilePath = [AWEDraftUtils absolutePathFrom:customStickerFilePath taskID:publishModel.repoDraft.taskID];
                if (fullCustomStickerFilePath.length==0 || ![[NSFileManager defaultManager] fileExistsAtPath:fullCustomStickerFilePath]) {
                    return ;
                }

                if ([fullCustomStickerFilePath.lastPathComponent hasSuffix:@"gif"]) {
                    BDImage *animatedImage = [BDImage imageWithContentsOfFile:fullCustomStickerFilePath];
                    if ([animatedImage frameCount] > 0) {
                        CGFloat duration = 0;
                        CGFloat step = 0;
                        NSMutableArray *gifFrames = [NSMutableArray new];
                        for (int i = 0 ; i < animatedImage.frameCount; i++) {
                            NSTimeInterval frameDur = [animatedImage frameAtIndex:i].nextFrameTime;
                            if (i == 0 || (duration <= step && duration+frameDur >= step)) {
                                @autoreleasepool {
                                    UIImage *frameImg = [animatedImage frameAtIndex:i].image;
                                    [gifFrames acc_addObject:frameImg];
                                }

                                step += 2;
                            }
                            duration += frameDur;
                        }

                        dispatch_group_enter(group);
                        [ACCSecurityFramesSaver saveImages:gifFrames
                                                      type:ACCSecurityFrameTypeCustomSticker
                                                    taskId:publishModel.repoDraft.taskID
                                                compressed:NO
                                                completion:^(NSArray<NSString *> * _Nonnull paths, BOOL success, NSError * _Nonnull error) {
                            if (!ACC_isEmptyArray(paths)) {
                                [extractFrames addObjectsFromArray:paths];
                            }

                            dispatch_group_leave(group);
                        }];
                    }
                } else {
                    UIImage *stickerImage = [UIImage imageWithContentsOfFile:fullCustomStickerFilePath];
                    if (stickerImage != nil) {
                        dispatch_group_enter(group);
                        [ACCSecurityFramesSaver saveImage:stickerImage
                                                     type:ACCSecurityFrameTypeCustomSticker
                                                   taskId:publishModel.repoDraft.taskID
                                               completion:^(NSString * _Nonnull path, BOOL success, NSError * _Nonnull error) {
                            if (!ACC_isEmptyString(path)) {
                                [extractFrames addObject:path];
                            }

                            dispatch_group_leave(group);
                        }];
                    }
                }
            }
        }];
        
        dispatch_group_notify(group, dispatch_get_main_queue(), ^{
            ACCBLOCK_INVOKE(completion, extractFrames.copy, nil);
        });
    });
}

+ (void)exportPropsFramesWithPropsAssets:(NSArray<AVAsset *> *)videoAssets
                           clipDurations:(NSMutableArray<NSNumber *> *)clipDurations
                            publishModel:(AWEVideoPublishViewModel *)publishModel
                              completion:(void (^)(NSArray *framePaths, NSError *error))completion
{
    [self p_exportFramesWithAssets:videoAssets
                         videoData:nil
               restrictDurationArr:clipDurations
                         frameType:ACCSecurityFrameTypeProps
                      publishModel:publishModel
                        completion:completion];
}

+ (void)exportPropsFramesWithPublishModel:(AWEVideoPublishViewModel *)publishModel
                               completion:(void (^)(NSArray *framePaths, NSError *error))completion
{
    if (ACC_isEmptyArray(publishModel.repoSecurityInfo.bgStickerVideoAssests)) {
        ACCBLOCK_INVOKE(completion, publishModel.repoSecurityInfo.bgStickerImageAssests, nil);
        return;
    }
    [self p_exportFramesWithAssets:publishModel.repoSecurityInfo.bgStickerVideoAssests
                         videoData:nil
               restrictDurationArr:publishModel.repoSecurityInfo.bgStickerVideoAssetsClipDuration
                         frameType:ACCSecurityFrameTypeProps
                      publishModel:publishModel
                        completion:completion];
}

#pragma mark - Private

+ (void)p_exportFramesForRecordVideoWithPublishModel:(AWEVideoPublishViewModel *)publishModel
                                           awemeId:(NSString *)awemeId
                                        completion:(void (^)(NSArray *framePaths, NSError *error))completion
{
    acc_dispatch_queue_async_safe([self securityExportQueue], ^{
        // 拍摄视频，直接使用拍摄过程抽的帧作为审核帧
        if (publishModel.repoContext.isRecord) {
            ACCBLOCK_INVOKE(completion, publishModel.repoVideoInfo.originalFrameNamesArray.copy, nil);
        } else {
            ACCBLOCK_INVOKE(completion, nil, nil);
        }
    });
}

+ (void)p_exportFramesForTakePhotoWithPublishModel:(AWEVideoPublishViewModel *)publishModel
                                           awemeId:(NSString *)awemeId
                                        completion:(void (^)(NSArray *framePaths, NSError *error))completion
{
    acc_dispatch_queue_async_safe([self securityExportQueue], ^{
        // 拍照，使用拍摄过程的原始图片作为审核帧
        if (publishModel.repoUploadInfo.toBeUploadedImage) {
            // 判断是否有原始照片，如果有原始照片，优先使用原始照片送审。
            NSString *shootPhotoFramePath = publishModel.repoSecurityInfo.shootPhotoFramePath;
            
            if (!ACC_isEmptyString(shootPhotoFramePath)) {
                ACCBLOCK_INVOKE(completion, @[shootPhotoFramePath], nil);
            } else if (!ACC_isEmptyArray(publishModel.repoVideoInfo.originalFrameNamesArray)) {
                ACCBLOCK_INVOKE(completion, publishModel.repoVideoInfo.originalFrameNamesArray, nil);
            } else {
                [ACCSecurityFramesSaver saveImage:publishModel.repoUploadInfo.toBeUploadedImage type:ACCSecurityFrameTypeRecord taskId:publishModel.repoDraft.taskID completion:^(NSString * _Nonnull path, BOOL success, NSError * _Nonnull error) {
                    if (!ACC_isEmptyString(path)) {
                        ACCBLOCK_INVOKE(completion, @[path], nil);
                    } else {
                        ACCBLOCK_INVOKE(completion, @[], nil);
                    }
                }];
            }
        }
    });
}

+ (void)p_exportFramesForAudioModeWithPublishModel:(AWEVideoPublishViewModel *)publishModel
                                           awemeId:(NSString *)awemeId
                                        completion:(void (^)(NSArray *framePaths, NSError *error))completion
{
    acc_dispatch_queue_async_safe([self securityExportQueue], ^{
        if (publishModel.repoUploadInfo.toBeUploadedImage) {
            [ACCSecurityFramesSaver saveImage:publishModel.repoUploadInfo.toBeUploadedImage type:ACCSecurityFrameTypeRecord taskId:publishModel.repoDraft.taskID completion:^(NSString * _Nonnull path, BOOL success, NSError * _Nonnull error) {
                if (!ACC_isEmptyString(path)) {
                    ACCBLOCK_INVOKE(completion, @[path], nil);
                } else {
                    ACCBLOCK_INVOKE(completion, @[], nil);
                }
            }];
        }
    });
}

+ (void)p_exportFramesForUploadVideoWithPublishModel:(AWEVideoPublishViewModel *)publishModel
                                             awemeId:(NSString *)awemeId
                                          completion:(void (^)(NSArray *framePaths, NSError *error))completion
{
    acc_dispatch_queue_async_safe([self securityExportQueue], ^{
        // 未优化的MV影集
        if (publishModel.repoMV.templateMaterials.count > 0) {
            [ACCSecurityFramesSaver compressImages:publishModel.repoMV.templateMaterials
                                              type:ACCSecurityFrameTypeTemplate
                                            taskId:publishModel.repoDraft.taskID
                                        completion:^(NSArray<NSString *> * _Nonnull paths, BOOL success, NSError * _Nonnull error) {
                ACCBLOCK_INVOKE(completion, paths, nil);
            }];
            return;
        }

        if (publishModel.repoSmartMovie.videoMode == ACCSmartMovieSceneModeSmartMovie) {
            ACCBLOCK_INVOKE(completion, publishModel.repoSmartMovie.thumbPaths, nil);
            return;
        }
        
        // 上传类、模板类视频，使用原始AVAsset进行抽帧送审核
        if (ACC_isEmptyArray(publishModel.repoVideoInfo.fragmentInfo) || [self isInvalideFragmentInfoInModel:publishModel]) {
            [publishModel.repoVideoInfo updateFragmentInfoForce:YES];
        }
        
        if (ACC_isEmptyArray(publishModel.repoVideoInfo.fragmentInfo)) {
            [ACCSecurityFramesUtils showACCMonitorAlertWithErrorCode:ACCSecurityFramesErrorEmptyFragmentInfo];
        }
        
        if ([self isInvalideFragmentAssetPathInModel:publishModel]) {
            [ACCSecurityFramesExporter uploadVideoFallbackTracker:YES invalidFragment:YES publishModel:publishModel];
            [self p_exportFramesWithAssets:publishModel.repoVideoInfo.video.videoAssets
                                 videoData:publishModel.repoVideoInfo.video
                       restrictDurationArr:nil
                                 frameType:ACCSecurityFrameTypeUpload
                              publishModel:publishModel completion:completion];
            return;
        }
        
        NSMutableArray *resultPaths = [[NSMutableArray alloc] init];
        dispatch_group_t group = dispatch_group_create();
        
        @weakify(self);
        [publishModel.repoVideoInfo.fragmentInfo enumerateObjectsUsingBlock:^(AWEVideoFragmentInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            @strongify(self);
            dispatch_group_enter(group);
            [self p_exportFramesWithFragment:obj publishModel:publishModel awemeId:awemeId completion:^(NSArray *framePaths, NSError *error) {
                [resultPaths addObjectsFromArray:framePaths];
                dispatch_group_leave(group);
            }];
        }];
        
        dispatch_group_notify(group, dispatch_get_global_queue(0, 0), ^{
            if (ACC_isEmptyArray(resultPaths)) {
                [ACCSecurityFramesExporter uploadVideoFallbackTracker:YES invalidFragment:NO publishModel:publishModel];
                [self p_exportFramesWithAssets:publishModel.repoVideoInfo.video.videoAssets
                                     videoData:publishModel.repoVideoInfo.video
                           restrictDurationArr:nil
                                     frameType:ACCSecurityFrameTypeUpload
                                  publishModel:publishModel
                                    completion:completion];
                return;
            }
            [ACCSecurityFramesExporter uploadVideoFallbackTracker:NO invalidFragment:NO publishModel:publishModel];
            ACCBLOCK_INVOKE(completion, resultPaths.copy, nil);
        });
    });
}

+ (ACCSecurityFrameType)p_frameTypeForVideoDataWithPublishModel:(AWEVideoPublishViewModel *)publishModel
{
    AWERepoContextModel *contextModel = [publishModel extensionModelOfClass:[AWERepoContextModel class]];
    
    if (contextModel.videoSource == AWEVideoSourceCapture) {
        return ACCSecurityFrameTypeRecord;
    }
    
    if (contextModel.videoType == AWEVideoTypeImageAlbum) {
        return ACCSecurityFrameTypeImageAlbum;
    }
    
    if (contextModel.isMVVideo || contextModel.isPhoto) {
        return ACCSecurityFrameTypeTemplate;
    }
    
    return ACCSecurityFrameTypeUpload;
}

+ (NSData *)p_extractInputDataFromImage:(UIImage *)image usePNG:(BOOL)usePNG
{
    if(usePNG) {
        return UIImagePNGRepresentation(image);
    } else {
        return UIImageJPEGRepresentation(image, 0.9);
    }
}

+ (void)p_exportFramesWithFragment:(AWEVideoFragmentInfo *)fragmentInfo
                      publishModel:(AWEVideoPublishViewModel *)publishModel
                           awemeId:(NSString *)awemeId
                        completion:(void (^)(NSArray *framePaths, NSError *error))completion
{
    if (fragmentInfo.avAssetURL) {
        if (![[NSFileManager defaultManager] fileExistsAtPath:fragmentInfo.avAssetURL.path]) {
            AWELogToolError(AWELogToolTagSecurity, @"[export] fragmentInfo.avAssetURL = %@, taskId = %@", fragmentInfo.avAssetURL.path, publishModel.repoDraft.taskID);
            [ACCSecurityFramesUtils showACCMonitorAlertWithErrorCode:ACCSecurityFramesErrorInvalidAVASSetURL];
            ACCBLOCK_INVOKE(completion, nil, [ACCSecurityFramesUtils errorWithErrorCode:ACCSecurityFramesErrorInvalidAVASSetURL]);
            return;
        }
        
        NSURL *videoFileURL = [ACCSecurityFramesExporter p_fileURLWithString:fragmentInfo.avAssetURL.path];
        AVURLAsset *avAsset = [AVURLAsset assetWithURL:videoFileURL];
        AVAssetTrack *videoTrack = [avAsset tracksWithMediaType:AVMediaTypeVideo].firstObject;
        
        if (!videoTrack) {
            [ACCSecurityFramesUtils showACCMonitorAlertWithErrorCode:ACCSecurityFramesErrorInvalidAVASSet];
            ACCBLOCK_INVOKE(completion, nil, [ACCSecurityFramesUtils errorWithErrorCode:ACCSecurityFramesErrorInvalidAVASSet]);
            [ACCSecurityFramesExporter accessPathTrackerURL:fragmentInfo.avAssetURL isVideo:YES success:NO publishModel:publishModel];
            return;
        }
        
        [ACCSecurityFramesExporter accessPathTrackerURL:fragmentInfo.avAssetURL isVideo:YES success:YES publishModel:publishModel];
        AWELogToolInfo(AWELogToolTagSecurity, @"[export] video path: %@", videoFileURL);
        ACCSecurityFrameType frameType = [self p_frameTypeForVideoDataWithPublishModel:publishModel];
        UIEdgeInsets insets = UIEdgeInsetsMake(fragmentInfo.frameInsetsModel.top, fragmentInfo.frameInsetsModel.left, fragmentInfo.frameInsetsModel.bottom, fragmentInfo.frameInsetsModel.right);
        CMTimeRange range = kCMTimeRangeZero;
        if (fragmentInfo.clipTimeRange) {
            range = [fragmentInfo.clipTimeRange CMTimeRangeValue];
        }
        
        NSTimeInterval interval = [ACCSecurityFramesUtils uploadFramesInterval];
        
        ACCSecurityExportModel *model = [[ACCSecurityExportModel alloc] init];
        model.asset = avAsset;
        model.frameType = frameType;
        model.insets = insets;
        model.range = range;
        model.timeInterval = interval;
        model.orientation = fragmentInfo.assetOrientation;
        
        [self p_exportFramesWithExportModel:model publishModel:publishModel awemeId:awemeId completion:completion];
                
        return;
    }
    
    if (fragmentInfo.imageAssetURL) {
        NSURL *imageFileURL = [ACCSecurityFramesExporter p_fileURLWithString:fragmentInfo.imageAssetURL.path];
        AWELogToolInfo(AWELogToolTagSecurity, @"[export] export image path: %@", imageFileURL);
        UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:imageFileURL]];
        ACCSecurityFrameType frameType = [self p_frameTypeForVideoDataWithPublishModel:publishModel];
        
        if (!image) {
            NSMutableArray *paths = [[NSMutableArray alloc] init];
            [paths acc_addObject:fragmentInfo.imageAssetURL.path];
            [ACCSecurityFramesExporter accessPathTrackerURL:fragmentInfo.imageAssetURL isVideo:NO success:NO publishModel:publishModel];
            ACCBLOCK_INVOKE(completion, paths.copy, [ACCSecurityFramesUtils errorWithErrorCode:ACCSecurityFramesErrorInvalidImageAsset]);
            return;
        }
        
        [ACCSecurityFramesExporter accessPathTrackerURL:fragmentInfo.imageAssetURL isVideo:NO success:YES publishModel:publishModel];
        
        [ACCSecurityFramesSaver saveImage:image
                                     type:frameType
                                   taskId:publishModel.repoDraft.taskID
                               completion:^(NSString * _Nonnull path, BOOL success, NSError * _Nonnull error) {
            if (success && !ACC_isEmptyString(path)) {
                ACCBLOCK_INVOKE(completion, @[path], nil);
            } else {
                ACCBLOCK_INVOKE(completion, nil, [ACCSecurityFramesUtils errorWithErrorCode:ACCSecurityFramesErrorInvalidImageAsset]);
            }
        }];
        
        return;
    }
    
    if (!ACC_isEmptyArray(fragmentInfo.originalFramesArray)) {
        ACCBLOCK_INVOKE(completion, fragmentInfo.originalFramesArray, nil);
        return;
    }

    AWELogToolError(AWELogToolTagSecurity, @"[export] avAssetURL = nil, imageAssetURL = nil, taskId = %@", publishModel.repoDraft.taskID);
    [ACCSecurityFramesUtils showACCMonitorAlertWithErrorCode:ACCSecurityFramesErrorInvalidFragment];
    ACCBLOCK_INVOKE(completion, nil, [ACCSecurityFramesUtils errorWithErrorCode:ACCSecurityFramesErrorInvalidAVASSetURL]);
}

+ (void)p_exportFramesWithExportModel:(ACCSecurityExportModel *)model
                         publishModel:(AWEVideoPublishViewModel *)publishModel
                              awemeId:(NSString *)awemeId
                           completion:(void (^)(NSArray *framePaths, NSError *error))completion
{
    acc_dispatch_queue_async_safe([self securityExportQueue], ^{
        NSRecursiveLock *addLock = [[NSRecursiveLock alloc] init];
        LVAssetImageGenerator *generator = [[LVAssetImageGenerator alloc] initWithAsset:model.asset size:[ACCSecurityFramesUtils framesResolution]];
        
        NSMutableArray *times = @[].mutableCopy;
        NSMutableArray *resultPaths = @[].mutableCopy;
        
        CMTime start = model.range.start;
        CMTime duration = model.range.duration;
        CMTime end = CMTimeAdd(start, duration);
        
        if (CMTimeRangeEqual(model.range, kCMTimeRangeZero)) {
            start = kCMTimeZero;
            duration = model.asset.duration;
            end = CMTimeAdd(start, duration);
        }
        
        NSTimeInterval interval = model.timeInterval;
        if (ACC_FLOAT_EQUAL_ZERO(interval)) {
            interval = [ACCSecurityFramesUtils uploadFramesInterval];
        }
        CMTimeValue increment = interval * duration.timescale;
        CMTimeValue currentValue = start.value;
        
        do {
            CMTime time = CMTimeMake(currentValue, duration.timescale);
            [times addObject:[NSValue valueWithCMTime:time]];
            currentValue += increment;
        } while (currentValue <= end.value);
        
        dispatch_group_t group = dispatch_group_create();
        for (NSValue *timeValue in times) {
            CMTime time = [timeValue CMTimeValue];
            
            @autoreleasepool {
                // 抽帧
                UIImage *image = [generator generaImageWithEdgeInset:model.insets atTime:time];
                if (!image) {
                    AWELogToolError(AWELogToolTagSecurity, @"[generate] generate image failed at time: %.2f", CMTimeGetSeconds(time));
                    continue;
                }
                
                // 旋转
                if (model.orientation != UIImageOrientationUp) {
                    image = [image acc_rotate:model.orientation];
                }

                // 存储
                dispatch_group_enter(group);
                [ACCSecurityFramesSaver saveImage:image
                                             type:model.frameType
                                           taskId:publishModel.repoDraft.taskID
                                       completion:^(NSString * _Nonnull path, BOOL success, NSError * _Nonnull error) {
                    if (success && !ACC_isEmptyString(path)) {
                        
                        [addLock lock];
                        [resultPaths acc_addObject:path];
                        [addLock unlock];
                    }
                    dispatch_group_leave(group);
                }];
                
            }
        }
        
        dispatch_group_notify(group, dispatch_get_main_queue(), ^{
            ACCBLOCK_INVOKE(completion, resultPaths.copy, nil);
        });
    });
}

+ (void)p_exportFramesWithAssets:(NSArray<AVAsset*>*)videoAssets
                       videoData:(ACCEditVideoData *)videoData
             restrictDurationArr:(NSArray<NSNumber*>*)restrictDurationArr
                       frameType:(ACCSecurityFrameType)frameType
                    publishModel:(AWEVideoPublishViewModel *)publishModel
                      completion:(void (^)(NSArray *framePaths, NSError *error))completion
{
    if (ACC_isEmptyArray(videoAssets) && videoData) {
        videoAssets = videoData.videoAssets;
    }
    
    if (ACC_isEmptyArray(videoAssets)) {
        ACCBLOCK_INVOKE(completion, nil, nil);
        return;
    }
    
    NSAssert(!ACC_isEmptyArray(videoAssets), @"[security frame] invalid video assets");

    NSMutableArray *targetPaths = [NSMutableArray array];
    
    acc_dispatch_queue_async_safe([self securityExportQueue], ^{
        dispatch_group_t group = dispatch_group_create();
        [videoAssets enumerateObjectsUsingBlock:^(AVAsset * _Nonnull asset, NSUInteger idx, BOOL * _Nonnull stop) {
            NSURL *imageUrl = [videoData.photoAssetsInfo objectForKey:asset];
            if (imageUrl) {
                dispatch_group_enter(group);
                UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:imageUrl]];
                [ACCSecurityFramesSaver saveImage:image type:frameType taskId:publishModel.repoDraft.taskID completion:^(NSString * _Nonnull path, BOOL success, NSError * _Nonnull error) {
                    dispatch_group_leave(group);
                    if (!ACC_isEmptyString(path) && success) {
                        [targetPaths acc_addObject:path];
                    }
                }];
                return;
            }
            
            AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
            generator.requestedTimeToleranceAfter = CMTimeMake(1, 10);
            generator.requestedTimeToleranceBefore = CMTimeMake(1, 10);
            generator.maximumSize = [ACCSecurityFramesUtils framesResolution];
            generator.appliesPreferredTrackTransform = YES;
            
            NSMutableArray *times = [NSMutableArray array];
            CMTime duration = asset.duration;
            CMTime startTime = kCMTimeZero;
            
            // 计算截取的起始时间、时长
            if (videoData) {
                CMTimeRange range = [videoData videoTimeClipRangeForAsset:asset];
                CGFloat scale = [[videoData.videoTimeScaleInfo objectForKey:asset] floatValue] > 0 ?: 1;
                
                duration = CMTimeMultiplyByFloat64(range.duration, 1.0 / scale);
                startTime = range.start;
            }
            
            if (restrictDurationArr.count > 0 && idx < restrictDurationArr.count ) {
                duration =  CMTimeMake(restrictDurationArr[idx].integerValue * duration.timescale, duration.timescale);
            }
            CMTime endTime = CMTimeAdd(startTime, duration);
            
            CMTimeValue increment = [ACCSecurityFramesUtils uploadFramesInterval] * duration.timescale ?: 1;
            if (increment <= 0) {
                increment = 1;
            }
            CMTimeValue currentValue = startTime.value;
            
            do {
                CMTime time = CMTimeMake(currentValue, duration.timescale);
                [times addObject:[NSValue valueWithCMTime:time]];
                currentValue += increment;
            } while (currentValue <= endTime.value);

            for (NSValue *timeValue in times) {
                @autoreleasepool {
                    NSError * error;
                    CGImageRef imageRef = [generator copyCGImageAtTime:[timeValue CMTimeValue] actualTime:nil error:&error];
                    if (error) {
                        AWELogToolError(AWELogToolTagSecurity, @"[export] 抽帧失败 %@", error);
                        continue;
                    }

                    if (imageRef == NULL) {
                        AWELogToolError(AWELogToolTagSecurity, @"[export] AVAssetImageGenerator imageRef为空");
                        NSAssert(NO, @"LVAssetImageGenerator imageRef是空的!!");
                        continue;
                    }
                    
                    UIImage *image = [UIImage imageWithCGImage:imageRef];
                    CGImageRelease(imageRef);
                    
                    if (image) {
                        dispatch_group_enter(group);
                        [ACCSecurityFramesSaver saveImage:image type:frameType taskId:publishModel.repoDraft.taskID completion:^(NSString * _Nonnull path, BOOL success, NSError * _Nonnull error) {
                            dispatch_group_leave(group);
                            if (!ACC_isEmptyString(path) && success) {
                                [targetPaths acc_addObject:path];
                            }
                        }];
                    }
                }
            }
        }];
        
        dispatch_group_notify(group, [self securityExportQueue], ^{
            ACCBLOCK_INVOKE(completion, [targetPaths copy], nil);
        });
    });
}

#pragma mark - Utils

+ (BOOL)isInvalideFragmentInfoInModel:(AWEVideoPublishViewModel *)publishModel
{
    __block BOOL flag = NO;
    [publishModel.repoVideoInfo.fragmentInfo enumerateObjectsUsingBlock:^(AWEVideoFragmentInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (!obj.imageAssetURL && !obj.avAssetURL && ACC_isEmptyArray(obj.originalFramesArray)) {
            flag = YES;
            *stop = YES;
        }
    }];
    
    return flag;
}

+ (BOOL)isInvalideFragmentAssetPathInModel:(AWEVideoPublishViewModel *)publishModel
{
    __block BOOL flag = NO;
    [publishModel.repoVideoInfo.fragmentInfo enumerateObjectsUsingBlock:^(AWEVideoFragmentInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        BOOL invalidImagePath = obj.imageAssetURL && ![[NSFileManager defaultManager] fileExistsAtPath:obj.imageAssetURL.path];
        BOOL invalidVideoPath = obj.avAssetURL && ![[NSFileManager defaultManager] fileExistsAtPath:obj.avAssetURL.path];
        if (invalidImagePath || invalidVideoPath) {
            flag = YES;
            *stop = YES;
        }
        
        if (invalidImagePath) {
            AWELogToolError(AWELogToolTagSecurity, @"[export] 图片素材不存在 %@/%@", @(idx+1), @(publishModel.repoVideoInfo.fragmentInfo.count));
        }

        if (invalidVideoPath) {
            AWELogToolError(AWELogToolTagSecurity, @"[export] 视频素材不存在 %@/%@", @(idx+1), @(publishModel.repoVideoInfo.fragmentInfo.count));
        }
    }];
    
    return flag;
}

+ (NSURL *)p_fileURLWithString:(NSString *)URLString
{
    if (ACC_isEmptyString(URLString)) {
        return nil;
    }
    
    NSURL *validUrl = nil;
    if ([URLString.lowercaseString hasPrefix:@"file://"]) {
        validUrl = [NSURL URLWithString:URLString];
    } else {
        validUrl = [NSURL fileURLWithPath:URLString];
    }
    
    return validUrl;
}

+ (void)accessPathTrackerURL:(NSURL *)path isVideo:(BOOL)isVideo success:(BOOL)success publishModel:(AWEVideoPublishViewModel *)publishModel
{
    NSString *contentType = ACCDynamicCast([publishModel.repoTrack.referExtra acc_objectForKey:@"content_type"], NSString);
    
    NSDictionary *params = @{
        @"aweme_type":@(publishModel.repoContext.feedType),
        @"content_type": contentType ?: @"",
        @"task_id":publishModel.repoDraft.taskID ?: @"",
        @"path":path ?: @"",
        @"is_video":@(isVideo),
        @"success":@(success)
    };
    
    [ACCMonitor() trackService:ACCSecurityMonitorAssetPathAccessService status:success extra:params];
}

+ (void)uploadVideoFallbackTracker:(BOOL)isFallBack invalidFragment:(BOOL)invalidFragment publishModel:(AWEVideoPublishViewModel *)publishModel
{
    [ACCSecurityFramesCheck checkExceptionForFallback:isFallBack];
    
    NSString *contentType = ACCDynamicCast([publishModel.repoTrack.referExtra acc_objectForKey:@"content_type"], NSString);
    
    NSDictionary *params = @{
        @"aweme_type":@(publishModel.repoContext.feedType),
        @"content_type": contentType ?: @"",
        @"task_id":publishModel.repoDraft.taskID ?: @"",
        @"is_fallback":@(isFallBack),
        @"invalid_fragment":@(invalidFragment),
    };
    
    [ACCMonitor() trackService:ACCSecurityMonitorFallbackEvent status:isFallBack extra:params];
    [ACCTracker() trackEvent:ACCSecurityMonitorFallbackEvent params:params];
}

@end
