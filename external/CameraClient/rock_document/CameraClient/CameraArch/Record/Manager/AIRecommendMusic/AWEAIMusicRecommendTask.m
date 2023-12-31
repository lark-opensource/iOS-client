//
//  AWEAIMusicRecommendTask.m
//  AWEStudio
//
//  Created by Bytedance on 2019/1/17.
//  Copyright © 2019 Bytedance. All rights reserved.
//

#import "AWEAIMusicRecommendManager.h"
#import <CreationKitArch/AWEVideoPublishViewModel.h>
//#import <CameraClient/ACCBDImageUploadService.h>
//#import <CameraClient/ACCFileUploadServiceBuilder.h>
#import <CreationKitArch/AWEDraftUtils.h>
#import <CameraClient/ACCConfigKeyDefines.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <SSZipArchive/SSZipArchive.h>
#import <CreativeKit/ACCMonitorProtocol.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>

#import <CreativeKit/ACCCacheProtocol.h>
#import <CameraClient/ACCMusicNetServiceProtocol.h>
#import <CreationKitArch/ACCUserServiceProtocol.h>
#import <KVOController/NSObject+FBKVOController.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import <CreationKitArch/ACCRepoDraftModel.h>
#import "AWERepoVideoInfoModel.h"
#import <CameraClient/ACCVideoMusicListResponse.h>
#import <CreationKitArch/ACCRepoUploadInfomationModel.h>
#import <CameraClient/AWERepoMusicModel.h>
#import "AWEEditAlgorithmManager.h"

static NSString * const kAWEAIRecommendRequestMonitorServiceName = @"ies_ai_recommend_request_monitor";
static NSString * const kAWEAIRecommendVideoFramesUploadMonitorServiceName = @"ies_ai_recommend_video_frames_upload_monitor";

typedef NS_ENUM(NSUInteger, AWEAIRecommendRequestMonitorStatus) {
    AWEAIRecommendRequestMonitorStatusSuccess = 0,      // AI配乐获取成功
    AWEAIRecommendRequestMonitorStatusUseServerDefault, // 使用服务端兜底
    AWEAIRecommendRequestMonitorStatusNetworkNotReached // 网络不可达
};

typedef NS_ENUM(NSUInteger, AWEAIRecommendVideoFramesUploadMonitorStatus) {
    AWEAIRecommendVideoFramesUploadMonitorStatusSuccess = 0,      // 成功
    AWEAIRecommendVideoFramesUploadMonitorStatusFailed, // 失败
};

typedef NS_ENUM(NSUInteger, AWERecommendMusicFetchType) {
    AWERecommendMusicFetchTypeDefault,      // 拉兜底的推荐
    AWERecommendMusicFetchTypeAI,           // 上传图片后拉推荐
    AWERecommendMusicFetchTypeLib,          // 曲库推荐
};

@interface AWEAIMusicRecommendTask ()

@property(nonatomic,      copy) NSString *taskIdentifier;
@property(nonatomic, copy) NSArray<NSArray *> *recordFramePahts;
@property(nonatomic, copy) NSArray<NSString *> *imagePathArray;
@property(nonatomic, copy) NSArray<UIImage *> *frameImageInZipArray;
@property(nonatomic,      copy) NSString * framesDirPath;
// 上传SDK
//@property(nonatomic, strong) id<ACCFileUploadServiceProtocol> uploadService;

@property(nonatomic, readwrite) AWEAIMusicFetchType musicFetchType;
@property(nonatomic,      copy) AWEAIMusicRecommendTaskCompletion completion;
@property(nonatomic, readwrite, weak) AWEVideoPublishViewModel *model;
@property(nonatomic, assign) NSInteger count;

@end


@implementation AWEAIMusicRecommendTask

#pragma mark - life cycle

- (void)dealloc {
    [self stopUploadServiceIfNeed];
    AWELogToolDebug(AWELogToolTagEdit|AWELogToolTagAIClip, @"%@ dealloc",[self class]);
}

