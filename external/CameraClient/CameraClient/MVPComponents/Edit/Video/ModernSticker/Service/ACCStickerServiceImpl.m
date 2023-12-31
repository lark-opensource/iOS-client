//
//  ACCStickerServiceImpl.m
//  CameraClient-Pods-Aweme
//
//  Created by liyingpeng on 2020/9/4.
//

#import "AWERepoStickerModel.h"
#import "AWERepoContextModel.h"
#import <CreativeKitSticker/ACCStickerProtocol.h>
#import "ACCStickerServiceImpl.h"
#import <CreationKitRTProtocol/ACCCameraSubscription.h>
#import <CreationKitRTProtocol/ACCEditAudioEffectProtocol.h>
#import "ACCStickerBizDefines.h"
#import <CreationKitInfra/ACCToastProtocol.h>
#import <CameraClient/UIView+ACCTextLoadingView.h>
#import "ACCConfigKeyDefines.h"
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/ACCLoadingViewProtocol.h>
#import <CreationKitInfra/ACCRACWrapper.h>
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import "ACCInfoStickerPinPlugin.h"
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreativeKit/ACCEditViewContainer.h>
#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import "ACCPublishServiceProtocol.h"
#import <CreationKitArch/ACCEditAndPublishConstants.h>
#import "ACCStickerEditContentProtocol.h"
#import <CameraClient/AWERepoVideoInfoModel.h>
#import <CreationKitArch/ACCRepoStickerModel.h>
#import <CreationKitArch/ACCRepoUploadInfomationModel.h>
#import <CreationKitInfra/ACCGroupedPredicate.h>
#import "AWEInteractionStickerModel+DAddition.h"
#import "AWERepoDraftModel.h"
#import <CreativeKitSticker/ACCStickerGroupView.h>
#import "ACCRepoActivityModel.h"

@interface ACCStickerServiceImpl ()

@property (nonatomic, strong, readwrite) ACCStickerCompoundHandler *compoundHandler;

@property (nonatomic, strong) ACCCameraSubscription *subscription;

@property (nonatomic, strong, readwrite) RACSignal *willStartEditingStickerSignal;
@property (nonatomic, strong, readwrite) RACSubject *willStartEditingStickerSubject;
@property (nonatomic, strong, readwrite) RACSignal *didFinishEditingStickerSignal;
@property (nonatomic, strong, readwrite) RACSubject *didFinishEditingStickerSubject;

@property (nonatomic, strong, readwrite) RACSignal *stickerDeselectedSignal;

@end

@implementation ACCStickerServiceImpl

@synthesize needResetPreviewEdge = _needResetPreviewEdge;
@synthesize needRecoverStickers = _needRecoverStickers;
@synthesize stickerContainer = _stickerContainer;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_willStartEditingStickerSubject sendCompleted];
    [_didFinishEditingStickerSubject sendCompleted];
}

#pragma mark - public method

- (ACCStickerContainerView *)stickerContainer {
    if (_stickerContainer || !self.stickerContainerLoader) {
        return _stickerContainer;
    }
    _stickerContainer = self.stickerContainerLoader();
    return _stickerContainer;
}

- (void)startEditingStickerOfType:(ACCStickerType)type
{
    [self.willStartEditingStickerSubject sendNext:nil];
}

- (void)finishEditingStickerOfType:(ACCStickerType)type
{
    [self.didFinishEditingStickerSubject sendNext:nil];
}

- (BOOL)canAddMoreText {
    if (self.textStickersCount) {
        if (self.textStickersCount >= ACCConfigInt(kConfigInt_text_sticker_max_count)) {
            [ACCToast() show:ACCLocalizedCurrentString(@"com_mig_maximum_text_stickers_selected")];
            return NO;
        }
    }
    if (self.repository.repoActivity.wishModel.text.length) {
        return NO;
    }
    return YES;
}

- (void)expressStickers
{
    [self expressStickersOnCompletion:nil];
}

