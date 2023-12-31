//
//  AWEAIMusicRecommendManager.m
//  AWEStudio
//
//  Created by Bytedance on 2019/1/9.
//  Copyright © 2019 Bytedance. All rights reserved.
//

#import "AWERepoPublishConfigModel.h"
#import "AWERepoContextModel.h"
#import "AWEAIMusicRecommendManager.h"
#import <CreationKitArch/ACCVideoConfigProtocol.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CameraClient/ACCMusicNetServiceProtocol.h>
#import "ACCConfigKeyDefines.h"
#import <CameraClient/AWEAssetModel.h>
#import <CreationKitArch/ACCRecordInformationRepoModel.h>
#import "ACCCommerceServiceProtocol.h"
#import "AWERepoCommercialAnchorModelCameraClient.h"
#import "AWERepoVideoInfoModel.h"
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreativeKit/ACCCacheProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/ACCAPMProtocol.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import "ACCAICoverNetServiceProtocol.h"
#import <CreationKitArch/AWEVideoImageGenerator.h>
#import <CreativeKit/ACCMonitorProtocol.h>
#import "ACCRepoImageAlbumInfoModel.h"
#import "ACCImageAlbumEditImageInputInfo.h"
#import "AWERepoMusicModel.h"
#import <CreationKitArch/ACCRepoDraftModel.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CreationKitArch/ACCRepoDuetModel.h>
#import <CreationKitArch/ACCRepoUploadInfomationModel.h>
#import "ACCSecurityFramesSaver.h"
#import <CreationKitArch/ACCPublishMusicTrackModel.h>
#import "AWERepoVideoInfoModel.h"
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import <CreationKitInfra/ACCLogProtocol.h>

NSString *const kAWEAIMusicRecommendCacheURIKey     = @"kAWEAIMusicRecommendCacheURIKey";
NSString *const kAWEAIHashtagRecommendCacheURIKey     = @"kAWEAIHashtagRecommendCacheURIKey";

@interface AWEAIMusicRecommendManager ()

@property(nonatomic, readwrite) NSMutableArray<NSArray *> *recordFramePahts;
@property(nonatomic, copy) NSArray<NSString *> *originFramesPathArray;
@property(nonatomic, readwrite) NSInteger maxNumForUpload;
@property(nonatomic, readwrite) NSInteger frameSizeForUpload;
@property(nonatomic, readwrite) AWEAIRecordFrameType recordFrameType;
@property(nonatomic,    strong) AWEAIMusicRecommendTask *currentTask;
@property(nonatomic,      copy) NSArray<id<ACCMusicModelProtocol>> *recommedMusicList;
@property (nonatomic, assign, readwrite) BOOL usedAIRecommendDefaultMusicList; // 是否正在使用兜底的推荐音乐

@property(nonatomic, readwrite) BOOL isRequesting;
@property(nonatomic, readwrite) NSString *requestID;

/// for tracker
@property(nonatomic, readwrite) AWEAIMusicFetchType musicFetchType;
@property(nonatomic,      copy) NSString *enterFrom;
@property(nonatomic, readwrite) NSTimeInterval startFetchTime;


//针对同一个视频从视频编辑回到拍摄（maybe 拍摄多段）再回视频编辑
@property(nonatomic,      copy) NSString * lastCreateId;
@property(nonatomic, readwrite) NSMutableArray *lastAssetsDurationArray;
@property (nonatomic, copy) NSArray<AWEAssetModel *> *lastSelectedAssets;
//上传视频返回编辑再回来
@property(nonatomic, readwrite) NSInteger lastClipRotateType;
@property(nonatomic, readwrite) CMTimeRange lastClipRange;

@property (nonatomic, strong) id<ACCVideoConfigProtocol> videoConfig;

@property (nonatomic, strong) AWEVideoImageGenerator *imageGenerator;
@property (nonatomic, copy) NSArray<NSNumber *> *timeArray;

@end


@implementation AWEAIMusicRecommendManager
IESAutoInject(ACCBaseServiceProvider(), videoConfig, ACCVideoConfigProtocol)

#pragma mark - life cycle

+ (instancetype)sharedInstance {
    static AWEAIMusicRecommendManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[AWEAIMusicRecommendManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _maxNumForUpload = ACCConfigBool(kConfigBool_upload_three_frames) ? 3 : 5;
        _frameSizeForUpload = 256;
        _recordFramePahts = [NSMutableArray array];
        _lastAssetsDurationArray = [NSMutableArray array];

        [self p_fetchAIRecommendDefaultData];
    }
    return self;
}

#pragma mark - public methods

