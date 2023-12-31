//
//  AWEStickerFeatureManager.m
//  AWEStudio
//
//  Created by 郝一鹏 on 2018/3/26.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import "AWEStickerFeatureManager.h"
#import "AWEStickerDataManager+AWEConvenience.h"
#import "AWERecorderTipsAndBubbleManager.h"
#import <CreativeKit/NSTimer+ACCAdditions.h>

@interface AWEStickerFeatureManager ()

@property (nonatomic, strong, readwrite) AWEModernStickerViewController *stickerController;
@property (nonatomic, strong) UIImage *prevImage;//fixing this bug: https://jira.bytedance.com/browse/AME-53584

//for performace track
@property (nonatomic, strong) IESEffectModel *effectApplied;
@property (nonatomic, strong) id<AWEComposerEffectProtocol> composerEffectApplied;
@property (nonatomic, assign) NSTimeInterval effectAppliedStart;
@property (nonatomic, strong) NSTimer *photoSensitiveTimer;

@end

@implementation AWEStickerFeatureManager

- (void)dealloc
{
    [self invalidatePhotoSensitiveTimer];
}

- (instancetype)initWithPanelType:(AWEStickerPanelType)panelType
{
    self = [super init];
    if (self) {
        _stickerDataManager = [[AWEStickerDataManager alloc] initWithPanelType:panelType];
    }
    return self;
}

- (void)setStickerFeatureDelegate:(NSObject<AWEStickerFeatureDelegate> *)delegate
{
    self.delegate = delegate;
    self.stickerController.delegate = self;
}

- (void)showStickerViewControllerWithBlock:(void(^)(void))block;
{
    UIViewController *vc = (UIViewController *)self.delegate;
    if (![vc isKindOfClass:[UIViewController class]]) {
        if ([(id)self.delegate respondsToSelector:@selector(containerViewController)]) {
            vc = [self.delegate containerViewController];
        }
    }
    self.stickerController.isStoryMode = self.isStoryMode;
    [self.stickerController showOnViewController:vc];
    ACCBLOCK_INVOKE(block);
}

- (void)hideStickerViewController:(BOOL)hidden {
    self.stickerController.view.hidden = hidden;
}

- (void)setStickerViewControllerDismissBlock:(void (^)(IESEffectModel *))dismissBlock
{
    self.stickerController.dismissBlock = dismissBlock;
}

- (void)setTrackingInfoDictionary:(NSDictionary *)trackingInfoDictionary {
    self.stickerController.trackingInfoDictionary = trackingInfoDictionary;
    self.stickerDataManager.trackExtraDic = [trackingInfoDictionary copy];
}

- (void)setSchemaTrackParams:(NSDictionary *)schemaTrackParams {
    self.stickerController.schemaTrackParams = [schemaTrackParams copy];
}

- (void (^)(IESEffectModel *))getStickerViewControllerDismissBlock
{
    return self.stickerController.dismissBlock;
}

#pragma mark - apply sticker methods

- (void)applySticker:(IESEffectModel *)item completion:(AWEApplyStickerCompletionBlock)completion
{
    if (![item isCommerce] && (item.gameType == ACCGameTypeNone) && [item isTypePhotoSensitive]) {
        [self p_applyPhotoSensitiveSticker:item completion:completion];
    } else {
        [self p_applySticker:item completion:completion];
    }
}

- (void)p_applyPhotoSensitiveSticker:(IESEffectModel *)item completion:(AWEApplyStickerCompletionBlock)completion {
    if (item) {
        BOOL isLocalSticker= NO;
        if ([self.delegate respondsToSelector:@selector(isLocalSticker:)]) {
            isLocalSticker = [self.delegate isLocalSticker:item];
        }
        if (!isLocalSticker) {
            [[AWERecorderTipsAndBubbleManager shareInstance] removePropHint]; // 引用道具 setEffectLoadStatusBlock 里会再次显示
            [self p_applySticker:nil completion:nil];
        }
        if ([self.delegate respondsToSelector:@selector(showPhotoSensitiveAlertWithSticker:)]) {
            [self.delegate showPhotoSensitiveAlertWithSticker:item];
        }
        [self invalidatePhotoSensitiveTimer];
        // PropPhotoSensitive auto dismiss after show duration 3s, and auto apply the effect
        @weakify(self);
        self.photoSensitiveTimer = [NSTimer acc_scheduledTimerWithTimeInterval:3.0 block:^(NSTimer * _Nonnull timer) {
            @strongify(self);
            BOOL isLocalSticker= NO;
            if ([self.delegate respondsToSelector:@selector(isLocalSticker:)]) {
                isLocalSticker = [self.delegate isLocalSticker:item];
            }
            if (isLocalSticker) {
                [self.stickerController.actionDelegate stickerHintViewShowWithEffect:item];
            }
            
            if ([self.stickerController.propSelection.leafEffect.effectIdentifier isEqualToString:item.effectIdentifier]) {
                [self p_applySticker:item completion:completion];
            }
        } repeats:NO];
    } else {
        [self p_applySticker:item completion:completion];
    }
}
- (void)invalidatePhotoSensitiveTimer
{
    if (self.photoSensitiveTimer) {
        [self.photoSensitiveTimer invalidate];
        self.photoSensitiveTimer = nil;
    }
}

