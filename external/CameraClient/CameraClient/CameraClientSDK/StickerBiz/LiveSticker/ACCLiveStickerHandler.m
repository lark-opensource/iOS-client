//
//  ACCLiveStickerHandler.m
//  CameraClient-Pods-Aweme
//
//  Created by 卜旭阳 on 2021/1/4.
//

#import "ACCLiveStickerHandler.h"
#import "ACCLiveStickerView.h"
#import <CameraClient/AWEInteractionStickerModel+DAddition.h>
#import "ACCLiveStickerEditView.h"
#import "ACCLiveStickerConfig.h"
#import "ACCStickerBizDefines.h"
#import "AWEInteractionLiveStickerModel.h"
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreationKitArch/AWEInteractionStickerLocationModel+ACCSticker.h>
#import <CreationKitArch/ACCUserServiceProtocol.h>
#import "ACCConfigKeyDefines.h"
#import "ACCModernLiveStickerView.h"
#import "ACCStickerSafeAreaUtils.h"
#import "ACCConfigKeyDefines.h"

#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/UIFont+ACCAdditions.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreationKitArch/ACCRepoContextModel.h>

@interface ACCLiveStickerHandler()

@property (nonatomic, weak) ACCLiveStickerView *currentStickerView;

@property (nonatomic, weak) ACCLiveStickerEditView *editView;

@property (nonatomic, weak) UILabel *hintLabel;

@end

@implementation ACCLiveStickerHandler

- (BOOL)enableLiveSticker
{
    return [self.dataProvider hasLived] && [IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) isLogin] && ![IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) isChildMode];
}

- (void)changeStickerStatus:(BOOL)show
{
    self.currentStickerView.hidden = !show;
}

- (void)addLiveSticker:(AWEInteractionLiveStickerModel *)model fromRecover:(BOOL)fromRecover fromAuto:(BOOL)fromAuto
{
    if (!self.currentStickerView) {
        ACCLiveStickerView *stickerView = [ACCModernLiveStickerView createLiveStickerViewWithModel:model];
        @weakify(self);
        stickerView.triggerDragDeleteCallback = ^{
            @strongify(self);
            [self.logger logStickerViewWillDeleteWithEnterMethod:@"drag"];
        };
        ACCLiveStickerConfig *stickerConfig = [[ACCLiveStickerConfig alloc] init];
        stickerView.hasEdited = fromRecover;
        stickerConfig.typeId = ACCStickerTypeIdLive;
        stickerConfig.minimumScale = 0.6;
        stickerConfig.maximumScale = 1.1;
        stickerConfig.hierarchyId = @(ACCStickerHierarchyTypeHigh);
        stickerConfig.timeRangeModel.pts = [NSDecimalNumber decimalNumberWithString:@"-1"];
        stickerConfig.gestureInvalidFrameValue = self.dataProvider.gestureInvalidFrameValue;
        stickerConfig.boxMargin = UIEdgeInsetsMake(10.f, 10.f, 10.f, 10.f);
        stickerConfig.boxPadding = UIEdgeInsetsMake(6, 6, 6, 6);
        NSString *startTime = [NSString stringWithFormat:@"%.4f", 0.f];
        NSString *endTime = [NSString stringWithFormat:@"%.4f", self.player.stickerInitialEndTime];
        stickerConfig.timeRangeModel.startTime = [NSDecimalNumber decimalNumberWithString:startTime];
        stickerConfig.timeRangeModel.endTime = [NSDecimalNumber decimalNumberWithString:endTime];
        
        if (ACCConfigBool(ACCConfigBOOL_allow_sticker_delete)) {
            @weakify(self);
            @weakify(stickerView);
            stickerConfig.deleteAction = ^{
                @strongify(self);
                @strongify(stickerView);
                [self.logger logStickerViewWillDeleteWithEnterMethod:@"click"];
                [self.stickerContainerView removeStickerView:stickerView];
            };
        }

        stickerConfig.secondTapCallback = ^(__kindof ACCBaseStickerView<ACCGestureResponsibleStickerProtocol> * _Nonnull contentView, UITapGestureRecognizer * _Nonnull gesture) {
            @strongify(self);
            [self startEdit:NO];
        };
        stickerConfig.editLive = ^{
            @strongify(self);
            [self startEdit:NO];
        };
        
        AWEInteractionStickerLocationModel *locationModel = [self adaptedLocationWithInteractionInfo:model];
        if (!locationModel) {
            locationModel = [[AWEInteractionStickerLocationModel alloc] init];
        }
        stickerConfig.geometryModel = [locationModel ratioGeometryModel];
        stickerView.extraAttr = model.attr;
        UIView<ACCStickerProtocol> *wrapper = [self.stickerContainerView addStickerView:stickerView config:stickerConfig];
        
        self.currentStickerView = stickerView;
        if (fromAuto) {
            stickerView.alpha = 0.75;
        }
        if (!fromRecover) {
            [self moveToAutoAddPlace:wrapper];
        }
    }
    if (!fromRecover) {
        [self startEdit:YES];
    }
}

- (void)moveToAutoAddPlace:(UIView<ACCStickerProtocol> *)stickerView
{
    // 和安全区左下角对齐
    UIEdgeInsets insets = [ACCStickerSafeAreaUtils safeAreaInsetsWithPlayerFrame:self.stickerContainerView.playerRect containerFrame:self.stickerContainerView.frame];
    stickerView.acc_left = insets.left;
    stickerView.acc_bottom = insets.bottom;
}

