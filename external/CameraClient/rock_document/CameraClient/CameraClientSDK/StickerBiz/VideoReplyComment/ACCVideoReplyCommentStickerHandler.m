//  视频回复评论二期
//  ACCVideoReplyCommentStickerHandler.m
//  CameraClient-Pods-Aweme
//
//  Created by lixuan on 2021/10/9.
//

#import "ACCVideoReplyCommentStickerHandler.h"
#import "ACCVideoReplyCommentStickerView.h"
#import "ACCVideoReplyCommentWithoutCoverStickerView.h"
#import "ACCVideoReplyCommentStickerConfig.h"
#import "AWEInteractionVideoReplyCommentStickerModel.h"
#import "ACCConfigKeyDefines.h"

#import <CameraClientModel/ACCVideoReplyCommentModel.h>
#import <CreationKitArch/AWEInteractionStickerLocationModel+ACCSticker.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreativeKitSticker/ACCStickerUtils.h>
#import <CreationKitInfra/ACCLogProtocol.h>

@interface ACCVideoReplyCommentStickerHandler ()
@property (nonatomic, strong, readwrite) ACCVideoReplyCommentModel *videoReplyCommentModel;
@end

@implementation ACCVideoReplyCommentStickerHandler

#pragma mark - Public
- (UIView<ACCStickerProtocol> *)addStickerViewWithModel:(ACCVideoReplyCommentModel *)videoReplyCommentModel
                                    locationModel:(AWEInteractionStickerLocationModel *)locationModel
{
    UIView<ACCStickerProtocol> *existingStickerView = [[self.stickerContainerView stickerViewsWithTypeId:ACCStickerTypeIdVideoReplyComment] acc_match:^BOOL(ACCStickerViewType  _Nonnull item) {
        return ([item.contentView isKindOfClass:[ACCVideoReplyCommentStickerView class]] || [item.contentView isKindOfClass:[ACCVideoReplyCommentWithoutCoverStickerView class]]);
    }];
    if (existingStickerView != nil) {
        return existingStickerView;
    }
    
    // Viewtype AB实验
    videoReplyCommentModel.viewType = ACCConfigInt(kConfigInt_comment_sticker_type);
    
    // 不同样式sticker view
    UIView<ACCStickerContentProtocol> *stickerView = nil;
    switch (videoReplyCommentModel.viewType) {
        case ACCVideoReplyCommentViewTypeWithoutCover: {
            stickerView = [[ACCVideoReplyCommentWithoutCoverStickerView alloc] initWithModel:videoReplyCommentModel];
        }
            break;
        case ACCVideoReplyCommentViewTypeWithCover: {
            stickerView = [[ACCVideoReplyCommentStickerView alloc] initWithModel:videoReplyCommentModel];
        }
            break;
    }
    
    ACCVideoReplyCommentStickerConfig *config = [[ACCVideoReplyCommentStickerConfig alloc] init];
    
    // update time range
    config.timeRangeModel.pts = [NSDecimalNumber decimalNumberWithString:@"-1"];
    config.timeRangeModel.startTime = [AWEInteractionStickerLocationModel convertCGFloatToNSDecimalNumber:0.f];
    config.timeRangeModel.endTime = [AWEInteractionStickerLocationModel convertCGFloatToNSDecimalNumber:-1.f];
    
    // update position
    if (locationModel == nil) {
        CGPoint topLeftPosition = [self getTopLeftPosition];
        CGRect stickerViewFrame = CGRectMake(topLeftPosition.x, topLeftPosition.y, stickerView.frame.size.width , stickerView.frame.size.height);
        config.geometryModel = [ACCStickerUtils convertStickerViewFrame:stickerViewFrame
                                          fromContainerCoordinateSystem:self.stickerContainerView.originalFrame
                                               toPlayerCoordinateSystem:[self.stickerContainerView playerRect]];
    }
    else {
        config.geometryModel = [locationModel ratioGeometryModel];
    }
    
    self.videoReplyCommentModel = [videoReplyCommentModel copy];
    
    config.willDeleteCallback = ^{
        [self.delegation willDeleteVideoReplyStickerView];
    };
    if (ACCConfigBool(ACCConfigBOOL_allow_sticker_delete)) {
        @weakify(stickerView);
        @weakify(self);
        config.deleteAction = ^{
            @strongify(stickerView);
            @strongify(self);
            [self.delegation willDeleteVideoReplyStickerView];
            [self.stickerContainerView removeStickerView:stickerView];
        };
    }
    
    // add stickerview to containerview
    UIView<ACCStickerProtocol> *stickerWrapView = [self.stickerContainerView addStickerView:stickerView config:config];
    
    return stickerWrapView;
}