- (void)expressStickersOnCompletion:(void (^)(void))completionHandler
{
    // text and poi do not needs a completion callback, no async invokes
    for (ACCEditorStickerConfig *config in self.repository.repoSticker.stickerConfigAssembler.textStickerConfigList) {
        [self.compoundHandler expressSticker:config];
    }
    if (self.repository.repoSticker.stickerConfigAssembler.modernPOIStickerConfig != nil) {
        [self.compoundHandler expressSticker:self.repository.repoSticker.stickerConfigAssembler.modernPOIStickerConfig];
    }
    if (completionHandler != nil) {
        dispatch_group_t group = dispatch_group_create();
        for (ACCEditorStickerConfig *config in self.repository.repoSticker.stickerConfigAssembler.infoStickerConfigList) {
            dispatch_group_enter(group);
            [self.compoundHandler expressSticker:config onCompletion:^{
                dispatch_group_leave(group);
            }];
        }
        dispatch_group_notify(group, dispatch_get_main_queue(), ^{
            if (completionHandler) {
                completionHandler();
            }
        });
    } else {
        for (ACCEditorStickerConfig *config in self.repository.repoSticker.stickerConfigAssembler.infoStickerConfigList) {
            [self.compoundHandler expressSticker:config];
        }
    }
    // lyrics should support completion callback one day
    if (self.repository.repoSticker.stickerConfigAssembler.lyricsStickerConfig) {
        [self.compoundHandler expressSticker:self.repository.repoSticker.stickerConfigAssembler.lyricsStickerConfig];
    }
    
    self.repository.repoSticker.stickerConfigAssembler = nil;
}

- (void)recoverySticker {
    for (IESInfoSticker *infoSticker in self.repository.repoVideoInfo.video.infoStickers) {
        ACCRecoverStickerModel *model = [[ACCRecoverStickerModel alloc] init];
        model.infoSticker = infoSticker;
        [self.compoundHandler recoverSticker:model];
    }
    for (AWEInteractionStickerModel *interactionSticker in self.repository.repoSticker.interactionStickers) {
        ACCRecoverStickerModel *model = [[ACCRecoverStickerModel alloc] init];
        model.interactionSticker = interactionSticker;
        [self.compoundHandler recoverSticker:model];
    }
}

- (void)syncRecordSticker
{
    CGRect recordPlayerFrame = self.repository.repoSticker.recordStickerPlayerFrame;
    for (AWEInteractionStickerModel *interactionSticker in self.repository.repoSticker.recorderInteractionStickers) {
        AWEInteractionStickerLocationModel *location = [interactionSticker generateLocationModel];
        AWEInteractionStickerLocationModel *convertLocation = [ACCStickerServiceImpl convertRatioLocationModel:location fromPlayerFrame:recordPlayerFrame toPlayerFrame:self.stickerContainer.playerRect];
        [interactionSticker updateLocationInfo:convertLocation];
        
        ACCRecoverStickerModel *model = [[ACCRecoverStickerModel alloc] init];
        model.sourceType = ACCRecoverStickerSourceTypeRecord;
        model.interactionSticker = interactionSticker;
        [self.compoundHandler recoverSticker:model];
    }
}

- (void)resetStickerInPlayer {
    [self.compoundHandler reset];
}

- (void)addInteractionStickerInfoToArray:(NSMutableArray *)interactionStickers idx:(NSInteger)stickerIndex {
    [self.compoundHandler addInteractionStickerInfoToArray:interactionStickers idx:stickerIndex];
}

- (void)removeAllInfoStickers {
    [self resetStickerInPlayer];
    [self.stickerContainer removeAllStickerViews];
    [self removeAllTextRead];
}

- (void)setStickersForPublish {
    [self resetStickerInPlayer];
    NSMutableArray<ACCStickerViewType> * mutableStickers = [NSMutableArray array];
    [mutableStickers addObjectsFromArray:[self.stickerContainer stickerViewsWithHierarchyId:@(ACCStickerHierarchyTypeNormal)]];
    [mutableStickers addObjectsFromArray:[self.stickerContainer stickerViewsWithHierarchyId:@(ACCStickerHierarchyTypeMediumHigh)]];
    NSArray<ACCStickerViewType> * stickers = [mutableStickers copy];
    if (stickers.count == 0) {
        self.repository.repoSticker.hasTextAdded = NO;
    }
    UIView<ACCLoadingViewProtocol> *loadingView = nil;
    if (![self.stickerContainer.containerView acc_loadingViewExistsInHierarchy]) {
        loadingView = [ACCLoading() showTextLoadingOnView:self.stickerContainer.containerView title:@"" animated:YES];
    }
    [stickers enumerateObjectsUsingBlock:^(ACCStickerViewType  _Nonnull sticker, NSUInteger idx, BOOL * _Nonnull stop) {
        [self.compoundHandler apply:sticker index:idx];
    }];
    [loadingView dismissWithAnimated:YES];
}

- (void)finish {
    [self.compoundHandler finish];
}

