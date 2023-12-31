//
//  ACCRecognitionGrootStickerHandler.m
//  CameraClient-Pods-Aweme
//
//  Created by Ryan Yan on 2021/8/23.
//

#import "AWERepoStickerModel.h"
#import "ACCRecognitionGrootStickerHandler.h"

#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreativeKitSticker/ACCStickerUtils.h>

#import "ACCRecognitionGrootStickerViewFactory.h"
#import "ACCRecognitionGrootStickerConfig.h"
#import <CreationKitArch/ACCEditAndPublishConstants.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreationKitInfra/NSData+ACCAdditions.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import <CreationKitArch/AWEDraftUtils.h>
#import "NLESegmentSticker_OC+ACCAdditions.h"
#import "NLETrackSlot_OC+ACCAdditions.h"
#import <CreationKitArch/ACCRepoStickerModel.h>
#import <CameraClient/AWERepoDraftModel.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import "ACCRecognitionEditGrootStickerView.h"
#import "ACCRecognitionService.h"
#import <CameraClient/ACCRecognitionTrackModel.h>
#import "AWEInteractionGrootStickerModel.h"
#import "ACCRecognitionGrootConfig.h"

NSString * const kIsACCRecognitionGrootStickerKey = @"kIsACCRecognitionGrootStickerKey";

@interface ACCRecognitionGrootStickerHandler ()

@property (nonatomic, strong) UIView<ACCStickerProtocol> *stickerWrapView;
@property (nonatomic, strong) ACCRecognitionGrootStickerViewModel *viewModel;
@property (nonatomic, strong) ACCRecognitionGrootStickerView *stickerView;
@property (nonatomic, strong) ACCRecognitionEditGrootStickerView *editGrootStickerView;

@end

@implementation ACCRecognitionGrootStickerHandler

@synthesize willDeleteCallback;

- (instancetype)initWithGrootStickerViewModel:(ACCRecognitionGrootStickerViewModel *)viewModel
                                 viewWithType:(ACCRecognitionStickerViewType)viewType
{
    self = [super init];
    if (self) {
        self.viewModel = viewModel;
        self.viewModel.grootStickerHandler = self;
        self.stickerView = [ACCRecognitionGrootStickerViewFactory viewWithType:viewType];
        self.stickerView.delegate = self.viewModel;

        @weakify(self)
        [[[RACObserve(self.stickerView, currentScale) takeUntil:self.rac_willDeallocSignal] skip:1] subscribeNext:^(NSNumber * _Nullable x) {
            @strongify(self)
            self.recognitionService.trackModel.grootModel.scale = x.floatValue;
        }];
    }
    return self;
}

- (void)updateStickerViewByDetailStickerModel:(ACCGrootDetailsStickerModel *)detailStickerModel
{
    [self.stickerView configWithModel:detailStickerModel];
}

- (void)removeGrootSticker
{
    ACCRecognitionGrootStickerView *stickerView = self.stickerView;
    [self.stickerContainerView removeStickerView:stickerView];
}

- (ACCRecognitionGrootStickerView *)addGrootStickerWithModel:(ACCGrootStickerModel *)model
{
    if (!model) {
        return nil;
    }
    [self.stickerView configWithModel:model.selectedGrootStickerModel];
    ACCRecognitionGrootStickerView *stickerView = self.stickerView;
    @weakify(self);
    stickerView.triggerDragDeleteCallback = ^{
        @strongify(self);
        ACCRecognitionTrackModel *trackModel = [self.viewModel.repository extensionModelOfClass:ACCRecognitionTrackModel.class];
        trackModel.grootModel = nil;
        [self.stickerContainerView removeStickerView:self.stickerView];
        [self.logger logStickerViewWillDeleteWithEnterMethod:@"drag"];
        [self.viewModel trackGrootStickerPropDelete:@"video_shoot_page"];
    };

    CGPoint topLeftPoint = [self getTopLeftPosition:stickerView];
    ACCStickerGeometryModel *geometryModel = [ACCStickerUtils convertStickerViewFrame:CGRectMake(topLeftPoint.x,
                                                                                                 topLeftPoint.y,
                                                                                                 stickerView.frame.size.width,
                                                                                                 stickerView.frame.size.height)
                                                        fromContainerCoordinateSystem:self.stickerContainerView.originalFrame
                                                             toPlayerCoordinateSystem:[self.stickerContainerView playerRect]];

    ACCRecognitionGrootStickerConfig *config = [[ACCRecognitionGrootStickerConfig alloc] init];
    config.showSelectedHint = NO;
    // update time range
    NSString *startTime = [NSString stringWithFormat:@"%.4f", 0.f];
    NSString *endTime = [NSString stringWithFormat:@"%.4f", 0.f];
    config.timeRangeModel.startTime = [NSDecimalNumber decimalNumberWithString:startTime];
    config.timeRangeModel.endTime = [NSDecimalNumber decimalNumberWithString:endTime];
//    config.boxMargin = UIEdgeInsetsMake(10.f, 10.f, 10.f, 10.f);
//    config.boxPadding = UIEdgeInsetsMake(6, 6, 6, 6);

    // update position
    config.geometryModel = geometryModel;
    config.typeId = ACCStickerTypeIdGroot;
    config.hierarchyId = @(ACCStickerHierarchyTypeNormal);
    config.timeRangeModel.pts = [NSDecimalNumber decimalNumberWithString:@"-1"];
    config.minimumScale = 0.6;

    // added grootSticker
    [self.stickerContainerView addStickerView:stickerView config:config];
    return stickerView;
}