- (BOOL)serviceOnWithModel:(nullable AWEVideoPublishViewModel *)model {
    self.enterFrom = model.repoTrack.enterFrom;
    return [AWEAIMusicRecommendTask shootTypeSupportWithModel:model];
}

- (BOOL)serviceOnWithEnterFrom:(nullable NSString *)enterFrom referString:(nullable NSString *)referString {
    self.enterFrom = enterFrom;
    return [AWEAIMusicRecommendTask shootTypeSupportWithReferString:referString];
}

- (void)setFrameRecordType:(AWEAIRecordFrameType)frameType {
    self.recordFrameType = frameType;
}

- (void)updateClipVideoStatusWithModel:(nullable AWEVideoPublishViewModel *)model
                            rotateType:(NSInteger)rotateType
                                 range:(CMTimeRange)clipRange {
    self.clipVideoModified = NO;
    if ((self.lastCreateId && [self.lastCreateId isEqualToString:model.repoContext.createId]) &&
        ([model.repoVideoInfo.video.videoAssets count] == [self.lastAssetsDurationArray count])) {
        if (self.lastClipRotateType != rotateType) {
            self.clipVideoModified = YES;
        } else if (CMTIMERANGE_IS_VALID(self.lastClipRange) && CMTIMERANGE_IS_VALID(clipRange)) {
            NSTimeInterval startTime = CMTimeGetSeconds(self.lastClipRange.start);
            NSTimeInterval endTime = startTime + CMTimeGetSeconds(self.lastClipRange.duration);
            NSTimeInterval startTime_new = CMTimeGetSeconds(clipRange.start);
            NSTimeInterval endTime_new = startTime + CMTimeGetSeconds(clipRange.duration);
            if ((!ACC_FLOAT_EQUAL_TO(startTime,startTime_new) || !ACC_FLOAT_EQUAL_TO(endTime,endTime_new))) {
                self.clipVideoModified = YES;
            }
        }
    }

    self.lastClipRange = clipRange;
    self.lastClipRotateType = rotateType;
}

- (void)updateClipVideoStatusWithVideo:(ACCEditVideoData *)video
                              createId:(NSString *)createId
                            rotateType:(NSInteger)rotateType
                                 range:(CMTimeRange)clipRange {
    self.clipVideoModified = NO;
    if ((self.lastCreateId && [self.lastCreateId isEqualToString:createId]) &&
        ([video.videoAssets count] == [self.lastAssetsDurationArray count])) {
        if (self.lastClipRotateType != rotateType) {
            self.clipVideoModified = YES;
        } else if (CMTIMERANGE_IS_VALID(self.lastClipRange) && CMTIMERANGE_IS_VALID(clipRange)) {
            NSTimeInterval startTime = CMTimeGetSeconds(self.lastClipRange.start);
            NSTimeInterval endTime = startTime + CMTimeGetSeconds(self.lastClipRange.duration);
            NSTimeInterval startTime_new = CMTimeGetSeconds(clipRange.start);
            NSTimeInterval endTime_new = startTime + CMTimeGetSeconds(clipRange.duration);
            if ((!ACC_FLOAT_EQUAL_TO(startTime,startTime_new) || !ACC_FLOAT_EQUAL_TO(endTime,endTime_new))) {
                self.clipVideoModified = YES;
            }
        }
    }

    self.lastClipRange = clipRange;
    self.lastClipRotateType = rotateType;
}

- (void)appendFramePaths:(nullable NSArray<NSString *> *)framePaths {
    if (![framePaths count]) {
        return;
    }
    [self.recordFramePahts acc_addObject:[framePaths copy]];
}

+ (NSString * _Nullable)recommendedBachZipUriWithPublishViewModel:(AWEVideoPublishViewModel * _Nonnull)model {
    // 是否使用bach本地模型推荐uri
    BOOL useBachToRecommend = [AWEEditAlgorithmManager sharedManager].useBachToRecommend;
    NSString *binURI = model.repoMusic.binURI;
    NSString *zipURI = model.repoMusic.zipURI;
    if (useBachToRecommend && !ACC_isEmptyString(binURI)) {
        return binURI;
    }
    if (ACC_isEmptyString(zipURI)) {
        AWELogToolError2(@"frame", AWELogToolTagEdit, @"recommend zip url is null.");
    }
    return zipURI;
}