- (void)removeVideoReplyCommentStickerView
{
    NSArray<ACCStickerViewType> *stickerViewList = [self.stickerContainerView stickerViewsWithTypeId:ACCStickerTypeIdVideoReplyComment];
    [stickerViewList enumerateObjectsUsingBlock:^(ACCStickerViewType  _Nonnull stickerView, NSUInteger idx, BOOL * _Nonnull stop) {
        [self.stickerContainerView removeStickerView:stickerView];
    }];
}

#pragma mark - Private

- (CGPoint)getTopLeftPosition
{
    // get the inital position
    CGFloat marginLeft = 16;
    CGFloat marginTop = 82;

    if ([UIDevice acc_isIPhoneX]) {
        if (@available(iOS 11.0, *)) {
            marginTop += ACC_STATUS_BAR_NORMAL_HEIGHT;
        }
    }
    
    return CGPointMake(marginLeft, marginTop);
}

- (void)p_addInteractionStickerInfoWith:(UIView<ACCStickerProtocol> *)stickerView
                                toArray:(NSMutableArray *)interactionStickers
                                    idx:(NSInteger)stickerIndex
{
    UIView *videoReplyCommentStickerView;
    switch (self.videoReplyCommentModel.viewType) {
        case ACCVideoReplyCommentViewTypeWithoutCover: {
            videoReplyCommentStickerView = (ACCVideoReplyCommentWithoutCoverStickerView *)(stickerView.contentView);
        }
            break;
        case ACCVideoReplyCommentViewTypeWithCover: {
            videoReplyCommentStickerView = (ACCVideoReplyCommentStickerView *)(stickerView.contentView);
        }
            break;
    }
    
    AWEInteractionVideoReplyCommentStickerModel *interactionStickerInfo = [[AWEInteractionVideoReplyCommentStickerModel alloc] init];
    interactionStickerInfo.type = AWEInteractionStickerTypeVideoReplyComment;
    interactionStickerInfo.localStickerUniqueId = [NSString stringWithFormat:@"%@", @([[NSDate date] timeIntervalSince1970])];
    interactionStickerInfo.index = [interactionStickers count] + stickerIndex;
    interactionStickerInfo.adaptorPlayer = [self.player needAdaptPlayer];
    interactionStickerInfo.videoReplyCommentInfo = self.videoReplyCommentModel;
    
    // get location model
    CGPoint point = [videoReplyCommentStickerView convertPoint:[videoReplyCommentStickerView center] toView:[stickerView.stickerContainer containerView]];
    
    AWEInteractionStickerLocationModel *locationModel = [[AWEInteractionStickerLocationModel alloc] initWithGeometryModel:[stickerView interactiveStickerGeometryWithCenterInPlayer:point interactiveBoundsSize:[videoReplyCommentStickerView bounds].size] andTimeRangeModel:stickerView.stickerTimeRange];
    
    if (locationModel.width && locationModel.height) {
        AWEInteractionStickerLocationModel *finalLocation = [self.player resetStickerLocation:locationModel isRecover:NO];
        finalLocation = finalLocation ?: locationModel;
        // set sticker's location trackinfo
        NSError *error = nil;
        NSArray *arr = [MTLJSONAdapter JSONArrayFromModels:@[finalLocation] error:&error];
        if (error) {
            AWELogToolError2(@"video_reply_comment_phase2", AWELogToolTagEffectPlatform, @"ACCVideoReplyCommentStickerHandler JSONArrayFromModels failed : %@", error);
            error = nil;
        }
        
        NSData *arrJsonData = [NSJSONSerialization dataWithJSONObject:arr options:kNilOptions error:&error];
        if (error) {
            AWELogToolError2(@"video_reply_comment_phase2", AWELogToolTagEffectPlatform, @"ACCVideoReplyCommentStickerHandler dataWithJSONObject failed : %@", error);
            error = nil;
        }
        if (arrJsonData) {
            NSString *arrJsonStr = [[NSString alloc] initWithData:arrJsonData encoding:NSUTF8StringEncoding];
            interactionStickerInfo.trackInfo = arrJsonStr;
        }
        [interactionStickers acc_addObject:interactionStickerInfo];
    }
}