- (void)dismissPreviewEdge
{
    AWEVideoType videoType = self.repository.repoContext.videoType;
    if (videoType == AWEVideoTypePhotoMovie) {//照片电影没有贴纸
        AWELogToolInfo2(@"resolution", AWELogToolTagEdit, @"[edge]dismissPreviewEdge is used videoType:AWEVideoTypePhotoMovie.");
        return;
    }
    BOOL isAllStickersInPlayer = [self isAllStickersInPlayer];
    if (isAllStickersInPlayer) {
        if ([self.needResetPreviewEdge evaluate]) {
            [self.editService.mediaContainerView updateOriginalFrameWithSize:self.editService.mediaContainerView.containerSize];
            self.repository.repoVideoInfo.playerFrame = self.editService.mediaContainerView.originalPlayerFrame;
            self.editService.preview.previewEdge = nil;
            self.repository.repoContext.isEditEffectInPlayerContainer = YES;
        } else {
            self.repository.repoContext.isEditEffectInPlayerContainer = NO;
        }
    } else {
        self.repository.repoContext.isEditEffectInPlayerContainer = NO;
    }
    AWELogToolInfo2(@"resolution", AWELogToolTagEdit, @"[edge]dismiss isAllStickersInPlayer:%@, videoType:%@, isDraft:%@, isBackUp:%@.", @(isAllStickersInPlayer), @(videoType), @(self.repository.repoDraft.isDraft), @(self.repository.repoDraft.isBackUp));
}

- (BOOL)needAdapterTo9V16FrameForPublish
{
    CGSize oldSize = self.editService.mediaContainerView.originalPlayerFrame.size;
    CGSize newSize = self.editService.mediaContainerView.editPlayerFrame.size;
    BOOL hasPreviewEdge = (oldSize.width > CGFLOAT_MIN && oldSize.height > CGFLOAT_MIN && ACC_FLOAT_GREATER_THAN(oldSize.width/oldSize.height, 9.f/16.f));
    BOOL isStandardEditFrame = (newSize.width > CGFLOAT_MIN && newSize.height > CGFLOAT_MIN && ACC_FLOAT_EQUAL_TO(newSize.width/newSize.height, 9.f/16.f));
    return hasPreviewEdge && !isStandardEditFrame && ![self isAllStickersInPlayer];
}

- (BOOL)isAllStickersInPlayer
{
    BOOL allin = YES;
    NSArray *stickerViews = [self.stickerContainer allStickerViews];
    for (UIView *stickerView in stickerViews) {
        if (![self.editService.mediaContainerView isPlayerContainsRect:stickerView.frame]) {
            allin = NO;
            break;
        }
    }
    
    if (allin) {
        self.repository.repoUploadInfo.extraDict[@"isAllStickersInPlayer"] = @(YES);
    } else {
        self.repository.repoUploadInfo.extraDict[@"isAllStickersInPlayer"] = @(NO);
        AWELogToolInfo2(@"resolution", AWELogToolTagEdit, @"All stickers in player:%d", allin);
    }
    
    return allin;
}

- (BOOL)isAllInfoStickersInPlayer
{
    BOOL allin = YES;
    NSArray *stickerViews = [self.stickerContainer stickerViewsWithTypeId:ACCStickerTypeIdInfo];
    for (UIView *stickerView in stickerViews) {
        if (![self.editService.mediaContainerView isPlayerContainsRect:stickerView.frame]) {
            allin = NO;
            break;
        }
    }
    return allin;
}

- (BOOL)needAdaptPlayer {
    return !self.repository.repoContext.isIMRecord && [self isAllStickersInPlayer];
}

- (void)startQuickTextInput {
    [self.subscription performEventSelector:@selector(onStartQuickTextInput) realPerformer:^(id<ACCStickerServiceSubscriber> handler) {
        [handler onStartQuickTextInput];
    }];
}

- (BOOL)hasStickers {
    // 过滤掉 ACCCanvasStickerComponent 加入的“贴纸”
    for (int i = 0; i < self.stickerContainer.allStickerViews.count; i++) {
        UIView<ACCStickerProtocol> *sticker = self.stickerContainer.allStickerViews[i];
        if (![sticker.config.hierarchyId isEqual:@(ACCStickerHierarchyTypeVeryVeryLow)]) {
            return YES;
        }
    }
    return NO;
}

- (NSInteger)infoStickerCount {
    return [self.stickerContainer allStickerViews].count -
        [self.stickerContainer stickerViewsWithTypeId:ACCStickerTypeIdText].count -
        [self.stickerContainer stickerViewsWithTypeId:ACCStickerTypeIdCaptions].count;
}

- (NSInteger)stickerCount
{
    return [self.stickerContainer allStickerViews].count;
}