- (void)startFetchFramsAndUploadWithPublishModel:(AWEVideoPublishViewModel *)model callback:(nullable AWEAIMusicURIFetchCompletion)completion
{
    //1.not support
    if (!model || model.repoDuet.isDuet) {//isDuet-合拍
        self.recommedMusicList = [NSArray array];
        self.musicFetchType = AWEAIMusicFetchTypeNone;
        self.isRequesting = NO;
        [self p_reset];
        ACCBLOCK_INVOKE(completion,nil, AWEAIRecommendStrategyNone, NO,[AWEAIMusicRecommendTask errorOfAIRecommend]);
        return;
    }

    //2.support
    if (model.repoContext.videoType == AWEVideoTypePhotoToVideo || model.repoContext.videoType == AWEVideoTypeImageAlbum || model.repoContext.feedType == ACCFeedTypeAIMusicVideo || model.repoContext.videoType == AWEVideoTypeMV) {
        /**
         * 图集模式：使用默认的最大5张图片的限制
         * 照片电影：根据上传图片的个数限制抽帧上传图片个数减少上传包大小，单张照片上传也是使用照片电影
         */
        self.maxNumForUpload = 5;
        if (model.repoContext.videoType == AWEVideoTypePhotoToVideo && ACCConfigBool(kConfigBool_enable_improve_frame_count)) {
            NSInteger maxCount = model.repoUploadInfo.selectedUploadAssets.count;
            self.maxNumForUpload = maxCount > 0 ? MIN(self.maxNumForUpload, maxCount) : 5;
        }
    } else {
        self.maxNumForUpload = ACCConfigBool(kConfigBool_upload_three_frames) ? 3 : 5;
    }
    self.requestID = nil;
    self.isRequesting = YES;
    self.startFetchTime = CFAbsoluteTimeGetCurrent();
    BOOL shouldFetchAIData = [AWEAIMusicRecommendTask shootTypeSupportWithModel:model];
    if (self.recordFramePahts.count == 0 && self.recordFrameType == AWEAIRecordFrameTypeOriginal && shouldFetchAIData) {
        if (model.repoVideoInfo.originalFrameNamesArray.count) {
            self.originFramesPathArray = model.repoVideoInfo.originalFrameNamesArray;
        }
    }

    //3.edit again
    BOOL shouldReFetchFrames = NO;
    if (self.lastCreateId && [self.lastCreateId isEqualToString:model.repoContext.createId]) {
        BOOL videoChanged = ![self isSameAssets:model.repoUploadInfo.selectedUploadAssets];
        if (videoChanged &&
            model.repoContext.videoType != AWEVideoTypeMV &&
            model.repoContext.videoType != AWEVideoTypePhotoToVideo &&
            model.repoContext.videoType != AWEVideoTypeMoments &&
            model.repoContext.videoType != AWEVideoTypeImageAlbum &&
            model.repoContext.videoType != AWEVideoTypeSmartMV &&
            !model.repoContext.isQuickStoryPictureVideoType &&
            ([model.repoVideoInfo.video.videoAssets count] == [self.lastAssetsDurationArray count])) {

            if (self.recordFrameType == AWEAIRecordFrameTypeSegmentedClip) {//clip album video
                //videoChanged = self.clipVideoModified;
                videoChanged = YES;//先和安卓保持一致，本地视频编辑每次回来都抽帧请求数据
            } else if (self.clipVideoModified) {
                videoChanged = YES; // 剪辑过
            } else {
                __block BOOL durationChanged = NO;
                [model.repoVideoInfo.video.videoAssets enumerateObjectsUsingBlock:^(AVAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    CGFloat seconds = CMTimeGetSeconds(obj.duration);
                    NSNumber * tmp = [self.lastAssetsDurationArray acc_objectAtIndex:idx];
                    if (!ACC_FLOAT_EQUAL_TO([tmp floatValue],seconds)) {
                        durationChanged = YES;
                        *stop = YES;
                    }
                }];
                videoChanged = durationChanged;
            }
        }
        if (!videoChanged) {//use the data last time fetch
            self.isRequesting = NO;
            [self p_reset];
            model.repoMusic.zipURI = [ACCCache() objectForKey:kAWEAIHashtagRecommendCacheURIKey];
            ACCBLOCK_INVOKE(completion, model.repoMusic.zipURI, AWEAIRecommendStrategyUploadFrames, NO, nil);
            return;
        }

        if(shouldFetchAIData && !self.recordFramePahts.count && !self.originFramesPathArray.count) {
            shouldReFetchFrames = YES;
        }
    } else if ((model.repoDraft.isDraft || model.repoDraft.isBackUp) && shouldFetchAIData) {
        shouldReFetchFrames = YES;
    } else if (self.recordFrameType == AWEAIRecordFrameTypeSegmentedClip && shouldFetchAIData) {
        shouldReFetchFrames = YES;
    } else if (![self.recordFramePahts count]) {
        shouldReFetchFrames = YES;
    }
    if (self.originFramesPathArray) {
        shouldReFetchFrames = NO;
    }
    if (model.repoContext.isQuickStoryPictureVideoType) {
        shouldReFetchFrames = YES;
    }

    //4.set default value
    [self.lastAssetsDurationArray removeAllObjects];
    [model.repoVideoInfo.video.videoAssets enumerateObjectsUsingBlock:^(AVAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CGFloat seconds = CMTimeGetSeconds(obj.duration);
        [self.lastAssetsDurationArray addObject:@(seconds)];
    }];
    self.lastSelectedAssets = model.repoUploadInfo.selectedUploadAssets;
    self.lastCreateId = model.repoContext.createId;
    self.musicFetchType = AWEAIMusicFetchTypeNone;

    //5.fetch cache and then fetch remote data
    if (shouldReFetchFrames) {
        [ACCAPM() attachFilter:@"ai_music" forKey:@"extracting_frame"];
        [self p_new_fetchFramesWithModel:model callback:^{
            [self p_readCacheAndFetchRemoteDataWithModel:model callback:completion];
            [ACCAPM() attachFilter:nil forKey:@"extracting_frame"];
        }];
    } else {
        [self p_readCacheAndFetchRemoteDataWithModel:model callback:completion];
    }
}