- (void)editStickerView
{
    [self setupEditViewIfNeed];
    [self.stickerContainerView.overlayView addSubview:self.editGrootStickerView];
    [self.editGrootStickerView startEditStickerView:self.stickerView];
}

- (void)setupEditViewIfNeed
{
    if (self.editGrootStickerView) {
        return;
    }
    self.editGrootStickerView = [[ACCRecognitionEditGrootStickerView alloc] init];

    @weakify(self);
    self.editGrootStickerView.startEditBlock = ^(ACCRecognitionGrootStickerView *stickerView) {
        @strongify(self);
        ACCBLOCK_INVOKE(self.editViewOnStartEdit);
    };

    self.editGrootStickerView.onEditFinishedBlock = ^(ACCRecognitionGrootStickerView *stickerView) {
        @strongify(self);
        [self.editGrootStickerView removeFromSuperview];
    };
}

- (void)stopEditStickerView
{
    [self.editGrootStickerView stopEdit];
}

#pragma mark - Private Methods

- (void)p_addInteractionStickerInfoWith:(UIView<ACCStickerProtocol> *)stickerView
                                toArray:(NSMutableArray *)interactionStickers
                                    idx:(NSInteger)stickerIndex {
    ACCRecognitionGrootStickerView *grootStickerView = (ACCRecognitionGrootStickerView *)(stickerView.contentView);

    AWEInteractionStickerModel *interactionStickerInfo = nil;

    { /* ························· server data binding unit ··························· */

        // added keyvalue  to server  by manual , auto serialization may case property name changed
        interactionStickerInfo = [[AWEInteractionGrootStickerModel alloc] init];
        interactionStickerInfo.type = AWEInteractionStickerTypeGroot;
        NSMutableDictionary *grootInteraction = [NSMutableDictionary dictionaryWithCapacity:3];
        ACCGrootDetailsStickerModel *grootDetailModel = grootStickerView.stickerModel;
        if (grootDetailModel) {
            NSDictionary *userGrootInfo = @{
                @"species_name"  : grootDetailModel.speciesName ?: @"",
                @"common_name"  : grootDetailModel.commonName ?: @"",
                @"category_name"  : grootDetailModel.categoryName ?: @"",
                @"prob" : grootDetailModel.prob ?: @0,
                @"baike_id" : grootDetailModel.baikeId ?: @0,
                @"baike_image" : grootDetailModel.baikeHeadImage ?: @0
            };
            [grootInteraction addEntriesFromDictionary:@{
                @"type": @(AWEInteractionStickerTypeGroot) ?: @0,
                @"index": @([interactionStickers count] + stickerIndex) ?: @0}];
            [grootInteraction addEntriesFromDictionary:@{@"user_groot_info" : userGrootInfo}];
            ((AWEInteractionGrootStickerModel *)interactionStickerInfo).grootInteraction = grootInteraction;
            // attr
            NSDictionary *attr = @{@"groot_sticker_id":[ACCRecognitionGrootConfig grootStickerId], @"recognition_groot": @YES};
            NSError *error = nil;
            NSData *data = [NSJSONSerialization dataWithJSONObject:attr options:kNilOptions error:&error];
            if (error) {
                AWELogToolError2(@"groot_sticker", AWELogToolTagRecord | AWELogToolTagEdit, @"ACCRecognitionGrootStickerHandler JSONArrayFromModels failed: %@", error);
            }
            NSString *attrStr = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
            interactionStickerInfo.attr = attrStr;
        } else {
            AWELogToolError2(@"Groot", AWELogToolTagEdit, @"add GrootInteractionSticker failed, groot selected model is null.");
        }
    }

    /* ·························  model create unit ··························· */
    if (interactionStickerInfo == nil) {
        interactionStickerInfo = [AWEInteractionStickerModel new];
    }

    interactionStickerInfo.stickerID = [ACCRecognitionGrootConfig grootStickerId];
    interactionStickerInfo.type = AWEInteractionStickerTypeGroot;
    interactionStickerInfo.localStickerUniqueId = [NSUUID UUID].UUIDString;
    interactionStickerInfo.index = [interactionStickers count] + stickerIndex;
    interactionStickerInfo.adaptorPlayer = YES;

    /* Location Model */
    CGPoint point = [stickerView convertPoint:grootStickerView.center toView:[stickerView.stickerContainer containerView]];
    AWEInteractionStickerLocationModel *locationInfoModel = [[AWEInteractionStickerLocationModel alloc]
                                                             initWithGeometryModel:[stickerView
                                                                                    interactiveStickerGeometryWithCenterInPlayer:point
                                                                                    interactiveBoundsSize:grootStickerView.bounds.size]
                                                             andTimeRangeModel:stickerView.stickerTimeRange];
    if (locationInfoModel.width && locationInfoModel.height) {
        AWEInteractionStickerLocationModel *finalLocation = self.player ? [self.player resetStickerLocation:locationInfoModel isRecover:NO] : locationInfoModel;
        if (finalLocation) {
            NSError *error = nil;
            NSArray *arr = [MTLJSONAdapter JSONArrayFromModels:@[finalLocation] error:&error];
            NSData *arrJsonData = [NSJSONSerialization dataWithJSONObject:arr options:kNilOptions error:&error];
            if (error) {
                AWELogToolError(AWELogToolTagEdit, @"[addLiveInteractionStickerInfo] -- error:%@", error);
            }
            if (arrJsonData) {
                NSString *arrJsonStr = [[NSString alloc] initWithData:arrJsonData encoding:NSUTF8StringEncoding];
                interactionStickerInfo.trackInfo = arrJsonStr;
            }
        }
        [interactionStickers acc_addObject:interactionStickerInfo];
    }
}

