//
//  ACCDuetLayoutViewModel.m
//  Pods
//
//  Created by guochenxiang on 2020/6/10.
//

#import "ACCDuetLayoutViewModel.h"

#import "ACCDuetLayoutManager.h"
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreativeKit/ACCMonitorProtocol.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/ACCWebImageProtocol.h>
#import "ACCDuetLayoutService.h"
#import <CreationKitArch/IESEffectModel+ACCSticker.h>
#import "ACCRecordFlowService.h"
#import "ACCRecordPropService.h"
#import "AWERepoDuetModel.h"
#import <CreationKitArch/ACCRepoDraftModel.h>
#import <CreationKitArch/HTSVideoDefines.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import "AWERepoVideoInfoModel.h"
#import <CreationKitArch/ACCRecordInformationRepoModel.h>
#import "AWEVideoFragmentInfo.h"

#import <CameraClient/ACCRecordViewControllerInputData.h>

#import <CreativeKit/ACCCacheProtocol.h>
#import <CreativeKit/ACCMonitorProtocol.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/ACCWebImageProtocol.h>
#import "ACCConfigKeyDefines.h"
#import <CreativeKit/ACCMacros.h>

typedef NS_ENUM(NSUInteger, ACCDuetLandscapeVideoLayoutABType) {
    ACCDuetLandscapeVideoLayoutABTypeDefault               = 0, ///< 保持线上(左右排列)
    ACCDuetLandscapeVideoLayoutABTypeUpDownAndOriginalUp   = 1, ///< 上下排列 且 原视频在上
    ACCDuetLandscapeVideoLayoutABTypeUpDownAndOriginalDown = 2, ///< 上下排列 且 原视频在下
};

@interface ACCDuetLayoutViewModel () <ACCDuetLayoutManagerDelegate>

@property (nonatomic, strong) RACSubject<ACCDuetLayoutModelPack> *duetLayoutDidChangedSubject;
@property (nonatomic, strong) RACSubject<UIImage *> *updateIconSubject;
@property (nonatomic, strong) RACSubject<ACCDuetLayoutModel *> *shouldSwapCameraPositionSubject;
@property (nonatomic, strong) RACSubject *applyDuetLayoutSubject;
@property (nonatomic, strong) RACSubject<NSNumber *> *refreshDuetLayoutsSubject;
@property (nonatomic, strong) RACSubject *successDownFirstLayoutResourceSubject;
@property (nonatomic, strong) RACSubject<ACCDuetIconImagePack> *duetIconImageReadySubject;

@property (nonatomic, strong) id<ACCCameraService> cameraService;
@property (nonatomic, strong) id<ACCRecordPropService> propService;
@property (nonatomic, strong) id<ACCRecordFlowService> flowService;

@property (nonatomic, strong, readwrite) ACCDuetLayoutManager *duetManager;
@property (nonatomic, assign) BOOL hasRetryDuetLayout;

@property (nonatomic, assign) NSInteger duetGreenScreenAppearanceThreshold;
@property (nonatomic, assign) NSInteger figureAppearanceDuration;
@property (nonatomic, assign) BOOL isDuetGreenScreenSelected;
@property (nonatomic, assign) BOOL figureAppearanceDurationReachesThreshold;

@end

@implementation ACCDuetLayoutViewModel

IESAutoInject(self.serviceProvider, cameraService, ACCCameraService)
IESAutoInject(self.serviceProvider, propService, ACCRecordPropService)
IESAutoInject(self.serviceProvider, flowService, ACCRecordFlowService)

#pragma mark -

- (void)dealloc
{
    [_shouldSwapCameraPositionSubject sendCompleted];
    [_duetLayoutDidChangedSubject sendCompleted];
    [_updateIconSubject sendCompleted];
    [_successDownFirstLayoutResourceSubject sendCompleted];
    [_refreshDuetLayoutsSubject sendCompleted];
    [_duetIconImageReadySubject sendCompleted];
    [_applyDuetLayoutSubject sendCompleted];
}

