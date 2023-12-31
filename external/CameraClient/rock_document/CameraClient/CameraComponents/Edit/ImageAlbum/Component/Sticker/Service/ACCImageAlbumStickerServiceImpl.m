//
//  ACCImageAlbumStickerServiceImpl.m
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/12/25.
//

#import "ACCImageAlbumStickerServiceImpl.h"
#import <CreationKitRTProtocol/ACCCameraSubscription.h>
#import "ACCPublishServiceProtocol.h"
#import <CreationKitRTProtocol/ACCEditAudioEffectProtocol.h>
#import <HTSServiceKit/HTSMessageCenter.h>
#import "ACCStickerBizDefines.h"
#import <CreationKitInfra/ACCToastProtocol.h>
#import "ACCConfigKeyDefines.h"
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreationKitInfra/ACCLoadingViewProtocol.h>
#import "ACCImageAlbumEditStickerHandler.h"
#import "ACCRepoImageAlbumInfoModel.h"
#import "ACCImageAlbumData.h"
#import "ACCInfoStickerPinPlugin.h"
#import "ACCStickerHandler+Private.h"
#import "ACCRepoImageAlbumInfoModel+ACCStickerLogic.h"
#import "AWERepoVideoInfoModel.h"
#import <CreationKitArch/ACCRepoStickerModel.h>
#import "ACCPublishServiceMessage.h"
#import "ACCImageAlbumItemModel.h"

@interface ACCImageAlbumStickerServiceImpl () <ACCPublishServiceMessage>

@property (nonatomic, strong, readwrite) ACCImageAlbumEditStickerHandler *compoundHandler;

@property (nonatomic, strong) ACCCameraSubscription *subscription;

@property (nonatomic, strong, readwrite) RACSignal *willStartEditingStickerSignal;
@property (nonatomic, strong, readwrite) RACSubject *willStartEditingStickerSubject;
@property (nonatomic, strong, readwrite) RACSignal *didFinishEditingStickerSignal;
@property (nonatomic, strong, readwrite) RACSubject *didFinishEditingStickerSubject;

@property (nonatomic, strong, readwrite) RACSignal *stickerDeselectedSignal;

@property (nonatomic, assign) BOOL didPrepared;

@end

@implementation ACCImageAlbumStickerServiceImpl
@synthesize stickerContainer = _stickerContainer;
@synthesize simStickerContainer = _simStickerContainer;
@synthesize needAdapterTo9V16FrameForPublish = _needAdapterTo9V16FrameForPublish;


- (instancetype)init
{
    self = [super init];
    if (self) {
        REGISTER_MESSAGE(ACCPublishServiceMessage, self);
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_willStartEditingStickerSubject sendCompleted];
    [_didFinishEditingStickerSubject sendCompleted];
    UNREGISTER_MESSAGE(ACCPublishServiceMessage, self);
}

#pragma mark - public method

- (BOOL)canAddMoreText {
    if (self.publishModel.repoImageAlbumInfo.isImageAlbumEdit) {
        if (self.stickerCount >= ACCConfigInt(kConfigInt_album_image_max_sticker_count)) {
            [ACCToast() show:ACCLocalizedCurrentString(@"infosticker_maxsize_limit_toast")];
            return NO;
        }
    }
    return YES;
}

- (BOOL)enableAllStickerCovertToImageAlbum
{
    return YES;
}

- (void)recoverySticker
{

}

- (void)resetStickerInPlayer {
    [self.compoundHandler reset];
}

- (void)addInteractionStickerInfoToArray:(NSMutableArray *)interactionStickers idx:(NSInteger)stickerIndex {
    [self.compoundHandler addInteractionStickerInfoToArray:interactionStickers idx:stickerIndex];
}

- (void)removeAllInfoStickers {
    [self resetStickerInPlayer];
    [self.compoundHandler removeAllInfoStickers];
    [self removeAllTextRead];
}