- (CGPoint)getTopLeftPosition:(UIView *)view
{
    CGRect frame = view.frame;
    CGFloat marginLeft = 0;
    CGFloat marginTop = 0;
    if ([UIDevice acc_isIPhoneX]) {
        if (@available(iOS 11.0, *)) {
            marginTop += ACC_STATUS_BAR_NORMAL_HEIGHT;
        }
    }
    marginLeft = (ACC_SCREEN_WIDTH - frame.size.width) / 2;
    marginTop += (ACC_SCREEN_HEIGHT / 2);
    CGPoint topLeftPoint = CGPointMake(marginLeft, marginTop);
    
    return topLeftPoint;
}

#pragma mark - ACCStickerHandler protocol methods

- (void)addInteractionStickerInfoToArray:(NSMutableArray *)interactionStickers
                                     idx:(NSInteger)stickerIndex
{
    for (UIView<ACCStickerProtocol> *sticker in [[self.stickerContainerView stickerViewsWithTypeId:ACCStickerTypeIdGroot] acc_filter:^BOOL(ACCStickerViewType  _Nonnull item) {
        return [item.contentView isKindOfClass:[ACCRecognitionGrootStickerView class]];
    }]) {
        [self p_addInteractionStickerInfoWith:sticker toArray:interactionStickers idx:stickerIndex];
    }
}

- (BOOL)canHandleSticker:(UIView<ACCStickerProtocol> *)sticker
{
    return [[sticker contentView] isKindOfClass:[ACCRecognitionGrootStickerView class]];
}

- (void)apply:(nullable UIView<ACCStickerProtocol> *)sticker
        index:(NSUInteger)idx
{

}

- (BOOL)canRecoverSticker:(ACCRecoverStickerModel *)sticker
{
    return YES;
}

- (void)recoverSticker:(ACCRecoverStickerModel *)sticker
{

}

- (void)reset
{

}

- (void)finish
{
    
}

@end
