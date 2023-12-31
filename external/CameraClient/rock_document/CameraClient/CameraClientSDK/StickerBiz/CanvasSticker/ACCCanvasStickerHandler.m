//
//  ACCCanvasStickerHandler.m
//  CameraClient-Pods-Aweme
//
//  Created by hongcheng on 2020/12/28.
//

#import "ACCCanvasStickerHandler.h"
#import "AWERepoVideoInfoModel.h"
#import <CreativeKitSticker/ACCStickerContainerProtocol.h>
#import "ACCStickerBizDefines.h"
#import <CreationKitArch/AWEInteractionStickerModel.h>
#import <CreationKitArch/AWEInteractionStickerLocationModel+ACCSticker.h>
#import <CameraClient/AWEInteractionVideoShareStickerModel.h>
#import <CameraClientModel/ACCVideoCanvasType.h>
#import "AWERepoStickerModel.h"
#import "ACCCanvasStickerContentView.h"
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import "ACCCanvasSinglePhotoStickerConfig.h"
#import "ACCCanvasStickerShareAsStoryConfig.h"
#import "ACCCanvasStickerVideoConfig.h"
#import "ACCRepoQuickStoryModel.h"
#import "ACCRepoCanvasModel.h"
#import <CreativeKitSticker/ACCStickerUtils.h>
#import <TTVideoEditor/IESMMCanvasSource.h>
#import "AWERepoUploadInfomationModel.h"

@interface ACCCanvasStickerHandler ()

@property (nonatomic, weak) AWEVideoPublishViewModel *repository;

@end

@implementation ACCCanvasStickerHandler

- (instancetype)initWithRepository:(AWEVideoPublishViewModel *)repository
{
    self = [super init];
    if (self) {
        _repository = repository;
    }
    return self;
}

- (BOOL)supportCanvas
{
    return (self.repository.repoVideoInfo.canvasType != ACCVideoCanvasTypeNone && self.repository.repoVideoInfo.canvasType != ACCVideoCanvasTypeDuet);
}

- (IESMMCanvasSource *)getCanvasSource
{
    IESMMCanvasSource *source = self.repository.repoVideoInfo.video.canvasInfo.allValues.firstObject;
    if (source != nil) {
        return [source copy];
    } else {
        return [self.repository.repoCanvas.source copy];
    }
}