- (void)fetchAIRecommendMusicWithURI:(nullable NSString *)URI callback:(AWEAIMusicRecommendFetchCompletion)completion
{
    AWELogToolInfo(AWELogToolTagMusic, @"%s start fetch AI music List", __PRETTY_FUNCTION__);
    @weakify(self);
    [self.currentTask fetchAIMusicListWithURI:URI otherParam:nil callback:^(AWEAIMusicFetchType fetchType, NSString * _Nullable requestID, NSArray<id<ACCMusicModelProtocol>> * _Nullable musicList, NSNumber * _Nonnull hasMore, NSNumber * _Nonnull cursor, NSError * _Nullable error) {
        @strongify(self);
        self.isRequesting = NO;
        self.recommedMusicList = musicList ? [musicList copy]:[NSArray array];
        self.musicFetchType = fetchType;
        if(fetchType == AWEAIMusicFetchTypeAI) {
            self.requestID = requestID;
        }
        ACCBLOCK_INVOKE(completion, self.recommedMusicList,error);
        AWELogToolInfo(AWELogToolTagMusic, @"%s fetch music list with count:%ld, type:%ld, error%@", __PRETTY_FUNCTION__, (long)musicList.count, (long)fetchType, error);
    }];
}

- (void)fetchAIRecommendMusicWithURI:(nullable NSString *)URI otherParam:(nullable NSDictionary *)param laodMoreCallback:(AWEAIMusicRecommendFetchLoadMoreCompletion)completion
{
    AWELogToolInfo(AWELogToolTagMusic, @"%s start fetch AI music List", __PRETTY_FUNCTION__);
    @weakify(self);
    [self.currentTask fetchAIMusicListWithURI:URI otherParam:param callback:^(AWEAIMusicFetchType fetchType, NSString * _Nullable requestID, NSArray<id<ACCMusicModelProtocol>> * _Nullable musicList, NSNumber * _Nonnull hasMore, NSNumber * _Nonnull cursor, NSError * _Nullable error) {
        @strongify(self);
        self.isRequesting = NO;
        self.usedAIRecommendDefaultMusicList = NO;
        if (self.recommedMusicList) {
            NSMutableArray<id<ACCMusicModelProtocol>> *musicAppendList = [self.recommedMusicList mutableCopy];
            if (param[@"cursor"]) {  // cursor为0时重置所有的音乐
                NSNumber *cursor = [NSNumber numberWithInteger:[param acc_integerValueForKey:@"cursor"]];
                if ([cursor isEqualToNumber:@(0)]) {
                    musicAppendList = [@[] mutableCopy];
                }
            }
            if (musicList.count > 0) {
                [musicAppendList addObjectsFromArray:musicList];
            }
            self.recommedMusicList = musicAppendList;
        } else {
            self.recommedMusicList = musicList ? [musicList copy]:[NSArray array];
        }
        self.musicFetchType = fetchType;
        if(fetchType == AWEAIMusicFetchTypeAI) {
            self.requestID = requestID;
        }
        ACCBLOCK_INVOKE(completion, self.recommedMusicList, hasMore, cursor, error);
        AWELogToolInfo(AWELogToolTagMusic, @"%s fetch music list with count:%ld, type:%ld, error%@", __PRETTY_FUNCTION__, (long)musicList.count, (long)fetchType, error);
    }];
}