- (instancetype)initWithIdentifier:(nonnull NSString *)taskIdentifier
                      publishModel:(nullable AWEVideoPublishViewModel *)model
                  recordFramePaths:(nullable NSArray<NSArray *> *)frames
                             count:(NSInteger)count
                          callback:(nullable AWEAIMusicRecommendTaskCompletion)completion {
    self = [super init];
    if (self) {
        _taskIdentifier = taskIdentifier;
        _recordFramePahts = [frames copy];
        _model = model;
        _completion = completion;
        _count = count;
        [self addObservers];
    }
    return self;
}

- (void)addObservers
{
    @weakify(self);
    [self.KVOController observe:IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) keyPath:@"isUserLogin" options:NSKeyValueObservingOptionNew block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
        @strongify(self);
        BOOL isLogin = [change[NSKeyValueChangeNewKey] boolValue];
//        [ACCTracker() trackEvent:@"account_info_cancel_upload_done" params:@{@"is_login" : @(isLogin), @"is_uploading" : @(self.uploadService.isUploading)} needStagingFlag:NO];
        [ACCTracker() trackEvent:@"account_info_cancel_upload_done" params:@{@"is_login" : @(isLogin), @"is_uploading" : @(NO)} needStagingFlag:NO];
//        if (!isLogin && self.uploadService.isUploading) {
//            [self.KVOController unobserve:self.uploadService keyPath:FBKVOClassKeyPath(ACCBDImageUploadService, isUploading)];
//            [self.uploadService stopUploading];
//        }
    }];
}

#pragma mark - public methods