- (void)setStickersForPublish {
    
    [self resetStickerInPlayer];
    
    NSInteger __block stickerIdx = 0;
    BOOL flag = NO;
    if ([self.compoundHandler respondsToSelector:@selector(applyStickerStorageModel:forContainer:stickerIndex:imageAlbumIndex:)]) {
        flag = YES;
    }
    
    UIView<ACCLoadingViewProtocol> *loadingView = nil;
    UIView *loadingContainerView = self.stickerContainer.containerView;
    if (loadingContainerView.bounds.size.width > 0 && loadingContainerView.bounds.size.height > 0) {
        loadingView = [ACCLoading() showTextLoadingOnView:loadingContainerView title:@"" animated:YES];
    }
    
    /// 只做一次刷新 这样避免闪一下
    [self.editService.sticker beginCurrentImageEditorBatchUpdate];
    
    [self.publishModel.repoImageAlbumInfo.imageAlbumData.imageAlbumItems enumerateObjectsUsingBlock:^(ACCImageAlbumItemModel * _Nonnull obj, NSUInteger imageAlbumIdx, BOOL * _Nonnull stop) {
        if (obj.stickerInfo.textStickers.count > 0) {
            self.publishModel.repoSticker.hasTextAdded = YES;
            
            if (flag) {
                [obj.stickerInfo.textStickers enumerateObjectsUsingBlock:^(NSObject<ACCSerializationProtocol> * _Nonnull sticker, NSUInteger idx, BOOL * _Nonnull stop) {
                    [self.compoundHandler applyStickerStorageModel:sticker
                                                      forContainer:self.simStickerContainer
                                                      stickerIndex:stickerIdx
                                                   imageAlbumIndex:imageAlbumIdx];
                    stickerIdx += 1;
                }];
            }
        }
    }];
    
    /// 务必注意成对调用，上面循环里如果后续有提前return要加上
    [self.editService.sticker endCurrentImageEditorBatchUpdate];
    
    [loadingView dismissWithAnimated:YES];
}

- (void)addInteractionStickerInfosForImageItem:(ACCImageAlbumItemModel *)item inContainer:(ACCStickerContainerView *)containerView
{
    NSMutableArray *interactionStickers = [[NSMutableArray alloc] init];
    [self.compoundHandler addInteractionStickerInfoToArray:interactionStickers idx:0 inContainerView:containerView];
    item.stickerInfo.interactionStickers = [interactionStickers copy];
}

- (void)finish {
    [self.compoundHandler finish];
}

- (void)startQuickTextInput {
    [self.subscription performEventSelector:@selector(onStartQuickTextInput) realPerformer:^(id<ACCStickerServiceSubscriber> handler) {
        [handler onStartQuickTextInput];
    }];
}

// TODO: @chenzhizhao
// Video
- (BOOL)needAdaptPlayer {
    return NO;
}

- (BOOL)isAllStickersInPlayer
{
    return YES;
}

- (BOOL)isAllInfoStickersInPlayer
{
    return YES;
}

- (BOOL)hasStickers {
    // 没打入的文字贴纸
    if ([self stickerCount] > 0) {
        return YES;
    }
    return self.publishModel.repoImageAlbumInfo.isHaveAnySticker;
}

- (NSInteger)infoStickerCount {
    return [self.stickerContainer stickerViewsWithTypeId:ACCStickerTypeIdInfo].count;
}

- (NSInteger)textStickersCount
{
    return [self.stickerContainer stickerViewsWithTypeId:ACCStickerTypeIdText].count;
}

// 独立计数，不受贴纸总个数限制的贴纸个数
- (NSInteger)independentStickersCount
{
    return [self.stickerContainer stickerViewsWithTypeId:ACCStickerTypeIdEditTag].count;
}

- (NSInteger)stickerCount
{
    return [self.stickerContainer allStickerViews].count - [self independentStickersCount];
}

- (void)deselectAllSticker {
    [self.stickerContainer doDeselectAllStickers];
}

- (id<ACCEditAudioEffectProtocol>)audioEffectService
{
    return self.editService.audioEffect;
}

- (void)setStickerContainerLoader:(ACCStickerContainerView * _Nonnull (^)(void))stickerContainerLoader
{
    _stickerContainerLoader = [stickerContainerLoader copy];
    _compoundHandler.stickerContainerLoader = stickerContainerLoader;
}