#pragma mark - ACCStickerMigrationProtocol Methods

+ (BOOL)fillCrossPlatformStickerByUserInfo:(NSDictionary *)userInfo repository:(id<ACCPublishRepository>)sessionModel context:(id<ACCCrossPlatformMigrateContext>)context sticker:(NLESegmentSticker_OC *__autoreleasing *)sticker
{
    
    return NO;
}

+ (void)updateUserInfo:(NSDictionary *__autoreleasing *)userInfo repoModel:(id<ACCPublishRepository>)sessionModel byCrossPlatformSlot:(NLETrackSlot_OC *)slot
{
   
}

#pragma mark - ACCStickerHandler Methods
- (void)addInteractionStickerInfoToArray:(NSMutableArray *)interactionStickers idx:(NSInteger)stickerIndex
{
    for (UIView<ACCStickerProtocol> *sticker in [[self.stickerContainerView stickerViewsWithTypeId:ACCStickerTypeIdVideoReplyComment] acc_filter:^BOOL(ACCStickerViewType  _Nonnull item) {
        switch (self.videoReplyCommentModel.viewType) {
            case ACCVideoReplyCommentViewTypeWithoutCover:
                return [item.contentView isKindOfClass:[ACCVideoReplyCommentWithoutCoverStickerView class]];
            case ACCVideoReplyCommentViewTypeWithCover:
                return [item.contentView isKindOfClass:[ACCVideoReplyCommentStickerView class]];
        }
        return NO;
    }]) {
        [self p_addInteractionStickerInfoWith:sticker toArray:interactionStickers idx:stickerIndex];
    }
}

- (void)apply:(UIView<ACCStickerProtocol> *)sticker index:(NSUInteger)idx
{
    // 外挂贴纸do nothing
}

- (BOOL)canHandleSticker:(UIView<ACCStickerProtocol> *)sticker
{
    BOOL canHandleSticker = NO;
    switch (self.videoReplyCommentModel.viewType) {
        case ACCVideoReplyCommentViewTypeWithoutCover: {
            canHandleSticker = [[sticker contentView] isKindOfClass:[ACCVideoReplyCommentWithoutCoverStickerView class]];
        }
            break;
        case ACCVideoReplyCommentViewTypeWithCover: {
            canHandleSticker = [[sticker contentView] isKindOfClass:[ACCVideoReplyCommentStickerView class]];
        }
            break;
    }
    return canHandleSticker;
}

- (BOOL)canRecoverSticker:(ACCRecoverStickerModel *)sticker
{
    return sticker.interactionSticker.trackInfo && (sticker.interactionSticker.type == AWEInteractionStickerTypeVideoReplyComment);
}

- (void)recoverSticker:(ACCRecoverStickerModel *)sticker
{
    if ([self canRecoverSticker:sticker]) {
        AWEInteractionVideoReplyCommentStickerModel * interactionModel = (AWEInteractionVideoReplyCommentStickerModel *)(sticker.interactionSticker);
        AWEInteractionStickerLocationModel *locationModel = [interactionModel fetchLocationModelFromTrackInfo];
        
        if (self.player && interactionModel.adaptorPlayer) {
            locationModel = [self.player resetStickerLocation:locationModel isRecover:YES];
        }
        
        [self addStickerViewWithModel:interactionModel.videoReplyCommentInfo locationModel:locationModel];
    }
}
 - (void)reset
{
    [[self.stickerContainerView stickerViewsWithTypeId:ACCStickerTypeIdVideoReplyComment] enumerateObjectsUsingBlock:^(ACCStickerViewType  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        BOOL isKindofReplyCommentStickerView = NO;
        switch (self.videoReplyCommentModel.viewType) {
            case ACCVideoReplyCommentViewTypeWithoutCover: {
                isKindofReplyCommentStickerView = [[obj contentView] isKindOfClass:[ACCVideoReplyCommentWithoutCoverStickerView class]];
            }
                break;
            case ACCVideoReplyCommentViewTypeWithCover: {
                isKindofReplyCommentStickerView = [[obj contentView] isKindOfClass:[ACCVideoReplyCommentStickerView class]];
            }
                break;
        }
        
        if (isKindofReplyCommentStickerView) {
            if (ACC_FLOAT_GREATER_THAN(0.1, obj.realStartTime)) {
                obj.hidden = NO;
            } else {
                obj.hidden = YES;
            }
        }
    }];
}

- (void)finish
{
    
}

@end