- (BOOL)enableAllStickerCovertToImageAlbum
{
    if (!ACCConfigBool(kConfigBool_enable_canvas_photo_publish_optimize_text_sticker_add)) {
        return ![self hasStickers];
    }
    
    NSTimeInterval totalVideoDuration = self.repository.repoVideoInfo.video.totalVideoDuration;
    
    __block BOOL ret = YES;
    [[self.stickerContainer allStickerViews] enumerateObjectsUsingBlock:^(ACCStickerViewType  _Nonnull sticker, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if (![sticker.config.hierarchyId isEqual:@(ACCStickerHierarchyTypeVeryVeryLow)] &&
            ![sticker.config.typeId isEqual:ACCStickerTypeIdText]) {
            ret = NO;
            *stop = YES;
        }
        // 不支持设置时长
        if (sticker.stickerTimeRange &&
            (sticker.stickerTimeRange.startTime.doubleValue > 0 ||
             sticker.stickerTimeRange.endTime.doubleValue < totalVideoDuration * 1000)) {
            ret = NO;
            *stop = YES;;
        }
    }];
    
    return ret;
}

- (void)deselectAllSticker {
    [self.stickerContainer doDeselectAllStickers];
}

- (id<ACCEditAudioEffectProtocol>)audioEffectService
{
    return self.editService.audioEffect;
}

- (void)cancelAllPinSticker {
    BOOL shouldCancelPin = [self.repository.repoVideoInfo.video.infoStickers btd_contains:^BOOL(IESInfoSticker * _Nonnull obj) {
        return obj.pinStatus == VEStickerPinStatus_Pinned;
    }];
    
    if (!shouldCancelPin) {
        return;
    }
    
    __block ACCInfoStickerPinPlugin *pinPlugin;
    [self.stickerContainer.plugins enumerateObjectsUsingBlock:^(id<ACCStickerContainerPluginProtocol>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:ACCInfoStickerPinPlugin.class]) {
            pinPlugin = (id)obj;
            *stop = YES;
        }
    }];
    
    if (pinPlugin) {
        [pinPlugin cancelAllPinnedSticker];
    }
}

- (void)syncStickerInfoWithVideo
{
    // synchronize stickerId between stickerContentView and HTSVideoData
    for (IESInfoSticker *videoSticker in self.repository.repoVideoInfo.video.infoStickers) {
        NSString *videoStickerUUIDStr = ACCDynamicCast([videoSticker.userinfo objectForKey:kACCStickerUUIDKey], NSString);
        
        [[self.stickerContainer allStickerViews] enumerateObjectsUsingBlock:^(ACCStickerViewType  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (![obj.contentView conformsToProtocol:@protocol(ACCStickerEditContentProtocol)]) {
                return;
            }
            
            UIView<ACCStickerEditContentProtocol> *contentView = (UIView<ACCStickerEditContentProtocol> *)obj.contentView;
            if (!ACC_isEmptyString(videoStickerUUIDStr) && [contentView respondsToSelector:@selector(stickerViewIdentifier)]) {
                if ([[contentView stickerViewIdentifier] isEqualToString:videoStickerUUIDStr]) {
                    contentView.stickerId = videoSticker.stickerId;
                }
            }
        }];
    }
}

- (void)updateStickerViewWithOriginStickerId:(NSInteger)originStickerId
                                newStickerId:(NSInteger)newStickerId
{
    void (^process)(ACCStickerViewType _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) = ^(ACCStickerViewType _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        if (![obj.contentView conformsToProtocol:@protocol(ACCStickerEditContentProtocol)]) {
            return;
        }
        
        UIView<ACCStickerEditContentProtocol> *contentView = (UIView<ACCStickerEditContentProtocol> *)obj.contentView;
        if (contentView.stickerId == originStickerId) {
            contentView.stickerId = newStickerId;
        }
    };
    
    [[self.stickerContainer allStickerViews] enumerateObjectsUsingBlock:^(ACCStickerViewType  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:ACCStickerGroupView.class]) {
            ACCStickerGroupView *groupView = (ACCStickerGroupView *)obj;
            NSArray<ACCStickerViewType> *allStickerViews = [groupView.stickerList copy];
            [allStickerViews enumerateObjectsUsingBlock:process];
        } else {
            process(obj, idx, stop);
        }
    }];
}

- (void)updateStickersDuration:(NSTimeInterval)duration
{
    for (UIView<ACCStickerProtocol> *view in self.stickerContainer.allStickerViews) {
        if (view.realStartTime < duration && view.realStartTime + view.realDuration > duration && duration > 0) {
            view.realDuration = duration - view.realStartTime;
        }
    }
}

