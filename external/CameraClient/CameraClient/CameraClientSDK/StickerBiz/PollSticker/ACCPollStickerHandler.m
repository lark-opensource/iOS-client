//
//  ACCPollStickerHandler.m
//  CameraClient-Pods-DouYin
//
//  Created by guochenxiang on 2020/9/7.
//

#import "ACCPollStickerHandler.h"
#import "ACCPollStickerView.h"
#import <CreativeKit/NSArray+ACCAdditions.h>
#import "ACCPollStickerConfig.h"
#import <CreationKitArch/AWEInteractionStickerLocationModel+ACCSticker.h>
#import "ACCStickerDataProvider.h"
#import <CreativeKit/ACCMacros.h>
#import "ACCPollStickerEditView.h"
#import <CreationKitInfra/ACCLogProtocol.h>
#import "ACCStickerBizDefines.h"
#import "AWEPollStickerView.h"
#import "ACCConfigKeyDefines.h"

@interface ACCPollStickerHandler ()

@property (nonatomic, strong) ACCPollStickerEditView *editView;

@end

@implementation ACCPollStickerHandler

#pragma mark - ACCStickerHandler

- (void)addInteractionStickerInfoToArray:(nonnull NSMutableArray *)interactionStickers idx:(NSInteger)stickerIndex
{
    for (UIView<ACCStickerProtocol> *sticker in [[self.stickerContainerView stickerViewsWithTypeId:ACCStickerTypeIdPoll] acc_filter:^BOOL(ACCStickerViewType  _Nonnull item) {
        return [item.contentView isKindOfClass:[ACCPollStickerView class]];
    }]) {
        [self addPollInteractionStickerInfo:sticker toArray:interactionStickers idx:stickerIndex];
    }
}