- (void)resume {
    BOOL shouldFetchAIData = [self.class shootTypeSupportWithModel:self.model];
    if (shouldFetchAIData) { // fetch from ailab
        if ([self.recordFramePahts count] || self.originFramesPathArray.count) {//resize ,save to disk and then zip & upload
            @weakify(self)
            [self saveImagesWithCompletion:^{
                NSArray *frameImageInZipArray = [self.frameImageInZipArray copy];
                if ([[AWEEditAlgorithmManager sharedManager] useBachToRecommend]) {
                    @strongify(self)
                    [[AWEEditAlgorithmManager sharedManager] runAlgorithmOfType:ACCEditImageAlgorithmTypeSmartSoundTrack withImagePaths:self.imagePathArray completion:^(NSArray<NSNumber *> *result, NSError *error) {
                        if (!result || error) {
                            ACC_LogError(@"Failed to run algorithm for error: %@", error);
                            ACCBLOCK_INVOKE(self.completion, nil, AWEAIRecommendStrategyBachVector, nil, nil, [AWEAIMusicRecommendTask errorOfAIRecommend]);
                            return ;
                        }
                        NSString *musicResultFile = [self.model.repoDraft.draftFolder stringByAppendingPathComponent:@"bach_smart_soundtrack.bin"];
                        if ([[NSFileManager defaultManager] fileExistsAtPath:musicResultFile]) {
                            [[NSFileManager defaultManager] removeItemAtPath:musicResultFile error:NULL];
                        }
                        BOOL success = [self saveResult:result toFile:musicResultFile];
                        if (!success) {
                            ACC_LogError(@"Failed to save bach resut");
                            ACCBLOCK_INVOKE(self.completion, nil, AWEAIRecommendStrategyBachVector, nil, nil, [AWEAIMusicRecommendTask errorOfAIRecommend]);
                        } else {
                            [[AWEEditAlgorithmManager sharedManager] runAlgorithmOfType:ACCEditImageAlgorithmTypeSmartHashtag withImagePaths:self.imagePathArray completion:^(NSArray<NSNumber *> *result, NSError *error) {
                                if (!result || error) {
                                    ACC_LogError(@"Failed to run algorithm for error: %@", error);
                                    ACCBLOCK_INVOKE(self.completion, nil, AWEAIRecommendStrategyBachVector, nil, nil, [AWEAIMusicRecommendTask errorOfAIRecommend]);
                                    return;
                                }
                                @strongify(self)
                                NSString *hashtagResultFile = [self.model.repoDraft.draftFolder stringByAppendingPathComponent:@"bach_hashtag.bin"];
                                if ([[NSFileManager defaultManager] fileExistsAtPath:hashtagResultFile]) {
                                    [[NSFileManager defaultManager] removeItemAtPath:hashtagResultFile error:NULL];
                                }
                                BOOL success = [self saveResult:result toFile:hashtagResultFile];
                                if (success) {
                                    NSArray *filePaths = @[musicResultFile, hashtagResultFile];
                                    NSString *zipPath = [self.model.repoDraft.draftFolder stringByAppendingPathComponent:@"bach_result.zip"];
                                    [SSZipArchive createZipFileAtPath:zipPath withFilesAtPaths:filePaths];
                                    [self uploadZipWithUrl:[NSURL fileURLWithPath:zipPath] callback:^(NSString *zipId, NSString *firstFrameId, NSError *error) {
                                        @strongify(self)
                                        if (error) {
                                            ACC_LogError(@"Failed to upload zip for error: %@", error);
                                        }
                                        self.model.repoMusic.binURI = zipId;
                                        ACCBLOCK_INVOKE(self.completion, self.model.repoMusic.binURI, AWEAIRecommendStrategyBachVector, nil, frameImageInZipArray, nil);
                                    }];
                                } else {
                                    ACC_LogError(@"Failed to save bach resut");
                                    ACCBLOCK_INVOKE(self.completion, nil, AWEAIRecommendStrategyBachVector, nil, nil, [AWEAIMusicRecommendTask errorOfAIRecommend]);
                                }
                            }];
                        }
                    }];
                }
                if ([AWEEditAlgorithmManager sharedManager].recommendStrategy & AWEAIRecommendStrategyUploadFrames) {
                    @strongify(self)
                    [self createZipWithCompletion:^(NSString *zipPath) {
                        if (zipPath.length) {
                            CFTimeInterval uploadStart = CFAbsoluteTimeGetCurrent();
                            @weakify(self)
                            [self uploadZipWithUrl:[NSURL fileURLWithPath:zipPath] callback:^(NSString *zipId, NSString *firstFrameId, NSError *error) {
                                @strongify(self);
                                if (!ACC_isEmptyString(zipId)) {
                                    [self p_fetchDataFinishedAndReset];
                                }
                                self.model.repoMusic.zipURI = zipId;
                                ACCBLOCK_INVOKE(self.completion, self.model.repoMusic.zipURI, AWEAIRecommendStrategyUploadFrames, firstFrameId, frameImageInZipArray, error);
                                NSUInteger uploadDiffInMS = (CFAbsoluteTimeGetCurrent() - uploadStart) * 1000;
                                NSMutableDictionary *params = @{ @"time_cost_ms": @(uploadDiffInMS) }.mutableCopy;
                                if (self.model.repoContext.videoType == AWEVideoTypePhotoToVideo) {
                                    params[@"photo_to_video_assets_count"] = @([self p_assetsCount]);
                                }
                                [ACCMonitor() trackService:kAWEAIRecommendVideoFramesUploadMonitorServiceName
                                                    status:zipId ? AWEAIRecommendVideoFramesUploadMonitorStatusSuccess : AWEAIRecommendVideoFramesUploadMonitorStatusFailed
                                                     extra:zipId ? params.copy : @{}];
                            }];
                        } else { 
                            ACCBLOCK_INVOKE(self.completion, self.model.repoMusic.zipURI, AWEAIRecommendStrategyUploadFrames, nil, frameImageInZipArray, nil);
                        }
                    }];
                } else {
                    ACCBLOCK_INVOKE(self.completion, nil, AWEAIRecommendStrategyUploadFrames, nil, nil, [AWEAIMusicRecommendTask errorOfAIRecommend]);
                }
            }];
            return;
        }
    } else {
        ACCBLOCK_INVOKE(self.completion, nil, AWEAIRecommendStrategyUploadFrames, nil, nil, [AWEAIMusicRecommendTask errorOfAIRecommend]);
    }
}