- (BOOL)isAllEditEffectInPlayerContaienr {
    BOOL isAllStickersInPlayer = [self isAllStickersInPlayer];
    if (isAllStickersInPlayer && [self.needResetPreviewEdge evaluate]) {
        return YES;
    }
    return NO;
}

#pragma mark - private method

- (NSInteger)textStickersCount {
    return [self.stickerContainer stickerViewsWithTypeId:ACCStickerTypeIdText].count;
}

- (void)removeAllTextRead {
    if(self.repository.repoSticker.textReadingAssets.count) {
        [[self audioEffectService] hotRemoveAudioAssests:[self.repository.repoSticker allAudioAssetsInVideoData]];
    }
    [self.repository.repoSticker.textReadingAssets removeAllObjects];
    [self.repository.repoSticker.textReadingRanges removeAllObjects];
}

#pragma mark - sticker handler

- (void)registStickerHandler:(ACCStickerHandler *)handler {
    [self.compoundHandler addHandler:handler];
}

- (ACCStickerCompoundHandler *)compoundHandler {
    if (!_compoundHandler) {
        _compoundHandler = [ACCStickerCompoundHandler compoundHandler];
    }
    return _compoundHandler;
}

#pragma mark - Signals

- (RACSignal *)willStartEditingStickerSignal
{
    return self.willStartEditingStickerSubject;
}

- (RACSubject *)willStartEditingStickerSubject
{
    if (!_willStartEditingStickerSubject) {
        _willStartEditingStickerSubject = [RACSubject subject];
    }
    return _willStartEditingStickerSubject;
}

- (RACSignal *)didFinishEditingStickerSignal
{
    return self.didFinishEditingStickerSubject;
}

- (RACSubject *)didFinishEditingStickerSubject
{
    if (!_didFinishEditingStickerSubject) {
        _didFinishEditingStickerSubject = [RACSubject subject];
    }
    return _didFinishEditingStickerSubject;
}

#pragma mark - subscription

- (ACCCameraSubscription *)subscription {
    if (!_subscription) {
        _subscription = [ACCCameraSubscription new];
    }
    return _subscription;
}

- (void)addSubscriber:(id<ACCStickerServiceSubscriber>)subscriber {
    [self.subscription addSubscriber:subscriber];
}

#pragma mark - signals

- (RACSignal *)stickerDeselectedSignal {
    if (!_stickerDeselectedSignal) {
        _stickerDeselectedSignal = [[self rac_signalForSelector:@selector(deselectAllSticker)] takeUntil:self.rac_willDeallocSignal];
    }
    return _stickerDeselectedSignal;
}

#pragma mark - Lazy Load

- (ACCGroupedPredicate *)needRecoverStickers
{
    if (_needRecoverStickers == nil) {
        _needRecoverStickers = [[ACCGroupedPredicate alloc] init];
    }
    return _needRecoverStickers;
}

- (ACCGroupedPredicate *)needResetPreviewEdge
{
    if (_needResetPreviewEdge == nil) {
        _needResetPreviewEdge = [[ACCGroupedPredicate alloc] init];
    }
    return _needResetPreviewEdge;
}

#pragma mark - Utils
+ (AWEInteractionStickerLocationModel *)convertRatioLocationModel:(AWEInteractionStickerLocationModel *)model
                                                  fromPlayerFrame:(CGRect)fromeFrame
                                                    toPlayerFrame:(CGRect)toFrame
{
    if (!fromeFrame.size.width || !fromeFrame.size.height || !toFrame.size.width || !toFrame.size.height) {
        return model;
    }
    
    if (fromeFrame.size.width / fromeFrame.size.height == toFrame.size.width / toFrame.size.height) {
        return model;
    }
    
    CGFloat x = [model.x floatValue];
    CGFloat y = [model.y floatValue];
    CGFloat width = [model.width floatValue];
    CGFloat height = [model.height floatValue];
    
    CGSize oldSize = fromeFrame.size;
    CGSize newSize = toFrame.size;
    
    if (newSize.width > oldSize.width) {
        x = (x * oldSize.width + (newSize.width - oldSize.width) / 2.0) / newSize.width;
    }
    if (newSize.height > oldSize.height) {
        y = (y * oldSize.height + (newSize.height - oldSize.height) / 2.0) / newSize.height;
    }
    width = width * oldSize.width / newSize.width;
    height = height * oldSize.height / newSize.height;
    
    AWEInteractionStickerLocationModel *locModel = [model copy];
    locModel.x = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.4f", x]];
    locModel.y = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.4f", y]];
    locModel.width = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.4f", width]];
    locModel.height = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.4f", height]];
    return locModel;
}

@end