- (ACCCanvasStickerConfig *)setupCanvasSticker
{
    if (![self supportCanvas]) {
        return nil;
    }
    ACCCanvasStickerContentView *stickerView = [[ACCCanvasStickerContentView alloc] initWithFrame:self.editService.mediaContainerView.bounds];
    ACCCanvasStickerConfig *config = nil;
    if (self.repository.repoQuickStory.isAvatarQuickStory || self.repository.repoQuickStory.isNewCityStory) {
        config = [[ACCCanvasStickerConfig alloc] init];
    } else if (self.repository.repoVideoInfo.canvasType == ACCVideoCanvasTypeSinglePhoto || self.repository.repoVideoInfo.canvasType == ACCVideoCanvasTypeLivePhoto) { // live photo as single photo
        config = [[ACCCanvasSinglePhotoStickerConfig alloc] init];
    } else if (self.repository.repoVideoInfo.canvasType == ACCVideoCanvasTypeShareAsStory) {
        config = [[ACCCanvasStickerShareAsStoryConfig alloc] init];
        
        ACCStickerGestureType supportedGestureType = config.supportedGestureType;
        config.supportGesture = ^BOOL(ACCStickerGestureType gestureType, id  _Nullable contextId, UIGestureRecognizer * _Nonnull gestureRecognizer) {
            return supportedGestureType & gestureType;
        };
    } else if (self.repository.repoVideoInfo.canvasType == ACCVideoCanvasTypeRePostVideo) {
        config = [[ACCCanvasStickerVideoConfig alloc] init];
    }
    if (self.repository.repoCanvas.minimumScale != nil) {
        config.minimumScale = [self.repository.repoCanvas.minimumScale doubleValue];
    }
    if (self.repository.repoCanvas.maximumScale != nil) {
        config.maximumScale = [self.repository.repoCanvas.maximumScale doubleValue];
    }
    config.groupId = self.repository.repoCanvas.groupId;
    config.typeId = ACCStickerTypeIdCanvas;
    config.deleteable = @(NO);
    config.hierarchyId = @(ACCStickerHierarchyTypeVeryVeryLow);
    config.timeRangeModel.pts = [NSDecimalNumber decimalNumberWithString:@"-1"];
    
    NSString *startTime = [NSString stringWithFormat:@"%.4f", 0.f];
    NSString *endTime = [NSString stringWithFormat:@"%.4f", self.player.stickerInitialEndTime];
    config.timeRangeModel.startTime = [NSDecimalNumber decimalNumberWithString:startTime];
    config.timeRangeModel.endTime = [NSDecimalNumber decimalNumberWithString:endTime];
    
    @weakify(self);
    config.gestureCanStartCallback = ^BOOL(__kindof ACCBaseStickerView<ACCGestureResponsibleStickerProtocol> * _Nonnull contentView, UIGestureRecognizer * _Nonnull gesture) {
        @strongify(self);
        [self.editService.preview setHighFrameRateRender:YES];
        return YES;
    };
    config.gestureEndCallback = ^(__kindof ACCBaseStickerView<ACCGestureResponsibleStickerProtocol> * _Nonnull contentView, UIGestureRecognizer * _Nonnull gesture) {
        @strongify(self);
        [self.editService.preview setHighFrameRateRender:NO];
    };
    
    void (^updatePosition)(__kindof UIView<ACCStickerProtocol> * _Nonnull view) = ^(__kindof UIView<ACCStickerProtocol> * _Nonnull view) {
        @strongify(self);
        CGRect playerBounds = self.editService.mediaContainerView.bounds;
        CGFloat centerX = [view.stickerGeometry.x floatValue] / CGRectGetWidth(playerBounds);
        CGFloat centerY = [view.stickerGeometry.y floatValue] / CGRectGetHeight(playerBounds);
        IESMMCanvasSource *canvasSource = [self getCanvasSource];
        canvasSource.centerPos = CGPointMake(centerX, centerY);
        [self.editService.canvas updateWithVideoInfo:self.repository.repoVideoInfo source:canvasSource];
    };
        
    config.externalHandlePanGestureAction = ^(__kindof UIView<ACCStickerProtocol> * _Nonnull view, CGPoint point) {
        updatePosition(view);
    };
    
    config.externalHandlePinchGestureeAction = ^(__kindof UIView<ACCStickerProtocol> * _Nonnull view, CGFloat scale) {
        @strongify(self);
        IESMMCanvasSource *canvasSource = [self getCanvasSource];;

        updatePosition(view);
        canvasSource.scale = view.stickerGeometry.scale.doubleValue;
        [self.editService.canvas updateWithVideoInfo:self.repository.repoVideoInfo source:canvasSource];
    };
    
    config.externalHandleRotationGestureAction = ^(__kindof UIView<ACCStickerProtocol> * _Nonnull view, CGFloat rotation) {
        @strongify(self);
        IESMMCanvasSource *canvasSource = [self getCanvasSource];;

        CGFloat rotationOfSticker = view.stickerGeometry.rotation.doubleValue;
        canvasSource.rotateAngle = rotationOfSticker >= 0 ? rotationOfSticker : (360 + rotationOfSticker);
        [self.editService.canvas updateWithVideoInfo:self.repository.repoVideoInfo source:canvasSource];
    };
    
    IESMMCanvasSource *canvasSource = [self getCanvasSource];
    CGRect contentBounds = [self frameOfContentInCanvas];
    CGRect playerBounds = self.editService.mediaContainerView.bounds;
    CGRect contentFrame = CGRectMake(canvasSource.centerPos.x * CGRectGetWidth(playerBounds) + CGRectGetWidth(playerBounds)/2 - CGRectGetWidth(contentBounds)/2,
                                      canvasSource.centerPos.y * CGRectGetHeight(playerBounds) + CGRectGetHeight(playerBounds)/2 - CGRectGetHeight(contentBounds)/2,
                                      CGRectGetWidth(contentBounds),
                                      CGRectGetHeight(contentBounds));
    
    CGRect contentFrameInStickerContainerView = [[self.stickerContainerView containerView] convertRect:contentFrame fromView:self.editService.mediaContainerView];
    stickerView.frame = contentFrameInStickerContainerView;
    config.geometryModel = [ACCStickerUtils convertStickerViewFrame:stickerView.frame fromContainerCoordinateSystem:[self.stickerContainerView containerView].frame toPlayerCoordinateSystem:self.editService.mediaContainerView.frame];
    config.geometryModel.scale = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.4f", canvasSource.scale]];
    config.geometryModel.rotation = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.4f", canvasSource.rotateAngle <= 180 ? canvasSource.rotateAngle : canvasSource.rotateAngle - 360]];
    if (self.repository.repoCanvas.minimumScale == nil) {
        config.minimumScale = 32 / MIN(CGRectGetWidth(contentFrameInStickerContainerView), CGRectGetHeight(contentFrameInStickerContainerView));
    }
    
    return [self.stickerContainerView addStickerView:stickerView config:config].config;
}

- (CGSize)videoCanvasSize
{
    AVAsset *avAsset = [self.repository.repoVideoInfo.video.videoAssets firstObject];
    AVAssetTrack *videoTrack = [avAsset tracksWithMediaType:AVMediaTypeVideo].firstObject;
    CGSize naturalSize = videoTrack.naturalSize;
    CGSize temp = CGSizeApplyAffineTransform(naturalSize, videoTrack.preferredTransform);
    return CGSizeMake(fabs(temp.width), fabs(temp.height));
}