- (BOOL)saveResult:(NSArray<NSNumber *> *)result toFile:(NSString *)file
{
    size_t size = sizeof(float) * [result count];
    float *resultAray = malloc(size);
    for (NSInteger index = 0; index < [result count]; index++) {
        resultAray[index] = [result[index] floatValue];
    }
    
    FILE *f = fopen([file UTF8String],"wb");
    if (f != NULL) {
        size_t res = fwrite(resultAray, size, 1, f);
        fclose(f);
        free(resultAray);
        return res > 0;
    } else {
        free(resultAray);
        return NO;
    }
}

- (void)fetchAIMusicListWithURI:(NSString *)zipURI otherParam:(nullable NSDictionary *)param callback:(AWEAIMusicRecommendTaskFetchCompletion)completion
{
    @weakify(self);
    //block-fetch settings data
    void(^fetchDefaultData)(NSNumber *originalHasMore, NSNumber *originalCursor, NSError * _Nullable originalError) = ^(NSNumber *originalHasMore, NSNumber *originalCursor, NSError * _Nullable originalError) {
        @strongify(self);
        [self p_fetchAIRecommendData:AWERecommendMusicFetchTypeDefault zipURI:nil count:self.count otherParam:param callback:^(NSArray<id<ACCMusicModelProtocol>> * _Nullable musicList, NSNumber *hasMore, NSNumber *cursor, NSString * _Nullable requestID, NSError * _Nullable error) {
            @strongify(self);
            if (!error && [musicList count]) {
                self.musicFetchType = AWEAIMusicFetchTypeSettings;
            } else {
                self.musicFetchType = AWEAIMusicFetchTypeNone;
            }
            
            [self p_fetchDataFinishedAndReset];
            // 获取AI配乐兜底音乐列表
            ACCBLOCK_INVOKE(completion, self.musicFetchType, nil, musicList,  originalHasMore, originalCursor, originalError);
        }];
    };
    
    [ACCTracker() trackEvent:@"account_info_before_rec_music_list" params:@{@"is_login" : @([IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) isLogin])} needStagingFlag:NO];
    if ([IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) isLogin] && zipURI) {
        CFTimeInterval start = CFAbsoluteTimeGetCurrent();
        @strongify(self);
        [self p_fetchAIRecommendData:AWERecommendMusicFetchTypeAI zipURI:zipURI count:self.count otherParam:param callback:^(NSArray<id<ACCMusicModelProtocol>> * _Nullable musicList, NSNumber *hasMore, NSNumber *cursor, NSString * _Nullable requestID, NSError * _Nullable error) {
            @strongify(self);
            if (!error && [musicList count]) {
                [self p_fetchDataFinishedAndReset];
                ACCBLOCK_INVOKE(completion, self.musicFetchType, requestID, musicList,  hasMore, cursor, error);
                
                CFTimeInterval end = CFAbsoluteTimeGetCurrent();
                NSUInteger diffInMS = (end - start) * 1000;
                NSMutableDictionary *params = @{ @"time_cost_ms": @(diffInMS) }.mutableCopy;
                if (self.model.repoContext.videoType == AWEVideoTypePhotoToVideo) {
                    params[@"photo_to_video_assets_count"] = @([self p_assetsCount]);
                }
                [ACCMonitor() trackService:kAWEAIRecommendRequestMonitorServiceName
                                    status:AWEAIRecommendRequestMonitorStatusSuccess
                                     extra:params.copy];
            } else {
                // AI 配乐请求失败率上报参数：错误码，错误信息，logID(服务端排查问题)
                NSDictionary *params = @{
                    @"errorCode": @(error.code),
                    @"errorDescription":error ?: @"",
                    @"trace_id":requestID ?: @"",
                };
                AWEAIRecommendRequestMonitorStatus status = (error.code == 0) ? AWEAIRecommendRequestMonitorStatusUseServerDefault : AWEAIRecommendRequestMonitorStatusNetworkNotReached;
                [ACCMonitor() trackService:kAWEAIRecommendRequestMonitorServiceName
                                                status:status
                                                 extra:params];
                ACCBLOCK_INVOKE(fetchDefaultData, hasMore, cursor, error); //recommend接口已经做了兜底-拿不到AI就拿曲库，不需要客户端再兜底
            }
        }];
    } else {
        // fetch music lib data
        @strongify(self);
        [self p_fetchAIRecommendData:AWERecommendMusicFetchTypeLib zipURI:nil count:self.count otherParam:param  callback:^(NSArray<id<ACCMusicModelProtocol>> * _Nullable musicList, NSNumber *hasMore, NSNumber *cursor, NSString * _Nullable requestID, NSError * _Nullable error) {
            @strongify(self);
            if (!error && [musicList count]) {
                self.musicFetchType = AWEAIMusicFetchTypeLib;
                
                [self p_fetchDataFinishedAndReset];
                ACCBLOCK_INVOKE(completion, self.musicFetchType, requestID, musicList,  hasMore, cursor, error);
            } else {
                ACCBLOCK_INVOKE(fetchDefaultData, hasMore, cursor, error); //settings data
            }
        }];
    }
}

