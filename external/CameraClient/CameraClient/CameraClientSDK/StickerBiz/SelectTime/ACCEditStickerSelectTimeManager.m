//
//  ACCEditStickerSelectTimeManager.m
//  CameraClient-Pods-Aweme
//
//  Created by raomengyun on 2021/1/26.
//

#import "ACCEditStickerSelectTimeManager.h"
#import <CreationKitArch/AWEVideoImageGenerator.h>
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import "ACCAssetImageGeneratorTracker.h"
#import "ACCStickerEditContentProtocol.h"
#import "ACCVideoEditStickerContainerConfig.h"
#import "ACCStickerSelectTimeConfigImpl.h"
#import "ACCEditStickerSelectTimeViewController.h"
#import "ACCEditTransitionServiceProtocol.h"
#import "ACCInfoStickerContentView.h"
#import "ACCStickerGroup.h"

#import <CreativeKitSticker/ACCStickerContainerView.h>
#import <CreativeKitSticker/ACCStickerContainerConfigProtocol.h>
#import <CreativeKitSticker/ACCStickerContainerView+ACCStickerCopying.h>
#import <TTVideoEditor/IESInfoSticker.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CreativeKit/ACCMacros.h>

@interface ACCEditStickerSelectTimeManager()<ACCStickerSelectTimeVCDelegate>

@property (nonatomic, strong) id<ACCEditServiceProtocol> editService;
@property (nonatomic, strong) AWEVideoPublishViewModel *repository;
@property (nonatomic, strong) ACCStickerContainerView *stickerContainer;
@property (nonatomic, strong) id<ACCStickerPlayerApplying> player;
@property (nonatomic, strong) id<ACCEditTransitionServiceProtocol> transitionService;

@property (nonatomic, copy) NSDictionary<NSNumber *, NSNumber *> *backPinStatusDict;

@end
@implementation ACCEditStickerSelectTimeManager

- (instancetype)initWithEditService:(id<ACCEditServiceProtocol>)editService
                         repository:(AWEVideoPublishViewModel *)repository
                             player:(id<ACCStickerPlayerApplying>)player
                   stickerContainer:(ACCStickerContainerView *)stickerContainer
                  transitionService:(id<ACCEditTransitionServiceProtocol>)transitionService;
{
    self = [super init];
    if (self) {
        _editService = editService;
        _repository = repository;
        _player = player;
        _stickerContainer = stickerContainer;
        _transitionService = transitionService;
    }
    return self;
}

#pragma mark - ACCStickerSelectTimeVCDelegate

- (void)imageGenerator:(AWEVideoImageGenerator *)imageGenerator requestImages:(NSUInteger)count step:(CGFloat)step size:(CGSize)size array:(NSMutableArray *)previewImageDictArray completion:(void (^)(void))complete
{
    NSTimeInterval imageGeneratorBegin = CFAbsoluteTimeGetCurrent();
    @weakify(self);
    [imageGenerator requestImages:count effect:YES index:0 step:step size:size array:previewImageDictArray editService:[self editService] oneByOneImageBlock:nil completion:^{
        @strongify(self);
        ACCBLOCK_INVOKE(complete);
        //performance track
        [ACCAssetImageGeneratorTracker trackAssetImageGeneratorWithType:ACCAssetImageGeneratorTypeStickerSelectTime frames:count beginTime:imageGeneratorBegin extra:self.repository.repoTrack.commonTrackInfoDic];
    }];
}

- (void)didUpdateStickerContainer:(nonnull ACCStickerContainerView *)stickerContainer
{
    [self.stickerContainer updateWithInstance:stickerContainer context:@""];
    [self.stickerContainer.allStickerViews enumerateObjectsUsingBlock:^(ACCStickerViewType  _Nonnull stickerWrapper, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([stickerWrapper.contentView conformsToProtocol:@protocol(ACCStickerEditContentProtocol)]) {
            [(id<ACCStickerEditContentProtocol>)stickerWrapper.contentView setTransparent:NO];
        }
    }];
}

- (void)didCancelStickerContainer:(ACCStickerContainerView *)stickerContainer
{
    [self recoveryInfoStickerChanges:stickerContainer originPinStatus:self.backPinStatusDict];
}

- (void)modernEditStickerDuration:(UIView<ACCStickerProtocol> *)stickerView
{
    self.backPinStatusDict = [self backupStickerInfosPinStatus];
    
    @weakify(self);
    ACCStickerContainerView *stickerContainer = [self.stickerContainer
                                                 copyForContext:@""
                                                 modConfig:^(NSObject<ACCStickerContainerConfigProtocol> * _Nonnull config) {
        if ([config isKindOfClass:ACCVideoEditStickerContainerConfig.class]) {
            ACCVideoEditStickerContainerConfig *rConfig = (id)config;
            [rConfig reomoveSafeAreaPlugin];
            [rConfig removeAdsorbingPlugin];
            [rConfig removePreviewViewPlugin];
        }
    } modContainer:^(ACCStickerContainerView * _Nonnull stickerContainerView) {
        @strongify(self);
        [stickerContainerView configWithPlayerFrame:self.stickerContainer.frame allowMask:NO];
    } enumerateStickerUsingBlock:^(__kindof ACCBaseStickerView * _Nonnull stickerView, NSUInteger idx, ACCStickerGeometryModel * _Nonnull geometryModel, ACCStickerTimeRangeModel * _Nonnull timeRangeModel) {
        stickerView.config.showSelectedHint = NO;
        stickerView.config.secondTapCallback = NULL;
        geometryModel.preferredRatio = NO;
        stickerView.stickerGeometry.preferredRatio = NO;
    }];
    [stickerContainer setShouldHandleGesture:YES];
    
    ACCStickerSelectTimeConfigImpl *config = [[ACCStickerSelectTimeConfigImpl alloc] init];
    config.repository = self.repository;
    
    ACCEditStickerSelectTimeInputData *inputData = [[ACCEditStickerSelectTimeInputData alloc] init];
    inputData.delegate = self;
    inputData.transitionService = self.transitionService;
    inputData.player = self.player;
    inputData.stickerView = stickerView;
    inputData.stickerContainer = stickerContainer;
    inputData.playerRect = [self editService].mediaContainerView.frame;
    inputData.editService = self.editService;
    
    ACCEditStickerSelectTimeViewController *stickerSelectTimeVC = [[ACCEditStickerSelectTimeViewController alloc] initWithConfig:config
                                                                                                                       inputData:inputData];
    [self.transitionService presentViewController:stickerSelectTimeVC completion:nil];
}