- (void)addPollInteractionStickerInfo:(UIView<ACCStickerProtocol> *)stickerView toArray:(nonnull NSMutableArray *)interactionStickers idx:(NSInteger)stickerIndex
{
    ACCPollStickerView *pollSticker = (ACCPollStickerView *)(stickerView.contentView);
    AWEInteractionStickerModel *interactionStickerInfo = pollSticker.model;
    CGPoint point = [pollSticker convertPoint:pollSticker.center toView:[stickerView.stickerContainer containerView]];
    AWEInteractionStickerLocationModel *locationInfoModel = [[AWEInteractionStickerLocationModel alloc] initWithGeometryModel:[stickerView interactiveStickerGeometryWithCenterInPlayer:point interactiveBoundsSize:pollSticker.bounds.size] andTimeRangeModel:stickerView.stickerTimeRange];
    if (locationInfoModel.width && locationInfoModel.height) {
        AWEInteractionStickerLocationModel *finalLocation = [self.player resetStickerLocation:locationInfoModel isRecover:NO];
        if (finalLocation) {
            NSError *error = nil;
            NSArray *arr = [MTLJSONAdapter JSONArrayFromModels:@[finalLocation] error:&error];
            NSData *arrJsonData = [NSJSONSerialization dataWithJSONObject:arr options:kNilOptions error:&error];
            if (error) {
                AWELogToolError(AWELogToolTagEdit, @"[addPollInteractionStickerInfo] -- error:%@", error);
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

- (void)apply:(nullable UIView<ACCStickerProtocol> *)sticker index:(NSUInteger)idx
{
    !self.onStickerApplySuccess ?: self.onStickerApplySuccess();
}

- (BOOL)canHandleSticker:(UIView<ACCStickerProtocol> *)sticker
{
    return [sticker.contentView isKindOfClass:[ACCPollStickerView class]];
}

- (BOOL)canRecoverSticker:(ACCRecoverStickerModel *)sticker
{
    return sticker.interactionSticker.trackInfo && (sticker.interactionSticker.type == AWEInteractionStickerTypePoll);
}

- (void)recoverSticker:(nonnull ACCRecoverStickerModel *)sticker
{
    if ([self canRecoverSticker:sticker]) {
        AWEInteractionStickerModel *pollStickerModel = [sticker.interactionSticker copy];
        pollStickerModel.voteInfo = [sticker.interactionSticker.voteInfo copy];
        if (pollStickerModel) {
            ACCPollStickerView *pollStickerView = [self currentPollStickerView];
            if (pollStickerView == nil) {
                pollStickerView = [self addPollStickerWithModel:pollStickerModel];
            } else {
                [pollStickerView updateWithModel:pollStickerModel];
            }
            [pollStickerView.stickerView updateOptionsConstraints];
            pollStickerView.isDraftRecover = YES;
        }
    }
}

- (void)reset
{
    
}

- (AWEInteractionStickerLocationModel *)adaptedLocationWithInteractionInfo:(AWEInteractionStickerModel *)info
{
    AWEInteractionStickerLocationModel *location = [self locationModelFromInteractionInfo:info];
        
    if (self.player && (info.adaptorPlayer || self.dataProvider.isDraftBefore710)) {
        location = [self.player resetStickerLocation:location isRecover:YES];
    }
    
    return location;
}

#pragma mark - public

- (ACCPollStickerView *)addPollStickerWithModel:(AWEInteractionStickerModel *)model
{
    if (!model) {
        return nil;
    }
    
    ACCPollStickerView *pollStickerView = [[ACCPollStickerView alloc] initWithStickerModel:model];
    pollStickerView.effectIdentifier = model.voteID;
    @weakify(self);
    pollStickerView.triggerDragDeleteCallback = ^{
        @strongify(self);
        [self.logger logStickerViewWillDeleteWithEnterMethod:@"drag"];
    };
    ACCPollStickerConfig *config = [[ACCPollStickerConfig alloc] init];
    if (ACCConfigBool(ACCConfigBOOL_allow_sticker_delete)) {
        @weakify(self);
        @weakify(pollStickerView);
        config.deleteAction = ^{
            @strongify(self);
            @strongify(pollStickerView);
            [self.logger logStickerViewWillDeleteWithEnterMethod:@"click"];
            [self.stickerContainerView removeStickerView:pollStickerView];
        };
    }
    config.editPoll = ^{
        @strongify(self);
        [self editPollStickerView:pollStickerView];
    };
    config.secondTapCallback = ^(__kindof ACCBaseStickerView<ACCGestureResponsibleStickerProtocol> * _Nonnull contentView, UITapGestureRecognizer * _Nonnull gesture) {
        @strongify(self);
        [pollStickerView updateEditTypeWithTap:gesture];
        [self editPollStickerView:pollStickerView];
    };
    [config setWillDeleteCallback:^{
        @strongify(self);
        ACCBLOCK_INVOKE(self.onStickerWillDelete, [self currentPollStickerView].effectIdentifier);
    }];
    
    config.typeId = @"poll";
    config.hierarchyId = @(ACCStickerHierarchyTypeVeryHigh);
    config.timeRangeModel.pts = [NSDecimalNumber decimalNumberWithString:@"-1"];
    config.gestureInvalidFrameValue = self.dataProvider.gestureInvalidFrameValue;
    CGFloat realStartTime = 0.f;
    CGFloat realDuration = self.player.stickerInitialEndTime;
    NSString *startTime = [NSString stringWithFormat:@"%.4f", realStartTime];
    NSString *endTime = [NSString stringWithFormat:@"%.4f", realDuration];
    config.timeRangeModel.startTime = [NSDecimalNumber decimalNumberWithString:startTime];
    config.timeRangeModel.endTime = [NSDecimalNumber decimalNumberWithString:endTime];
    AWEInteractionStickerLocationModel *locationModel = [self locationModelFromInteractionInfo:model];
    if (!locationModel) {
        locationModel = [[AWEInteractionStickerLocationModel alloc] init];
    }
    config.geometryModel = [locationModel ratioGeometryModel];
    [self.stickerContainerView addStickerView:pollStickerView config:config];
    return pollStickerView;
}

- (void)editPollStickerView:(ACCPollStickerView *)stickerView
{
    [self.stickerContainerView.overlayView addSubview:self.editView];
    [self.editView startEditStickerView:stickerView];
}

- (ACCPollStickerView *)currentPollStickerView
{
    ACCPollStickerView *pollStickerView = nil;
    NSArray<UIView <ACCStickerContentProtocol> *> *pollStickerViewList = [[self.stickerContainerView stickerViewsWithTypeId:ACCStickerTypeIdPoll] acc_mapObjectsUsingBlock:^id _Nonnull(__kindof ACCBaseStickerView * _Nonnull obj, NSUInteger idex) {
        return [obj contentView];
    }];
    pollStickerView = (ACCPollStickerView *)[pollStickerViewList acc_match:^BOOL(UIView<ACCStickerContentProtocol> * _Nonnull item) {
        return  [item isKindOfClass:[ACCPollStickerView class]];
    }];
    return pollStickerView;
}

#pragma mark - getter

- (ACCPollStickerEditView *)editView
{
    if (!_editView) {
        _editView = [[ACCPollStickerEditView alloc] initWithFrame:CGRectMake(0, 0, ACC_SCREEN_WIDTH, ACC_SCREEN_HEIGHT)];
        @weakify(self);
        _editView.startEditBlock = ^{
            @strongify(self);
            ACCBLOCK_INVOKE(self.editViewOnStartEdit, [self currentPollStickerView].effectIdentifier);
        };
        _editView.finishEditBlock = ^{
            @strongify(self);
            ACCBLOCK_INVOKE(self.editViewOnFinishEdit, [self currentPollStickerView].effectIdentifier);
        };
        _editView.takeScreenShotRecover = ^(ACCPollStickerView * _Nonnull stickerView) {
            @strongify(self);
            [self editPollStickerView:stickerView];
        };
    }
    return _editView;
}

@end