#pragma mark - upload methods

- (void)saveImagesWithCompletion:(void (^)(void))completion
{
    if ([self useOriginFramesPathArray]) {
        ACCBLOCK_INVOKE(completion);
        return;
    }
    if (![self.recordFramePahts count]) {
        ACCBLOCK_INVOKE(completion);
        return;
    }
    
    //put all image in an array
    NSMutableArray *imagePathArray = [NSMutableArray array];
    [self.recordFramePahts enumerateObjectsUsingBlock:^(NSArray * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj enumerateObjectsUsingBlock:^(NSString *  _Nonnull path, NSUInteger idx_inner, BOOL * _Nonnull stop_inner) {
            if ([path isKindOfClass:[NSString class]]) {
                if ([path containsString:self.model.repoDraft.taskID]) {
                    [imagePathArray acc_addObject:path];
                } else {
                    path = [AWEDraftUtils absolutePathFrom:path taskID:self.model.repoDraft.taskID];
                    [imagePathArray acc_addObject:path];
                }
            }
        }];
    }];
    
    NSArray *uploadImageArray = [self extractionUploadArray:imagePathArray];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray *frameImageInZipArray = [NSMutableArray array];
        NSMutableArray *resultImagePathArray = [NSMutableArray array];
        [uploadImageArray enumerateObjectsUsingBlock:^(NSString *  _Nonnull path, NSUInteger idx, BOOL * _Nonnull stop) {
            @autoreleasepool {
                if ([path isKindOfClass:[NSString class]] &&
                    [[NSFileManager defaultManager] fileExistsAtPath:path]) {
                    NSData *data = [NSData dataWithContentsOfFile:path];
                    UIImage *image = [UIImage imageWithData:data];
                    if (image) {
                        [resultImagePathArray acc_addObject:path];
                        [frameImageInZipArray acc_addObject:image];
                    }
                }
            }
        }];
        acc_dispatch_main_async_safe(^{
            self.imagePathArray = imagePathArray;
            self.frameImageInZipArray = frameImageInZipArray;
            ACCBLOCK_INVOKE(completion);
        });
    });
}

- (BOOL)useOriginFramesPathArray
{
    if (!self.originFramesPathArray.count) {
        return NO;
    }

    NSMutableArray *imagePathArray = [NSMutableArray array];
    NSMutableArray *frameImageInZipArray = [NSMutableArray array];
    NSString *framesDirPath = [AWEDraftUtils generateDraftFolderFromTaskId:self.model.repoDraft.taskID];
    NSArray *uploadFramsPathArray = [self extractionUploadArray:self.originFramesPathArray];
    [uploadFramsPathArray enumerateObjectsUsingBlock:^(NSString * _Nonnull name, NSUInteger idx, BOOL * _Nonnull stop) {
        if (!([name hasSuffix:@".jpeg"] ||
              [name hasSuffix:@".jpg"] ||
              [name hasSuffix:@".png"] ||
              [name hasSuffix:@".bmp"])) {
            name = [NSString stringWithFormat:@"%@.jpeg", name];
        }
        NSString *imagePath = [framesDirPath stringByAppendingPathComponent:name];
        if (imagePath) {
            [imagePathArray addObject:imagePath];
        }
        
        @autoreleasepool {
            if ([imagePath isKindOfClass:[NSString class]] &&
                [[NSFileManager defaultManager] fileExistsAtPath:imagePath]) {
                NSData *data = [NSData dataWithContentsOfFile:imagePath];
                UIImage *image = [UIImage imageWithData:data];
                if (image) {
                    [frameImageInZipArray acc_addObject:image];
                }
            }
        }
    }];
    self.imagePathArray = imagePathArray;
    self.frameImageInZipArray = [frameImageInZipArray copy];

    return [self.imagePathArray count] > 0;
}