- (CGRect)frameOfContentInCanvas
{
    CGSize contentSize = self.repository.repoUploadInfo.toBeUploadedImage.size;
    CGSize videoSize = self.repository.repoVideoInfo.video.normalizeSize;
    if (self.repository.repoCanvas.canvasContentType == ACCCanvasContentTypeVideo) {
        contentSize = [self videoCanvasSize];
    }
    CGFloat contentAspectRatio = contentSize.height / contentSize.width;
    CGFloat videoAspectRatio = videoSize.height / videoSize.width;
    if (self.repository.repoVideoInfo.canvasType == ACCVideoCanvasTypeLivePhoto) {
        contentAspectRatio = self.repository.repoVideoInfo.canvasContentRatio;
        if (contentAspectRatio == 0) {
            contentAspectRatio = videoAspectRatio;
        }
    }
    CGRect frame = self.editService.mediaContainerView.bounds;

    if (contentAspectRatio < videoAspectRatio) {
        frame.origin.y = CGRectGetWidth(self.editService.mediaContainerView.bounds) * (videoAspectRatio - contentAspectRatio) / 2;
        frame.size.height = CGRectGetWidth(self.editService.mediaContainerView.bounds) * contentAspectRatio;
    } else {
        frame.origin.x = CGRectGetHeight(self.editService.mediaContainerView.bounds) * ( 1 / videoAspectRatio - 1 / contentAspectRatio) / 2;
        frame.size.width = CGRectGetHeight(self.editService.mediaContainerView.bounds) / contentAspectRatio;
    }
    
    return frame;
}

- (void)addInteractionStickerInfoToArray:(nonnull NSMutableArray *)interactionStickers idx:(NSInteger)stickerIndex
{
    if (self.repository.repoVideoInfo.canvasType == ACCVideoCanvasTypeShareAsStory) {
        NSArray<ACCStickerViewType> *groupViewArray = [self.stickerContainerView stickerViewsWithTypeId:ACCStickerTypeIdGroup];
        for (ACCStickerViewType groupView in groupViewArray) {
            NSArray<ACCStickerViewType> *subStickerViewArray = [self.stickerContainerView subStickerViewsInGroup:groupView.groupId];
            BOOL containCanvasSticker = NO;
            for (ACCStickerViewType subStickerView in subStickerViewArray) {
                if ([subStickerView.config.typeId isEqual:ACCStickerTypeIdCanvas]) {
                    containCanvasSticker = YES;
                }
            }
            if (containCanvasSticker) {
                [self addInteractionStickerInfoToArray:interactionStickers idx:stickerIndex gropView:groupView];
            }
        }
    }
}


- (void)addInteractionStickerInfoToArray:(nonnull NSMutableArray *)interactionStickers
                                     idx:(NSInteger)stickerIndex
                                gropView:(ACCStickerViewType)groupView
{
    ACCStickerGeometryModel *geoModel = [groupView interactiveStickerGeometryWithCenterInPlayer:groupView.center interactiveBoundsSize:groupView.bounds.size];
    AWEInteractionStickerLocationModel *locationInfoModel = [[AWEInteractionStickerLocationModel alloc] initWithGeometryModel:geoModel andTimeRangeModel:groupView.stickerTimeRange];
    
    AWEInteractionVideoShareStickerModel *interactionModel = [AWEInteractionVideoShareStickerModel new];
    interactionModel.type = AWEInteractionStickerTypeVideoShare;
    interactionModel.index = [interactionStickers count] + stickerIndex;
    interactionModel.adaptorPlayer = [self.player needAdaptPlayer];
    interactionModel.videoShareInfo = self.repository.repoSticker.videoShareInfo;
    
    if (locationInfoModel.width && locationInfoModel.height) {
        AWEInteractionStickerLocationModel *finalLocation = [self.player resetStickerLocation:locationInfoModel isRecover:NO];
        if (!finalLocation) {
            return;
        }
        [interactionModel storeLocationModelToTrackInfo:finalLocation];
    }
    
    [interactionStickers addObject:interactionModel];
}

- (void)apply:(nullable UIView<ACCStickerProtocol> *)sticker index:(NSUInteger)idx {
    
}

- (BOOL)canHandleSticker:(nonnull UIView<ACCStickerProtocol> *)sticker {
    return YES;
}

- (BOOL)canRecoverSticker:(nonnull ACCRecoverStickerModel *)sticker {
    return YES;
}

- (void)finish {
    
}

- (void)recoverSticker:(nonnull ACCRecoverStickerModel *)sticker {
    
}

- (void)reset {
    
}


@end