#pragma mark - private
- (void)moniterDuetCameraCreation
{
    // 增加校验资源端监控，校验资源是否成功
    //add resource verify monitor to check if resource has load succeed.
    BOOL initDuetRecoderSuccessed = NO;
    BOOL hasDuetLocalSourceURL = NO;
    BOOL legalDuetLocalSource = NO;
    if (self.cameraService && self.cameraService.cameraHasInit) {
        initDuetRecoderSuccessed = YES;
        if (self.inputData.publishModel.repoDuet.duetLocalSourceURL) {
            hasDuetLocalSourceURL = YES;
            legalDuetLocalSource = YES;
            AVAsset *sourceAsset = [AVURLAsset URLAssetWithURL:self.inputData.publishModel.repoDuet.duetLocalSourceURL  options:@{AVURLAssetPreferPreciseDurationAndTimingKey: @(YES)}];
            AVAssetTrack *videoTrack = [sourceAsset tracksWithMediaType:AVMediaTypeVideo].firstObject;
            if (!videoTrack || CGSizeEqualToSize(videoTrack.naturalSize, CGSizeZero)) {
                legalDuetLocalSource = NO;
            }
        }
    }
    
    AWELogToolInfo(AWELogToolTagRecord, @"IESMMDuetRecoder init successed:%@, is draft: %@, has duetLocalSourceURL:%@, legal duetLocalSource:%@, video size:%@", @(initDuetRecoderSuccessed), @(self.inputData.publishModel.repoDraft.isDraft), @(hasDuetLocalSourceURL), @(legalDuetLocalSource), NSStringFromCGSize(self.inputData.publishModel.repoVideoInfo.video.transParam.videoSize));

    NSDictionary *data = @{@"IESMMDuetRecoderInit" : @(initDuetRecoderSuccessed),
                           @"duetLocalSourceURL" : @(hasDuetLocalSourceURL),
                           @"legalDuetLocalSource" : @(legalDuetLocalSource),
                           @"duetVideoSize" : NSStringFromCGSize(self.inputData.publishModel.repoVideoInfo.video.transParam.videoSize) ?: @""};
    [ACCMonitor() trackService:@"aweme_ies_duet_recorder_log" status:legalDuetLocalSource ? 0 : 1 extra:data];
}

- (NSArray<NSString *> *)supportDuetLayoutList {
    return [ACCDuetLayoutFrameModel supportDuetLayoutFrameList];
}

#pragma mark - ACCDuetLayoutManagerDelegate

- (void)succeedDownloadFirstLayoutResource
{
    [self.successDownFirstLayoutResourceSubject sendNext:nil];
}

- (void)duetLayoutManager:(ACCDuetLayoutManager *)manager didApplyDuetLayout:(NSString *)duetLayout
{
    self.inputData.publishModel.repoDuet.duetLayout = duetLayout;
    [self.applyDuetLayoutSubject sendNext:nil];
}

- (void)duetLayoutManager:(ACCDuetLayoutManager *)manager loadEffectsFinished:(BOOL)success
{
    [self.refreshDuetLayoutsSubject sendNext:@(success)];
}

- (void)duetLayoutManager:(ACCDuetLayoutManager *)manager willApplyDuetLayoutModel:(ACCDuetLayoutModel *)model
{
    IESEffectModel *duetLayoutModel = model.effect;
    self.isDuetGreenScreenSelected = duetLayoutModel.isDuetGreenScreen;
    [self updateShouldShowDuetGreenScreenAlert];
    if (self.isDuetGreenScreenSelected) {
        self.duetGreenScreenAppearanceThreshold = [[duetLayoutModel acc_analyzeSDKExtra] acc_intValueForKey:@"appearance_duration"];
        AWELogToolInfo(AWELogToolTagRecord, @"received IESEffectModel: The max threshold of duet figure appearance is %ld ms", (long)self.duetGreenScreenAppearanceThreshold);
    }
    [self.shouldSwapCameraPositionSubject sendNext:model];
}

#pragma mark - getter

- (BOOL)isDuetGreenScreenEverShot
{
    return [ACCCache() boolForKey:kACCDuetGreenScreenIsEverShot];
}