- (void)fetchDefaultMusicListFromTOSWithURLGoup:(nullable NSArray<NSString *> *)urlGroup callback:(nullable AWEAIMusicRecommendFetchCompletion)completion {
    if (![urlGroup count]) {
        ACCBLOCK_INVOKE(completion, nil, [AWEAIMusicRecommendTask errorOfAIRecommend]);
        return;
    }
    [IESAutoInline(ACCBaseServiceProvider(), ACCMusicNetServiceProtocol) fetchDefaultMusicListWithURLGoup:urlGroup callback:completion];
}

- (BOOL)aiRecommendMusicEnabledForModel:(nullable AWEVideoPublishViewModel *)model
{
    id<AWERepoCommercialAnchorModelCameraClient> commercialAnchorModel = [model extensionModelOfProtocol:@protocol(AWERepoCommercialAnchorModelCameraClient)];
    if ([IESAutoInline(ACCBaseServiceProvider(), ACCCommerceServiceProtocol) shouldUseCommerceMusic] ||
           [commercialAnchorModel acc_TCMResultOfOpenReocordJSB]) {
        return NO;
    }

    return !model.repoDuet.isDuet;
}

#pragma mark - private methods

- (void)p_fetchAlbumImageFramesWithModel:(AWEVideoPublishViewModel *)model callback:(void (^)(void))callback
{
    @weakify(self);
    acc_dispatch_queue_async_safe(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray *imagePaths = [NSMutableArray array];
        for (ACCImageAlbumEditImageInputInfo *info in [model.repoImageAlbumInfo.imageEditCompressedFramsImages copy]) {
            NSString *path = [info getAbsoluteFilePath];
            if (!ACC_isEmptyString(path) && [[NSFileManager defaultManager] fileExistsAtPath:path]) {
                [imagePaths acc_addObject:path];
                if (imagePaths.count >= self.maxNumForUpload) {
                    break;
                }
            }
        }
        if (imagePaths.count == 0) {
            NSAssert(NO, @"AI music fetch album frame image empty");
            AWELogToolError(AWELogToolTagMusic, @"AI music fetch album frame image empty");
        }

        acc_dispatch_main_async_safe(^{
            @strongify(self);
            [self.recordFramePahts removeAllObjects];
            [self.recordFramePahts acc_addObject:imagePaths];
            ACCBLOCK_INVOKE(callback);
        });
    });
}

- (void)p_new_fetchFramesWithModel:(AWEVideoPublishViewModel *)model callback:(void (^)(void))callback
{
    @weakify(self);
    if (model.repoContext.isQuickStoryPictureVideoType && model.repoUploadInfo.toBeUploadedImage) {
        [self.recordFramePahts removeAllObjects];
        [ACCSecurityFramesSaver saveImage:model.repoUploadInfo.toBeUploadedImage type:ACCSecurityFrameTypeAIRecommond taskId:model.repoDraft.taskID completion:^(NSString * _Nonnull path, BOOL success, NSError * _Nonnull error) {
            @strongify(self);
            if (!ACC_isEmptyString(path)) {
                [self.recordFramePahts acc_addObject:@[path]];
            }
            ACCBLOCK_INVOKE(callback);
        }];
        return;
    }
    if ([model.repoImageAlbumInfo isImageAlbumEdit]) { // 图集模式，使用recordFramePahts，不抽帧
        [self  p_fetchAlbumImageFramesWithModel:model callback:callback];
        return;
    }

    self.timeArray = nil;

    NSMutableArray *pairs = [NSMutableArray array];
    const CGFloat scale = [UIScreen mainScreen].scale;
    const CGSize size = CGSizeMake(self.frameSizeForUpload * scale, self.frameSizeForUpload * scale);
    const NSInteger imageCount = MAX(self.maxNumForUpload, 1);
    const CGFloat start = 0; // 抽帧开始时间
    const CGFloat end = 0.1; // 抽帧结束时间 加个提前值0.1 尾帧容易出问题
    const CGFloat step = MAX(([model.repoVideoInfo.video totalVideoDuration] - start - end) / (imageCount - 1), 0);

    NSMutableArray *timeArray = [NSMutableArray array];
    self.imageGenerator = [[AWEVideoImageGenerator alloc] init];
    [self.imageGenerator requestImages:imageCount effect:NO index:0 startTime:start step:step size:size array:pairs editService:self.editService oneByOneImageBlock:nil completion:^{
        @strongify(self);
        NSMutableArray *frames = [NSMutableArray array];
        [pairs enumerateObjectsUsingBlock:^(NSDictionary *pair, NSUInteger idx, BOOL * _Nonnull stop) {
            UIImage *image = ACCDynamicCast(pair[AWEVideoImageGeneratorImageKey], UIImage);
            NSNumber *time = ACCDynamicCast(pair[AWEVideoImageGeneratorTimeKey], NSNumber);
            if (isnan(time.doubleValue)) {
                NSMutableDictionary *extra = [NSMutableDictionary dictionary];
                extra[@"duration"] = @([model.repoVideoInfo.video totalVideoDuration]);
                extra[@"index"] = @(idx);
                extra[@"step"] = @(step);
                extra[@"imageCount"] = @(imageCount);
                extra[@"prefered_time"] = @(start + idx * step);
                [ACCMonitor() trackService:@"aweme_detect_cover_choose_view_nan" status:1 extra:extra];
                time = @(0);
            }
            if (image && time) {
                [timeArray addObject:time];
                [frames addObject:image];
            }
        }];

        [ACCSecurityFramesSaver saveImages:frames type:ACCSecurityFrameTypeAIRecommond taskId:model.repoDraft.taskID completion:^(NSArray<NSString *> * _Nonnull paths, BOOL success, NSError * _Nonnull error) {
            @strongify(self);
            if (!ACC_isEmptyArray(paths) && paths.count == timeArray.count) {
                [self.recordFramePahts removeAllObjects];
                [self appendFramePaths:paths];
                self.timeArray = [timeArray copy];
            }
            ACCBLOCK_INVOKE(callback);
        }];
    }];
}