- (void)p_applySticker:(IESEffectModel *)item completion:(AWEApplyStickerCompletionBlock)completion
{
    [[AWERecorderTipsAndBubbleManager shareInstance] removePropPhotoSensitive];
    [self p_recordAppliedEffect:item];
    AWEStickerFeatureWillApplyStickerCompleteBlock complete = ^{
        self.stickerDataManager.faceImage = nil;
        self.stickerDataManager.multiAssetImages = nil;
        [self configCameraStickerStatusBlockWithSticker:item completion:completion];

        [self.cameraService.effect acc_applyStickerEffect:item];
        
        if (item!=nil && item.recordTrackInfos!=nil) {
            [ACCTracker() trackEvent:@"prop_try"
                              params:item.recordTrackInfos
                     needStagingFlag:NO];
        }
    };

    [self.stickerController stickerWillApplyAction];
    ACCBLOCK_INVOKE(self.willapplyStickerBlock, item, complete);
}

- (void)applyVESticker:(IESEffectModel *)item {
    [self p_recordAppliedEffect:item];
    [self.cameraService.effect acc_applyVEStickerEffect:item];
}

- (void)applyComposerSticker:(id<AWEComposerEffectProtocol>)item extra:(NSString *)extra {
    [self p_recordAppliedComposerEffect:item];
    [self.cameraService.effect acc_applyComposerEffect:item extra:extra];
    if (!item) {
        ACCBLOCK_INVOKE(self.applyStickerCompletionBlock, YES, nil, @"");
    }
}

- (void)applyVEComposerSticker:(id<AWEComposerEffectProtocol>)item extra:(NSString *)extra {
    [self p_recordAppliedComposerEffect:item];
    [self.cameraService.effect acc_applyVEComposerEffect:item extra:extra];
}

- (void)invokeFaceDetectingProgress:(IESEffectModel *)item completion:(AWEApplyStickerCompletionBlock)completion {
    [self p_recordAppliedEffect:item];
    AWEStickerFeatureWillApplyStickerCompleteBlock complete = ^{
        [self configCameraStickerStatusBlockWithSticker:item completion:completion];
        if ([item isTypeAdaptive]) { // 开启扫描算法
            [self.cameraService.effect acc_applyStickerEffect:item];
        }
    };
    [self.stickerController stickerWillApplyAction];
    ACCBLOCK_INVOKE(complete);
}

#pragma mark -

- (void)configCameraStickerStatusBlockWithSticker:(IESEffectModel *)item completion:(AWEApplyStickerCompletionBlock)completion
{
    @weakify(self);
    [self.cameraService.effect setEffectLoadStatusBlock:^(IESStickerStatus status,NSInteger stickerId, NSString *resName) {
        @strongify(self);
        ACCBLOCK_INVOKE(self.stickerStatusBlock, status, item);

        if (status != IESStickerStatusValid && status != IESStickerStatusInvalid) {
            return;
        }
        // 如果是AR抠脸贴纸，那么通知stickerViewController展示人脸列表
        [self.stickerController sticker:item isCancel:stickerId == 0 && ACC_isEmptyString(resName) appliedSuccess:status == IESStickerStatusValid];
        if (self.prevImage) {
            [self didChooseImage: self.prevImage];
            self.prevImage = nil;
        }

        // completion不是每次都调，点击应用贴纸effect可能只回调IESStickerStatusLoading
        acc_dispatch_main_async_safe(^{
            ACCBLOCK_INVOKE(self.applyStickerCompletionBlock, status == IESStickerStatusValid, item, resName);
            ACCBLOCK_INVOKE(completion, status == IESStickerStatusValid, stickerId, resName);
        });
    }];
}