- (BOOL)isDuetLandscapeVideoAndNeedOptimizeLayout
{
    if (!self.repository.repoDuet.isDuet) {
        return NO;
    }
    
    if (self.repository.repoDraft.isDraft || self.repository.repoDraft.isBackUp) {
        return NO;
    }

    NSString *duetLayout = [self p_landscapeVideoConfigDuetLayoutName];
    if (ACC_isEmptyString(duetLayout)) {
        return NO;
    }
    
    CGFloat videoWidth = self.repository.repoDuet.duetSource.video.width.floatValue;
    CGFloat videoHeight = self.repository.repoDuet.duetSource.video.height.floatValue;
    // 竖屏或者等边视频不处理
    return (videoWidth > videoHeight);
}

- (NSString *)p_landscapeVideoConfigDuetLayoutName
{
    ACCDuetLandscapeVideoLayoutABType layoutType = ACCConfigEnum(kConfigInt_duet_landscape_video_layout_type, ACCDuetLandscapeVideoLayoutABType);
    if (layoutType == ACCDuetLandscapeVideoLayoutABTypeUpDownAndOriginalUp) {
        return ACCConfigString(kConfigString_duet_original_up_layout_model_key);
    }
    
    if (layoutType == ACCDuetLandscapeVideoLayoutABTypeUpDownAndOriginalDown) {
        return ACCConfigString(kConfigString_duet_original_down_layout_model_key);
    }
    
    return nil;
}

- (RACSignal<ACCDuetLayoutModelPack> *)duetLayoutDidChangedSignal {
    return self.duetLayoutDidChangedSubject;
}

- (RACSubject<ACCDuetLayoutModelPack> *)duetLayoutDidChangedSubject {
    if (!_duetLayoutDidChangedSubject) {
        _duetLayoutDidChangedSubject = [RACSubject subject];
    }
    return _duetLayoutDidChangedSubject;
}

- (RACSignal<UIImage *> *)updateIconSignal
{
    return self.updateIconSubject;
}

- (RACSubject<UIImage *> *)updateIconSubject
{
    if (!_updateIconSubject) {
        _updateIconSubject = [RACSubject subject];
    }
    return _updateIconSubject;
}

- (RACSignal *)successDownFirstLayoutResourceSignal
{
    return self.successDownFirstLayoutResourceSubject;
}

- (RACSignal<NSNumber *> *)refreshDuetLayoutsSignal
{
    return self.refreshDuetLayoutsSubject;
}

- (RACSignal *)applyDuetLayoutSignal {
    return self.applyDuetLayoutSubject;
}

- (RACSubject *)applyDuetLayoutSubject {
    if (!_applyDuetLayoutSubject) {
        _applyDuetLayoutSubject = [RACSubject subject];
    }
    return _applyDuetLayoutSubject;
}

- (RACSignal<ACCDuetLayoutModel *> *)shouldSwapCameraPositionSignal
{
    return self.shouldSwapCameraPositionSubject;
}

- (RACSubject<ACCDuetLayoutModel *> *)shouldSwapCameraPositionSubject
{
    if (!_shouldSwapCameraPositionSubject) {
        _shouldSwapCameraPositionSubject = [RACSubject subject];
    }
    return _shouldSwapCameraPositionSubject;
}

- (RACSignal<ACCDuetIconImagePack> *)duetIconImageReadySignal
{
    return self.duetIconImageReadySubject;
}

- (RACSubject *)successDownFirstLayoutResourceSubject
{
    if (!_successDownFirstLayoutResourceSubject) {
        _successDownFirstLayoutResourceSubject = [RACSubject subject];
    }
    return _successDownFirstLayoutResourceSubject;
}

- (RACSubject<ACCDuetIconImagePack> *)duetIconImageReadySubject
{
    if (!_duetIconImageReadySubject) {
        _duetIconImageReadySubject = [RACSubject subject];
    }
    return _duetIconImageReadySubject;
}

- (ACCDuetLayoutManager *)duetManager
{
    if (!_duetManager) {
        _duetManager = [[ACCDuetLayoutManager alloc] initWithDelegate:self];
        _duetManager.cameraService = self.cameraService;
    }
    return _duetManager;
}