- (void)recoveryInfoStickerChanges:(UIView<ACCStickerContainerProtocol> *)stickerContainer originPinStatus:(NSDictionary<NSNumber *, NSNumber *> *)originPinStatus
{
    NSMutableDictionary<NSNumber *, ACCInfoStickerContentView *> *cmpDict = [[NSMutableDictionary alloc] init];
    [[stickerContainer stickerViewsWithTypeId:ACCStickerTypeIdInfo] enumerateObjectsUsingBlock:^(ACCStickerViewType  _Nonnull stickerWrapper, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([stickerWrapper.contentView isKindOfClass:ACCInfoStickerContentView.class]) {
            ACCInfoStickerContentView *infoContentView = (id)stickerWrapper.contentView;
            cmpDict[@(infoContentView.stickerId)] = infoContentView;
        }
    }];

    [[self.stickerContainer stickerViewsWithTypeId:ACCStickerTypeIdInfo] enumerateObjectsUsingBlock:^(ACCStickerViewType  _Nonnull stickerWrapper, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([stickerWrapper.contentView isKindOfClass:ACCInfoStickerContentView.class]) {
            ACCInfoStickerContentView *infoContentView = (id)stickerWrapper.contentView;
            VEStickerPinStatus curStatus = [[self editService].sticker getStickerPinStatus:infoContentView.stickerId];
            VEStickerPinStatus originStatus = [originPinStatus[@(infoContentView.stickerId)] integerValue];
            infoContentView.transparent = NO;

            if (curStatus != originStatus &&
                originStatus == VEStickerPinStatus_Pinned) {
                IESInfoStickerProps *props = cmpDict[@(infoContentView.stickerId)].stickerInfos;

                if (props) {
                    ACCStickerGeometryModel *geoModel = [stickerWrapper.stickerGeometry copy];
                    geoModel.x = [[NSDecimalNumber alloc] initWithFloat:props.offsetX];
                    geoModel.y = [[NSDecimalNumber alloc] initWithFloat:-props.offsetY];
                    geoModel.rotation = [[NSDecimalNumber alloc] initWithFloat:props.angle];
                    geoModel.scale = [[NSDecimalNumber alloc] initWithFloat:props.scale];

                    [stickerWrapper recoverWithGeometryModel:geoModel];
                    stickerWrapper.hidden = NO;
                    if ([stickerWrapper isKindOfClass:ACCBaseStickerView.class]) {
                        ACCBaseStickerView *baseStickerWrapper = (id)stickerWrapper;
                        baseStickerWrapper.foreverHidden = NO;
                    }
                    infoContentView.stickerInfos = props;
                }
            }

            if (curStatus != VEStickerPinStatus_Pinned) {
                [[self editService].sticker setSticker:infoContentView.stickerId
                                                  offsetX:infoContentView.stickerInfos.offsetX
                                                  offsetY:infoContentView.stickerInfos.offsetY
                                                    angle:infoContentView.stickerInfos.angle
                                                    scale:1.0];
                [[self editService].sticker setStickerScale:infoContentView.stickerId scale:infoContentView.stickerInfos.scale];
                [[self editService].sticker setSticker:infoContentView.stickerId
                                            startTime:infoContentView.stickerInfos.startTime
                                             duration:infoContentView.stickerInfos.duration];
            }
        }
    }];

    NSArray<ACCStickerTypeId> *typeIds = [[ACCStickerGroup commonInfoStickerIds] mtl_arrayByRemovingObject:ACCStickerTypeIdInfo];
    [typeIds enumerateObjectsUsingBlock:^(ACCStickerTypeId _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [[self.stickerContainer stickerViewsWithTypeId:obj] enumerateObjectsUsingBlock:^(ACCStickerViewType  _Nonnull stickerWrapper, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([stickerWrapper.contentView conformsToProtocol:@protocol(ACCStickerEditContentProtocol)]) {
                UIView<ACCStickerEditContentProtocol> *contentView = (id)stickerWrapper.contentView;
                contentView.transparent = NO;
            }
        }];
    }];
}

- (NSDictionary<NSNumber *, NSNumber *> *)backupStickerInfosPinStatus
{
    NSMutableDictionary *pinStatusDict = [[NSMutableDictionary alloc] init];
    [[self.stickerContainer stickerViewsWithTypeId:ACCStickerTypeIdInfo] enumerateObjectsUsingBlock:^(ACCStickerViewType  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.contentView isKindOfClass:ACCInfoStickerContentView.class]) {
            ACCInfoStickerContentView *infoContentView = (id)obj.contentView;
            VEStickerPinStatus status = [[self editService].sticker getStickerPinStatus:infoContentView.stickerId];

            pinStatusDict[@(infoContentView.stickerId)] = @(status);
        }
    }];

    return pinStatusDict;
}

@end