- (void)p_readCacheAndFetchRemoteDataWithModel:(AWEVideoPublishViewModel *)model callback:(nullable AWEAIMusicURIFetchCompletion)completion {
    //read cache if cache is not expired
    BOOL canUseCache = NO;
    NSString *cached_uri = [ACCCache() objectForKey:kAWEAIMusicRecommendCacheURIKey];
    NSString *settings_music_uri = ACCConfigString(kConfigString_ai_recommend_music_list_default_uri);
    if (!ACC_isEmptyString(cached_uri) && !ACC_isEmptyString(settings_music_uri) && [cached_uri isEqualToString:settings_music_uri]) {
        NSArray<id<ACCMusicModelProtocol>> * cachedList = [IESAutoInline(ACCBaseServiceProvider(), ACCMusicNetServiceProtocol) fetchCachedMusicListWithCacheKey:kAWEAIMusicRecommendDefaultMusicCacheKey];
        canUseCache = [cachedList count] ? YES:NO;
        if (canUseCache) {
            self.usedAIRecommendDefaultMusicList = YES;
            self.recommedMusicList = cachedList;
            self.musicFetchType = AWEAIMusicFetchTypeSettings;
        }
    }
    if (!canUseCache) {
        self.recommedMusicList = [NSArray array];
        self.musicFetchType = AWEAIMusicFetchTypeNone;
    }

    //create a new task to uplaod frames
    [ACCCache() removeObjectForKey:kAWEAIHashtagRecommendCacheURIKey];
    NSInteger count = 20;
    NSString *currentTaskIdentifier = [NSString stringWithFormat:@"%ld",(long)CFAbsoluteTimeGetCurrent()];
    @weakify(self);
    @weakify(model);
    self.currentTask = [[AWEAIMusicRecommendTask alloc] initWithIdentifier:currentTaskIdentifier
                                                              publishModel:model
                                                          recordFramePaths:[self.recordFramePahts copy]
                                                                     count:count
                                                                  callback:^(NSString * _Nullable zipURI, AWEAIRecommendStrategy recommendStrategyType, NSString * _Nullable firstFrameURI, NSArray<UIImage *> * _Nullable frameImageInZipArray, NSError * _Nullable error) {
        @strongify(self);
        @strongify(model);
        if (!self || !model) {
            AWELogToolInfo2(@"", AWELogToolTagMusic, @"fetch music recommend failed, model is nil.");
            ACCBLOCK_INVOKE(completion, nil, recommendStrategyType, NO, nil);
            return;
        }
        if ([currentTaskIdentifier isEqual:self.currentTask.taskIdentifier]) {
            if (recommendStrategyType == AWEAIRecommendStrategyUploadFrames) {
                model.repoMusic.zipURI = zipURI;
                [ACCCache() setObject:zipURI forKey:kAWEAIHashtagRecommendCacheURIKey];
                [self p_reset];
                [self p_trackWithModel:model fetchDuration:(NSInteger)((CFAbsoluteTimeGetCurrent() - self.startFetchTime)*1000)];
                [self p_fetchAICoverIfNeededWithModel:model zipURI:zipURI frameImageInZipArray:frameImageInZipArray];
            }
            ACCBLOCK_INVOKE(completion, zipURI, recommendStrategyType, YES, error);
        }
    }];
    self.currentTask.originFramesPathArray = self.originFramesPathArray;
    [self.currentTask resume];
}