- (NSArray<ACCDuetLayoutModel *> *)duetLayoutModels
{
    return self.duetManager.duetLayoutModels;
}

- (NSInteger)firstTimeIndex
{
    return self.duetManager.firstTimeIndex;
}

#pragma mark - public method

- (void)startDuetIfNecessary
{
    if (!self.inputData.publishModel.repoDuet.isDuet) {
        return;
    }

    AWEVideoPublishViewModel *publishModel = self.inputData.publishModel;
    //new duet
    if (publishModel.repoDraft.isDraft || publishModel.repoDraft.isBackUp) {
        self.duetManager.firstDuetLayout = publishModel.repoDuet.duetLayout;
    } else if ([self isDuetLandscapeVideoAndNeedOptimizeLayout]) {
        // 横屏视频默认应用上下布局
        NSString *duetLayout = [self p_landscapeVideoConfigDuetLayoutName];
        if (!ACC_isEmptyString(duetLayout)) {
            self.duetManager.firstDuetLayout = duetLayout;
        }
    }
    [self.duetManager downloadDuetLayoutResources];
    @weakify(self);
    AWELogToolInfo(AWELogToolTagRecord, @"Duet change layout setMultiVideo URL: %@", publishModel.repoDuet.duetLocalSourceURL);
    [self.cameraService.recorder setMultiVideoWithVideoURL:publishModel.repoDuet.duetLocalSourceURL
                                      rate:HTSVideoSpeedNormal
                             completeBlock:^(NSError * _Nullable error) {
        @strongify(self);
        if (error) {
            if (self.hasRetryDuetLayout) {//has retried but still failed
                AWELogToolError(AWELogToolTagRecord, @"Duet change layout setMultiVideo URL failed with errorCode = %@, errorMsg = %@, url = %@", @(error.code), error.localizedDescription, publishModel.repoDuet.duetLocalSourceURL);
            } else {
                self.hasRetryDuetLayout = YES;
                [self startDuetIfNecessary];
            }
        } else {
            [self.cameraService.recorder setMultiVideoAutoRepeat:NO];
            BOOL didApplyFirstDuetLayouts = NO;
            if (!ACC_isEmptyString(self.duetManager.firstDuetLayout) && ACCConfigBool(kConfigBool_duet_first_layout_optimize)) {
                didApplyFirstDuetLayouts = [self.duetManager applyFirstDuetLayoutsIfEnable];
            }
            // 优化,这里草稿恢复之前也有bug会闪一下，尝试修复，使用实际的layout而不是默认layout
            if (!didApplyFirstDuetLayouts) {
                [self.duetManager applyDefaultDuetLayouts];
            }
            
            [self retryMultiVideoSeekToTimeIfNeeded];
        }
    }];

    [self moniterDuetCameraCreation];
}

- (void)retryMultiVideoSeekToTimeIfNeeded
{
    if (self.flowService.lastCapturedVideoDuration > 0) { //restore duet video player play time
        CMTime targetTime = CMTimeMultiplyByFloat64(CMTimeMakeWithSeconds(self.flowService.lastCapturedVideoDuration, 10000), self.flowService.selectedSpeed);
        [self.cameraService.recorder multiVideoSeekToTime:targetTime completeBlock:^(BOOL finished) {}];
    }
}

- (void)sendUpdateIconSignal:(UIImage *)image
{
    if (image) {
        [self.updateIconSubject sendNext:image];
    }
}

- (void)didSelectDuetLayoutAtIndex:(NSInteger)index
{
    if (index >= self.duetManager.duetLayoutModels.count) {
        return;
    }
    [self.duetManager applyDuetLayoutWithIndex:index];
    ACCDuetLayoutModel *model = [self.duetManager.duetLayoutModels objectAtIndex:index];
    UIImage *iconImage = ACCResourceImage(@"duet_layout_left_right");
    [self.updateIconSubject sendNext:iconImage];
    
    NSNumber *enableTouchGes = [NSNumber numberWithBool:[model.effect isTypeTouchGes]];
    [self.duetLayoutDidChangedSubject sendNext:RACTuplePack(model, enableTouchGes)];
    
    @weakify(self);
    [ACCWebImage() requestImageWithURLArray:model.effect.iconDownloadURLs completion:^(UIImage * image, NSURL *url, NSError * error){
        if (image) {
            @strongify(self);
            [self.duetIconImageReadySubject sendNext:RACTuplePack(image, @(index))];
            [self.updateIconSubject sendNext:image];
        }
    }];
}
                                                                  