- (NSArray *)extractionUploadArray:(NSArray *)originArray;
{
    NSMutableArray *resultArray = [NSMutableArray array];
    if (([originArray count] > [AWEAIMusicRecommendManager sharedInstance].maxNumForUpload) &&
        ([AWEAIMusicRecommendManager sharedInstance].maxNumForUpload > 2)) {
        [resultArray addObject:[originArray firstObject]];//first
        
        NSInteger needAmount = [AWEAIMusicRecommendManager sharedInstance].maxNumForUpload - 2;
        NSInteger step = needAmount + 1;
        NSInteger gap = (NSInteger)([originArray count] / step);
        for (NSInteger i = 1; i < step; i++) {
            NSInteger idx = i * gap;
            if ([originArray acc_objectAtIndex:idx]) {
                [resultArray addObject:[originArray acc_objectAtIndex:idx]];
            }
        }
        
        [resultArray addObject:[originArray lastObject]];//last
        return resultArray.copy;
    } else {
        return originArray;
    }
}

- (void)createZipWithCompletion:(void (^)(NSString *path))completion
{
    NSArray *imagePathArray = [self.imagePathArray copy];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *path = [NSString stringWithFormat:@"%ld_ai_frames.zip", (long)CFAbsoluteTimeGetCurrent()];
        NSString *zipPath = [self.framesDirPath stringByAppendingPathComponent:path];
        BOOL success = NO;
        if (imagePathArray.count) {
            success = [SSZipArchive createZipFileAtPath:zipPath withFilesAtPaths:imagePathArray];
        }
        acc_dispatch_main_async_safe(^{
            ACCBLOCK_INVOKE(completion, success ? zipPath : nil);
        });
    });
}