- (void)p_fetchAIRecommendDefaultData {
    //read cache
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray <id<ACCMusicModelProtocol>> *cachedList = nil;
        NSString *cached_uri = [ACCCache() objectForKey:kAWEAIMusicRecommendCacheURIKey];
        NSString *settings_music_uri = ACCConfigString(kConfigString_ai_recommend_music_list_default_uri);
        if (!ACC_isEmptyString(cached_uri) && !ACC_isEmptyString(settings_music_uri) && [cached_uri isEqualToString:settings_music_uri]) {
            cachedList = [IESAutoInline(ACCBaseServiceProvider(), ACCMusicNetServiceProtocol) fetchCachedMusicListWithCacheKey:kAWEAIMusicRecommendDefaultMusicCacheKey];
        }
        acc_dispatch_main_async_safe(^{
            if (cachedList.count) {
                self.usedAIRecommendDefaultMusicList = YES;
                self.recommedMusicList = cachedList;
            } else {
                //save cache
                if (settings_music_uri.length) {
                    [ACCCache() setObject:settings_music_uri forKey:kAWEAIMusicRecommendCacheURIKey];
                }

                //fetch default music list from tos
                NSArray *tos_list = ACCConfigArray(kConfigArray_ai_recommend_music_list_default_url_lists);
                [self fetchDefaultMusicListFromTOSWithURLGoup:tos_list callback:^(NSArray<id<ACCMusicModelProtocol>> * _Nullable musicList, NSError * _Nullable error) {
                    [IESAutoInline(ACCBaseServiceProvider(), ACCMusicNetServiceProtocol) cacheMusicList:musicList cacheKey:kAWEAIMusicRecommendDefaultMusicCacheKey];
                    if (error) {
                        AWELogToolError(AWELogToolTagMusic, @"fetchDefaultMusicListFromTOSWithURLGoup: %@", error);
                    }
                }];
            }
        });
    });
}

- (BOOL)isSameAssets:(NSArray<AWEAssetModel *> *)newAssets
{
    if (newAssets.count != self.lastSelectedAssets.count || !self.lastSelectedAssets.count) {
        return NO;
    }
    for (int i = 0; i < newAssets.count; i++) {
        AWEAssetModel *assetModel0 = newAssets[i];
        AWEAssetModel *assetModel1 = self.lastSelectedAssets[i];
        if (![assetModel0.asset.localIdentifier isEqualToString:assetModel1.asset.localIdentifier ?: @""]) {
            return NO;
        }
    }
    return YES;
}

- (void)p_fetchAICoverIfNeededWithModel:(AWEVideoPublishViewModel *)model zipURI:(NSString *)zipURI frameImageInZipArray:(NSArray<UIImage *> *)frameImageInZipArray
{
    if (model.repoPublishConfig.recommendedAICoverTime || model.repoPublishConfig.dynamicCoverStartTime > 0) {
        [ACCMonitor() trackService:@"aweme_ai_cover_fetch_start" status:1 extra:@{@"local_exist" : @(1)}];
        return;
    }
    if (frameImageInZipArray.count == 0) {
        [ACCMonitor() trackService:@"aweme_ai_cover_fetch_start" status:1 extra:@{@"zip_empty" : @(1)}];
        return;
    }
    if (model.repoMusic.music && model.repoUploadInfo.selectedUploadAssets.count > 1) { // needAIClip
        [ACCMonitor() trackService:@"aweme_ai_cover_fetch_start" status:1 extra:@{@"music" : @(1)}];
        return;
    }

    if ([model.repoImageAlbumInfo isImageAlbumEdit]) {
        return;
    }

    [ACCMonitor() trackService:@"aweme_ai_cover_fetch_start" status:0 extra:@{@"pass" : @(1)}];

    [IESAutoInline(ACCBaseServiceProvider(), ACCAICoverNetServiceProtocol) fetchAICoverWithZipURI:zipURI completion:^(NSNumber * _Nullable index, NSError * _Nullable error) {
        NSMutableDictionary *extra = [NSMutableDictionary dictionary];
        extra[@"index"] = index ?: @(-2);
        extra[@"zip_valid"] = @(zipURI.length > 0);
        extra[@"local_exist"] = @(model.repoPublishConfig.recommendedAICoverTime != nil || model.repoPublishConfig.dynamicCoverStartTime > 0);
        [ACCMonitor() trackService:@"aweme_ai_cover_fetch_finish" status:error ? 1 : 0 extra:[extra copy]];

        if (error) {
            AWELogToolError(AWELogToolTagMusic, @"fetchAICoverWithZipURI: %@", error);
            return;
        }
        if (model.repoPublishConfig.recommendedAICoverTime || model.repoPublishConfig.dynamicCoverStartTime > 0) {
            return;
        }

        NSArray *times = self.timeArray;
        NSString *timesString = [[[times sortedArrayUsingComparator:^NSComparisonResult(NSNumber *obj1, NSNumber *obj2) {
            return [obj1 compare:obj2];
        }] acc_mapObjectsUsingBlock:^id _Nonnull(NSNumber *obj, NSUInteger idex) {
            return obj.stringValue;
        }] componentsJoinedByString:@", "];
        AWELogToolInfo(AWELogToolTagMusic, @"Cover times = [%@], index = %@", timesString, index);

        if (!index || index.integerValue <= 0) {
            return;
        }

        NSNumber *recommendedAICoverTime = [self.timeArray acc_objectAtIndex:index.integerValue];
        if (recommendedAICoverTime && !isnan(recommendedAICoverTime.doubleValue) && !isinf(recommendedAICoverTime.doubleValue)) {
            model.repoPublishConfig.recommendedAICoverIndex = index;
            model.repoPublishConfig.recommendedAICoverTime = @(recommendedAICoverTime.doubleValue);
            model.repoPublishConfig.dynamicCoverStartTime = recommendedAICoverTime.doubleValue;
        }
        self.timeArray = nil;
    }];
}