- (void)didChooseImage:(UIImage *)image
{
    NSArray<NSString *> * AuxiliaryTextureKeys = [self.cameraService.effect getAuxiliaryTextureKeys];
    if (AuxiliaryTextureKeys.count > 0 && image) {
        self.stickerDataManager.faceImage = image;
        [self.cameraService.effect setAuxiliaryImage:image withKey:AuxiliaryTextureKeys.firstObject];
    } else {
        self.prevImage = image;//AR抠脸贴纸sdk内部是异步调用，需要等上面的函数status正常后才能设image，所以这里尝试把图片先缓存，sdk ready后再设置
        [self.cameraService.effect removeAllAuxiliaryImages];
    }
}

- (void)clearStickerAllEffect
{
    self.stickerDataManager.faceImage = nil;
    self.stickerDataManager.multiAssetImages = nil;
    [self.stickerController stickerClearAllEffect];
}

- (AWEModernStickerViewController *)stickerController
{
    if (!_stickerController) {
        _stickerController = [[AWEModernStickerViewController alloc] initWithDataManager:self.stickerDataManager];
        _stickerController.needTrackEvent = self.needTrackEvent;

//        _stickerController.isStoryMode = self.isStoryMode;
    }
    return _stickerController;
}

- (void)setNeedTrackEvent:(BOOL)needTrackEvent
{
    _needTrackEvent = needTrackEvent;
    _stickerController.needTrackEvent = needTrackEvent;
}

- (void)setIsShowingStickerController:(BOOL)isShowingStickerController
{
    self.stickerController.isShowing = isShowingStickerController;
}

- (void)setSelectedSticker:(IESEffectModel *)model selectedChildSticker:(IESEffectModel *)childModel
{
    [self.stickerController setSelectedSticker:model selectedChildSticker:childModel];
}

- (void)updateModernStickerViewController {
    [self.stickerController updateCollectionView];
}

- (void)switchCameraToFront:(BOOL)isFront
{
    [self.stickerController switchCameraToFront:isFront];
}

#pragma mark - Getter

- (id<ACCCameraService>)cameraService
{
    return [self.stickerController.actionDelegate cameraService];
}

#pragma mark - performance track

- (void)trackEffectApplyToRecognize:(NSDictionary *)commonParams
{
    @synchronized (self) {
        if (self.effectApplied || self.composerEffectApplied) {
            NSTimeInterval recognize = CFAbsoluteTimeGetCurrent();
            if (self.effectAppliedStart && (recognize > self.effectAppliedStart)) {
                NSTimeInterval applyCostTime = (recognize - self.effectAppliedStart) * 1000;
                NSMutableDictionary *params = commonParams.mutableCopy;
                params[@"duration"] = @((NSInteger)applyCostTime);
                params[@"effect_id"] = self.effectApplied.effectIdentifier ?:(self.composerEffectApplied.effectId ?:@"");
                [ACCTracker() trackEvent:@"tool_performance_effect_use_info" params:params needStagingFlag:NO];
                
                //reset after record track
                self.effectApplied = nil;
                self.composerEffectApplied = nil;
            }
        }
    }
}

- (void)p_recordAppliedEffect:(IESEffectModel *)item
{
    if (!item) {
        self.effectApplied = nil;
    } else {
        if (!self.effectApplied || ![self.effectApplied.effectIdentifier isEqualToString:item.effectIdentifier]) {
            self.effectApplied = item;
            self.effectAppliedStart = CFAbsoluteTimeGetCurrent();
        }
    }
    
    //only apply/deselect 1 sticker at the same time
    self.composerEffectApplied = nil;
}

- (void)p_recordAppliedComposerEffect:(id<AWEComposerEffectProtocol>)item
{
    if (!item) {
        self.composerEffectApplied = nil;
    } else {
        if (!self.composerEffectApplied || ![self.composerEffectApplied.effectId isEqualToString:item.effectId]) {
            self.composerEffectApplied = item;
            self.effectAppliedStart = CFAbsoluteTimeGetCurrent();
        }
    }
    
    //only apply/deselect 1 sticker at the same time
    self.effectApplied = nil;
}


@end