- (void)startEdit:(BOOL)showHint
{
    [self.hintLabel removeFromSuperview];
    if (!self.editView) {
        ACCLiveStickerEditView *editView = [[ACCLiveStickerEditView alloc] initWithFrame:self.stickerContainerView.overlayView.bounds];
        @weakify(self);
        editView.editDidCompleted = ^{
            @strongify(self);
            [self trackForEnterLiveStickerEvent:@"livesdk_live_announce_open"];
            ACCBLOCK_INVOKE(self.editViewOnFinishEdit);
            if (showHint) {
                [self showHintView];
            }
        };
        [self.stickerContainerView.overlayView addSubview:editView];
        self.editView = editView;
    }
    [self.editView startEditSticker:self.currentStickerView];
    [self trackForEnterLiveStickerEvent:@"livesdk_live_announce_setting_show"];
    ACCBLOCK_INVOKE(self.editViewOnStartEdit);
}

- (void)showHintView
{
    if (self.currentStickerView) {
        UILabel *hintLabel = [[UILabel alloc] init];
        hintLabel.textColor = [UIColor whiteColor];
        hintLabel.font = [UIFont acc_systemFontOfSize:14.f weight:ACCFontWeightRegular];
        hintLabel.text = @"可移动至合适位置";
        hintLabel.textAlignment = NSTextAlignmentCenter;
        hintLabel.bounds = CGRectMake(0.f, 0.f, 124.f, 22.f);
        self.hintLabel = hintLabel;
        
        UIView *wrapper = self.currentStickerView.superview;
        hintLabel.acc_centerX = wrapper.acc_width/2;
        hintLabel.acc_bottom = -4.f;
        [wrapper addSubview:hintLabel];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [hintLabel removeFromSuperview];
        });
    }
}

#pragma mark - Track
- (void)trackForEnterLiveStickerEvent:(NSString *)event
{
    NSDictionary *params = @{
        @"shoot_way":self.dataProvider.referString?:@"",
        @"enter_from":@"trailer_prop",
        @"anchor_id":[IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) currentLoginUserModel].userID?:@"",
        @"live_announce_time":@(self.currentStickerView.liveInfo.targetTime).stringValue
    };
    [ACCTracker() trackEvent:event params:params needStagingFlag:NO];
}


#pragma mark getter&generate

- (void)addInteractionStickerInfoToArray:(nonnull NSMutableArray *)interactionStickers idx:(NSInteger)stickerIndex
{
    for (UIView<ACCStickerProtocol> *sticker in [[self.stickerContainerView stickerViewsWithTypeId:ACCStickerTypeIdLive] acc_filter:^BOOL(ACCStickerViewType  _Nonnull item) {
        return [item.contentView isKindOfClass:[ACCLiveStickerView class]];
    }]) {
        [self addLiveInteractionStickerInfo:sticker toArray:interactionStickers idx:stickerIndex];
    }
}

- (void)addLiveInteractionStickerInfo:(UIView<ACCStickerProtocol> *)stickerView toArray:(nonnull NSMutableArray *)interactionStickers idx:(NSInteger)stickerIndex
{
    ACCLiveStickerView *liveSticker = (ACCLiveStickerView *)(stickerView.contentView);
    AWEInteractionLiveStickerModel *interactionStickerInfo = [[AWEInteractionLiveStickerModel alloc] init];
    interactionStickerInfo.type = AWEInteractionStickerTypeLive;
    interactionStickerInfo.liveInfo = liveSticker.liveInfo;
    interactionStickerInfo.attr = liveSticker.extraAttr;
    
    CGPoint point = [liveSticker convertPoint:liveSticker.center toView:[stickerView.stickerContainer containerView]];
    AWEInteractionStickerLocationModel *locationInfoModel = [[AWEInteractionStickerLocationModel alloc] initWithGeometryModel:[stickerView interactiveStickerGeometryWithCenterInPlayer:point interactiveBoundsSize:liveSticker.bounds.size] andTimeRangeModel:stickerView.stickerTimeRange];
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
            
            interactionStickerInfo.index = [interactionStickers count] + stickerIndex;
            interactionStickerInfo.adaptorPlayer = [self.player needAdaptPlayer];
            [interactionStickers addObject:interactionStickerInfo];
        }
    }
}

- (BOOL)canHandleSticker:(nonnull UIView<ACCStickerProtocol> *)sticker
{
    return [sticker.contentView isKindOfClass:ACCLiveStickerView.class];
}

- (BOOL)canRecoverSticker:(nonnull ACCRecoverStickerModel *)sticker
{
    if (self.dataProvider.isKaraokeMode && sticker.sourceType == IESVideoSourceTypeRecord) return NO;
    return sticker.interactionSticker.trackInfo && sticker.interactionSticker.type == AWEInteractionStickerTypeLive;
}

- (void)recoverSticker:(nonnull ACCRecoverStickerModel *)sticker
{
    if ([self canRecoverSticker:sticker]) {
        AWEInteractionStickerModel *liveStickerModel = [sticker.interactionSticker copy];
        if ([liveStickerModel isKindOfClass:[AWEInteractionLiveStickerModel class]] && liveStickerModel && ((AWEInteractionLiveStickerModel *)liveStickerModel).liveInfo) {
            [self addLiveSticker:(AWEInteractionLiveStickerModel *)liveStickerModel fromRecover:YES fromAuto:NO];
        }
    }
}

@end