- (void)p_reset {
    self.recordFrameType = AWEAIRecordFrameTypeOriginal;
    [self.recordFramePahts removeAllObjects];
    self.originFramesPathArray = nil;
}

#pragma mark - track

- (void)p_trackWithModel:(AWEVideoPublishViewModel *)model fetchDuration:(NSInteger)duration {
    if (!duration) {
        return;
    }

    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"creation_id"] = model.repoContext.createId;
    params[@"enter_from"] = self.enterFrom;
    params[@"music_upload_num"] = @([self.recommedMusicList count]);
    params[@"music_upload_duration"] = @(duration);
    params[@"music_rec_type"] = @(self.musicFetchType);

    NSMutableString *musicIDListStr = [NSMutableString string];
    [self.recommedMusicList enumerateObjectsUsingBlock:^(id<ACCMusicModelProtocol> _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![musicIDListStr length] && obj.musicID) {
            [musicIDListStr appendString:obj.musicID];
        } else if ([musicIDListStr length]) {
            [musicIDListStr appendString:[NSString stringWithFormat:@",%@",obj.musicID]];
        }
    }];
    if ([musicIDListStr length]) {
        params[@"music_id_list"] = musicIDListStr;
    }

    [ACCTracker() trackEvent:@"music_upload_done" params:params needStagingFlag:NO];
}


#pragma mark - jarvis platform track

- (void)jarvisTrackWithEvent:(NSString *)event params:(NSDictionary *)params publishModel:(AWEVideoPublishViewModel *)publishModel {
    if (!event) {
        return;
    }

    NSMutableDictionary *jarvis_params = [NSMutableDictionary dictionary];
    [jarvis_params addEntriesFromDictionary:params];
    NSString *music_id = jarvis_params[@"item_id"]?:@"";
    if (![music_id length]) {
        return;
    }

    if (self.musicFetchType == AWEAIMusicFetchTypeAI || [publishModel.repoMusic.musicTrackModel.musicRecType integerValue] == AWEAIMusicFetchTypeAI) {
        __block BOOL isAIMusic = NO;
        if ([self.recommedMusicList count]) {
            NSMutableArray<id<ACCMusicModelProtocol>> *musicList = [NSMutableArray arrayWithArray:self.recommedMusicList];
            [musicList enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id<ACCMusicModelProtocol> _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([obj.musicID isEqualToString:music_id]) {
                    isAIMusic = YES;
                    *stop = YES;
                }
            }];
        }
        if (!isAIMusic && (publishModel.repoDraft.isBackUp || publishModel.repoDraft.isDraft)) {
            if ([publishModel.repoMusic.musicSelectedFrom isEqualToString:@"edit_page_recommend"]) {
                isAIMusic = YES;
            }
        }

        if (isAIMusic) {
            jarvis_params[@"req_id"] = [AWEAIMusicRecommendManager sharedInstance].requestID?:@"";
            jarvis_params[@"channel_id"] = ACCConfigString(kConfigString_javisChannel);
            [ACCTracker() trackEvent:event params:jarvis_params needStagingFlag:NO];
            AWELogToolInfo(AWELogToolTagEdit|AWELogToolTagAIClip, @"jarvisTrackWithEvent %@, params:%@",event,jarvis_params);
        }
    }
}

- (void)cleanRecommedMusicList
{
    self.usedAIRecommendDefaultMusicList = NO;
    self.recommedMusicList = [NSArray array];
    self.musicFetchType = AWEAIMusicFetchTypeNone;
}

@end