- (void)retryDownloadDuetEffects
{
    BOOL isDraftOrBackup = (self.inputData.publishModel.repoDraft.isDraft || self.inputData.publishModel.repoDraft.isBackUp);
    if (isDraftOrBackup) {
        self.duetManager.firstDuetLayout = self.inputData.publishModel.repoDuet.duetLayout;
    }
    [self.duetManager downloadDuetLayoutResources];
}

#pragma mark - duet import asset

- (BOOL)enableDuetImportAsset {
    return !self.repository.repoDuet.isDuetSing &&  ACCConfigBool(kConfigBool_studio_enable_duet_import_asset);
}

- (BOOL)supportImportAssetDuetLayout {
    BOOL isDuet = self.repository.repoDuet.isDuet;
    NSString *duetLayout = self.repository.repoDuet.duetLayout;
    if (isDuet && [self enableDuetImportAsset] && !ACC_isEmptyString(duetLayout)) { // 合拍且支持相册导入
        __block BOOL support = NO;
        [[self supportDuetLayoutList] enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([duetLayout isEqualToString:obj]) {
                support = YES;
                *stop = YES;
            }
        }];
        return support;
    } else {
        return NO;
    }
}

- (void)handleMessageOfDuetLayoutChanged:(NSString *)duetLayout {
    if (!ACC_isEmptyString(duetLayout)) {
        self.repository.repoDuet.duetLayoutMessage = duetLayout;
    } else {
        self.repository.repoDuet.duetLayoutMessage = nil;
        AWELogToolError2(@"duet", AWELogToolTagRecord, @"Message of duet layout is empty.");
    }
}

#pragma mark - Green Screen Duet Layout Handler

- (void)updateShouldShowDuetGreenScreenAlert
{
    // if duet greenscreen is selected and [the duration doesn't satisfy the requirement or user never captures duet greenscreen],
    // then set as YES
    self.repository.repoDuet.shouldShowDuetGreenScreenAlert = self.isDuetGreenScreenSelected &&
                                                    (!(self.figureAppearanceDurationReachesThreshold ||
                                                       self.figureAppearanceDuration >= self.duetGreenScreenAppearanceThreshold) ||
                                                       ![self isDuetGreenScreenEverShot]);
}

- (void)updateFigureAppearanceDurationInMS
{
    // sum up all the fragmentInfo.figureAppearanceDurationInMS to validate whether this video satisfies the requirement
    __block NSInteger totalDuration = 0;
    [self.inputData.publishModel.repoVideoInfo.fragmentInfo enumerateObjectsUsingBlock:^(AWEVideoFragmentInfo * _Nonnull fragmentInfo, NSUInteger idx, BOOL * _Nonnull stop) {
            totalDuration += fragmentInfo.figureAppearanceDurationInMS;
    }];
    self.figureAppearanceDuration = totalDuration;
    self.figureAppearanceDurationReachesThreshold = NO;
    [self updateShouldShowDuetGreenScreenAlert];
}

- (void)handleMessageOfFigureAppearanceDurationReachesThreshold
{
    self.figureAppearanceDurationReachesThreshold = YES;
    [self updateShouldShowDuetGreenScreenAlert];
}

- (void)sendMessageOfRemovingSegmentsToEffectWithID:(NSInteger)messageId
{
    IESMMEffectMessage *message = [[IESMMEffectMessage alloc] init];
    message.msgId = messageId;
    [self.cameraService.message sendMessageToEffect:message];
    [self updateFigureAppearanceDurationInMS];
    AWELogToolInfo(AWELogToolTagRecord, @"did send IESMMEffectMessage: remove segment(s) with messageId %ld", (long)messageId);
}

@end