- (void)uploadZipWithUrl:(NSURL *)zipUrl callback:(void(^)(NSString *zipId, NSString *firstFrameId, NSError *error))callback
{
    @weakify(self);
    [ACCTracker() trackEvent:@"account_info_before_auth" params:@{@"is_login" : @([IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) isLogin])} needStagingFlag:NO];
    [IESAutoInline(ACCBaseServiceProvider(), ACCMusicNetServiceProtocol) fetchAIFramesUploadAuthkeyWithCallback:^(AWEResourceUploadParametersResponseModel * _Nullable response, NSError * _Nullable error) {
        @strongify(self);
        NSMutableDictionary *params = @{}.mutableCopy;
        params[@"is_login"] = @([IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) isLogin]);
        params[@"authkey_res_status"] = error ? @(0) : @(1);
        params[@"errorCode"] = error ? @(error.code) : @(0);
        params[@"errorDesc"] = error.localizedDescription ? : @"";
        if (error) {
            AWELogToolError(AWELogToolTagEdit|AWELogToolTagAIClip, @"fetchAIFramesUploadAuthKey error: %@", error);
        }
        [ACCTracker() trackEvent:@"account_info_after_auth" params:params.copy needStagingFlag:NO];
//        if (!error && response.frameUploadParameters) {
//            ACCFileUploadServiceBuilder *uploadBuilder= [[ACCFileUploadServiceBuilder alloc] init];
//            self.uploadService = [uploadBuilder createUploadServiceWithParams:response filePaths:@[[zipUrl path]]];
//            [self.KVOController observe:self.uploadService keyPath:FBKVOClassKeyPath(ACCBDImageUploadService, isUploading) options:NSKeyValueObservingOptionNew block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
//                @strongify(self);
//                BOOL isUploading = [change[NSKeyValueChangeNewKey] boolValue];
//                [ACCTracker() trackEvent:@"account_info_cancel_upload_done" params:@{@"is_login" : @([IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) isLogin]), @"is_uploading" : @(isUploading)} needStagingFlag:NO];
//                if (isUploading && ![IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) isLogin]) {
//                    [self.KVOController unobserve:self.uploadService keyPath:FBKVOClassKeyPath(ACCBDImageUploadService, isUploading)];
//                    [self.uploadService stopUploading];
//                }
//            }];
//
//            BOOL isAuthExist = response.frameUploadParameters.authorization2;
//            if (response.frameUploadParameters.appKey && isAuthExist) {
//                NSProgress *progress = nil;
//                [ACCTracker() trackEvent:@"account_info_before_zip_upload" params:@{@"is_login" : @([IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) isLogin])} needStagingFlag:NO];
//                if ([IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) isLogin]) {
//                    [self.uploadService uploadFileWithProgress:&progress completion:^(ACCFileUploadResponseInfoModel *uploadInfoModel, NSError *error) {
//                        NSMutableDictionary *params = @{}.mutableCopy;
//                        params[@"is_login"] = @([IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) isLogin]);
//                        params[@"zip_upload_res_status"] = error ? @(0) : @(1);
//                        params[@"errorCode"] = error ? @(error.code) : @(0);
//                        params[@"errorDesc"] = error.localizedDescription ? : @"";
//                        params[@"zipuri"] = uploadInfoModel.materialId ? : @"";
//                        [ACCTracker() trackEvent:@"account_info_after_zip_upload" params:params.copy needStagingFlag:NO];
//                        AWELogToolInfo(AWELogToolTagEdit|AWELogToolTagAIClip, @"zip url is tosv.byted.org/obj/%@",uploadInfoModel.materialId);
//                        if (error) {
//                            AWELogToolWarn(AWELogToolTagMusic, @"Upload zip error: %@", error);
//                        }
//                        ACCBLOCK_INVOKE(callback, uploadInfoModel.materialId, nil, error);
//                    }];
//                } else {
//                    AWELogToolWarn(AWELogToolTagMusic, @"Upload cancelled for logout");
//                    ACCBLOCK_INVOKE(callback, nil, nil, [self.class errorOfAIRecommend]);
//                }
//
//            } else {
//                ACCBLOCK_INVOKE(callback, nil, nil, [self.class errorOfAIRecommend]);
//            }
//        } else {
            ACCBLOCK_INVOKE(callback, nil, nil, [self.class errorOfAIRecommend]);
//        }
    }];
}

- (NSString *)framesDirPath
{
    if (!_framesDirPath) {
        _framesDirPath = [AWEDraftUtils generateDraftFolderFromTaskId:[[AWEDraftUtils generateTaskID] stringByAppendingString:[[NSUUID UUID] UUIDString]]];
    }
    return _framesDirPath;
}

- (void)stopUploadServiceIfNeed
{
//    if (self.uploadService.isUploading) {
//        [self.uploadService stopUploading];
//        AWELogToolInfo(AWELogToolTagEdit, @"Upload service cancelled by dealloc");
//    }
}

#pragma mark - fetch mathods