- (void)recoveryStickersForContainer:(ACCStickerContainerView *)containerView
                          imageModel:(ACCImageAlbumItemStickerInfo *)stickerModel
{
    if ([self.compoundHandler respondsToSelector:@selector(recoverStickerForContainer:storageModel:)]) {
        [stickerModel.textStickers enumerateObjectsUsingBlock:^(NSObject<ACCSerializationProtocol> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [self.compoundHandler recoverStickerForContainer:containerView storageModel:obj];
        }];
    }
    if ([self.compoundHandler respondsToSelector:@selector(recoverStickerForContainer:imageAlbumStickerModel:)]) {
        [stickerModel.stickers enumerateObjectsUsingBlock:^(ACCImageAlbumStickerModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            ACCImageAlbumStickerRecoverModel *recoverModel = [[ACCImageAlbumStickerRecoverModel alloc] init];
            recoverModel.infoSticker = obj;
            [self.compoundHandler recoverStickerForContainer:containerView imageAlbumStickerModel:recoverModel];
        }];
        [stickerModel.interactionStickers enumerateObjectsUsingBlock:^(AWEInteractionStickerModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            ACCImageAlbumStickerRecoverModel *recoverModel = [[ACCImageAlbumStickerRecoverModel alloc] init];
            recoverModel.interactionSticker = obj;
            [self.compoundHandler recoverStickerForContainer:containerView imageAlbumStickerModel:recoverModel];
        }];
    }
}

- (void)resetStickerContainer
{
    self.compoundHandler.stickerContainerView = nil;
    _stickerContainer = nil;
}

- (BOOL)isSelectedSticker:(UIGestureRecognizer *)gesture
{
    return [self.stickerContainer targetViewFor:gesture] != nil;
}

- (BOOL)shouldDismissInPreviewMode:(id)typeId
{
    if ([typeId isKindOfClass:NSString.class] && [typeId isEqualToString:ACCStickerTypeIdEditTag]) {
        return NO;
    }
    return YES;
}

#pragma mark - private method

- (void)removeAllTextRead {
    if(self.publishModel.repoSticker.textReadingAssets.count) {
        [[self audioEffectService] hotRemoveAudioAssests:[self.publishModel.repoSticker allAudioAssetsInVideoData]];
    }
    [self.publishModel.repoSticker.textReadingAssets removeAllObjects];
    [self.publishModel.repoSticker.textReadingRanges removeAllObjects];
}

#pragma mark - ACCPublishService

- (void)publishServiceWillStart
{
    [self.compoundHandler finish];
}

- (void)publishServiceWillSaveDraft
{
    [self.compoundHandler finish];
}

#pragma mark - sticker handler

- (void)registStickerHandler:(ACCStickerHandler *)handler {
    self.compoundHandler.editSticker = self.editService.sticker;
    [self.compoundHandler addHandler:handler];
}

- (ACCImageAlbumEditStickerHandler *)compoundHandler {
    if (!_compoundHandler) {
        _compoundHandler = [ACCImageAlbumEditStickerHandler compoundHandler];
        
        if (_stickerContainerLoader) {
            _compoundHandler.stickerContainerLoader = _stickerContainerLoader;
        }
    }
    return _compoundHandler;
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

- (void)dismissPreviewEdge {
}

- (void)startEditingStickerOfType:(ACCStickerType)type
{
    [self.willStartEditingStickerSubject sendNext:nil];
}

- (void)finishEditingStickerOfType:(ACCStickerType)type
{
    [self.didFinishEditingStickerSubject sendNext:nil];
}

- (void)syncStickerInfoWithVideo {
}

- (void)updateStickerViewWithOriginStickerId:(NSInteger)originStickerId
                                newStickerId:(NSInteger)newStickerId
{
}

- (BOOL)isAllEditEffectInPlayerContaienr {
    return YES;
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

- (RACSignal *)stickerDeselectedSignal {
    if (!_stickerDeselectedSignal) {
        _stickerDeselectedSignal = [[self rac_signalForSelector:@selector(deselectAllSticker)] takeUntil:self.rac_willDeallocSignal];
    }
    return _stickerDeselectedSignal;
}


#pragma mark - Properties

- (ACCStickerContainerView *)stickerContainer {
    if (_stickerContainer || !self.stickerContainerLoader) {
        return _stickerContainer;
    }
    _stickerContainer = self.stickerContainerLoader();
    return _stickerContainer;
}

- (void)setEditService:(id<ACCEditServiceProtocol>)editService
{
    _editService = editService;
    
    self.compoundHandler.editSticker = editService.sticker;
}

@end