- (void)p_fetchAIRecommendData:(AWERecommendMusicFetchType)type
                       zipURI:(NSString *)uri
                        count:(NSInteger)count
                    otherParam:(NSDictionary *)parma
                     callback:(void(^)(NSArray<id<ACCMusicModelProtocol>> * _Nullable musicList, NSNumber *hasMore, NSNumber *cursor, NSString * _Nullable requestID, NSError * _Nullable error))completion {
    if (type == AWERecommendMusicFetchTypeDefault) {
        //read cache
        NSString *cached_uri = [ACCCache() objectForKey:kAWEAIMusicRecommendCacheURIKey];
        NSString *settings_music_uri = ACCConfigString(kConfigString_ai_recommend_music_list_default_uri);
        if (!ACC_isEmptyString(cached_uri) && !ACC_isEmptyString(settings_music_uri) && [cached_uri isEqualToString:settings_music_uri]) {
            NSArray<id<ACCMusicModelProtocol>> * cachedList = [IESAutoInline(ACCBaseServiceProvider(), ACCMusicNetServiceProtocol) fetchCachedMusicListWithCacheKey:kAWEAIMusicRecommendDefaultMusicCacheKey];
            if ([cachedList count]) {
                ACCBLOCK_INVOKE(completion,cachedList, @(NO), @(0), nil, nil);
                return;
            }
        }
        
        //save cache
        if ([settings_music_uri length]) {
            [ACCCache() setObject:settings_music_uri forKey:kAWEAIMusicRecommendCacheURIKey];
        }
        
        //fetch default music list from tos
        NSArray * tos_list = ACCConfigArray(kConfigArray_ai_recommend_music_list_default_url_lists);
        [[AWEAIMusicRecommendManager sharedInstance] fetchDefaultMusicListFromTOSWithURLGoup:tos_list callback:^(NSArray<id<ACCMusicModelProtocol>> * _Nullable musicList, NSError * _Nullable error) {
            ACCBLOCK_INVOKE(completion, musicList, @(NO), @(0), nil, error);
        }];
        
    } else {
        NSMutableDictionary *params = nil;
        if (parma) {
            params = [parma mutableCopy];
        } else {
            params = [NSMutableDictionary dictionary];
        }
        params[@"creation_id"] = self.model.repoContext.createId;
        params[@"video_duration"] = @((int64_t)([self.model.repoVideoInfo.video totalVideoDuration] * 1000)); // 单位毫秒
        
        if ([uri isKindOfClass:[NSString class]]) {
           if ([uri length]) {
               if ([AWEEditAlgorithmManager sharedManager].useBachToRecommend) {
                   params[@"lab_extra"] = [@{@"embedding_uri" : uri} acc_dictionaryToJson];
               } else {
                   params[@"zip_uri"] = uri;
               }
           }
        }
        [IESAutoInline(ACCBaseServiceProvider(), ACCMusicNetServiceProtocol) requestAIRecommendMusicListWithZipURI:uri count:@(count > 0? count:10) otherParams:params completion:^(ACCVideoMusicListResponse *_Nullable response, NSError * _Nullable error) {
            if (type == AWERecommendMusicFetchTypeAI) {//接口下发是拿的AI推荐还是曲库
                 if ([response.musicType intValue] <= (NSInteger)AWEAIMusicFetchTypeLib) {
                     self.musicFetchType = (AWEAIMusicFetchType)(ABS([response.musicType intValue]));
                 } else {
                     self.musicFetchType = AWEAIMusicFetchTypeAI;
                 }
             }
             ACCBLOCK_INVOKE(completion, response.musicList, response.hasMore, response.cursor, response.requestID, error);
        }];
    }
}

#pragma mark - class methods

+ (BOOL)shootTypeSupportWithModel:(nullable AWEVideoPublishViewModel *)model {
    if (!model) {
        return NO;
    }
    return YES;
}

+ (BOOL)shootTypeSupportWithReferString:(nullable NSString *)referString {
    if (!referString) {
        return NO;
    }
    return YES;
}

+ (NSError *)errorOfAIRecommend {
    return [NSError errorWithDomain:@"com.aweme.aiMusicRecommend" code:-1 userInfo:nil];
}

#pragma mark - private methods

- (void)p_fetchDataFinishedAndReset {
    if (self.framesDirPath) {
        [[NSFileManager defaultManager] removeItemAtPath:self.framesDirPath error:nil];
    }
    self.recordFramePahts = nil;
    self.originFramesPathArray = nil;
    self.imagePathArray = nil;
    self.frameImageInZipArray = nil;
//    self.uploadService = nil;
}

- (NSUInteger)p_assetsCount
{
    return self.model.repoUploadInfo.selectedUploadAssets.count;
}

@end
