//
//  ACCVideoReplyStickerHandler.m
//  CameraClient-Pods-Aweme
//
//  视频评论视频
//
//  Created by Daniel on 2021/7/27.
//

#import "ACCVideoReplyStickerHandler.h"
#import "ACCVideoReplyStickerView.h"
#import "ACCVideoReplyNewTypeStickerView.h"
#import "ACCVideoReplyStickerConfig.h"
#import "AWERepoStickerModel.h"
#import "ACCConfigKeyDefines.h"
#import "AWEInteractionVideoReplyStickerModel.h"

#import <CameraClientModel/ACCVideoReplyModel.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreativeKitSticker/ACCStickerUtils.h>
#import <CreativeKit/ACCRouterProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>

@implementation ACCVideoReplyStickerHandler

#pragma mark - Private Methods

- (void)p_addInteractionStickerInfoWith:(UIView<ACCStickerProtocol> *)stickerView
                                toArray:(NSMutableArray *)interactionStickers
                                    idx:(NSInteger)stickerIndex {
    ACCVideoReplyStickerView *videoReplyStickerView = (ACCVideoReplyStickerView *)(stickerView.contentView);
    AWEInteractionVideoReplyStickerModel *interactionStickerInfo = ({
        AWEInteractionVideoReplyStickerModel *interactionModel = [[AWEInteractionVideoReplyStickerModel alloc] init];
        interactionModel.type = AWEInteractionStickerTypeVideoReply;
        interactionModel.localStickerUniqueId = [NSString stringWithFormat:@"%@", @([[NSDate date] timeIntervalSince1970])];
        interactionModel.index = [interactionStickers count] + stickerIndex;
        interactionModel.adaptorPlayer = [self.player needAdaptPlayer];
        interactionModel.videoReplyUserInfo = [videoReplyStickerView.videoReplyModel copy];
        interactionModel;
    });
    
    /* Location Model */
    CGPoint point = [videoReplyStickerView convertPoint:videoReplyStickerView.center
                                                 toView:[stickerView.stickerContainer containerView]];
    AWEInteractionStickerLocationModel *locationInfoModel = [[AWEInteractionStickerLocationModel alloc]
                                                             initWithGeometryModel:[stickerView
                                                                                    interactiveStickerGeometryWithCenterInPlayer:point
                                                                                    interactiveBoundsSize:videoReplyStickerView.bounds.size]
                                                             andTimeRangeModel:stickerView.stickerTimeRange];
    if (locationInfoModel.width && locationInfoModel.height) {
        AWEInteractionStickerLocationModel *finalLocation = [self.player resetStickerLocation:locationInfoModel isRecover:NO];
        finalLocation = finalLocation ?: locationInfoModel;
        NSError *tempError;
        NSArray *arr = [MTLJSONAdapter JSONArrayFromModels:@[finalLocation] error:&tempError];
        if (tempError) {
            AWELogToolError2(@"video_reply_sticker", AWELogToolTagEffectPlatform, @"ACCVideoReplyStickerHandler JSONArrayFromModels failed: %@", tempError);
            tempError = nil;
        }
        NSData *arrJsonData = [NSJSONSerialization dataWithJSONObject:arr options:kNilOptions error:&tempError];
        if (tempError) {
            AWELogToolError2(@"video_reply_sticker", AWELogToolTagEffectPlatform, @"ACCVideoReplyStickerHandler dataWithJSONObject failed: %@", tempError);
            tempError = nil;
        }
        if (arrJsonData) {
            NSString *arrJsonStr = [[NSString alloc] initWithData:arrJsonData encoding:NSUTF8StringEncoding];
            interactionStickerInfo.trackInfo = arrJsonStr;
        }
        
        interactionStickerInfo.index = [interactionStickers count] + stickerIndex;
        interactionStickerInfo.adaptorPlayer = [self.player needAdaptPlayer];
        [interactionStickers acc_addObject:interactionStickerInfo];
    }
}

- (CGPoint)getTopLeftPosition
{
    CGFloat marginLeft = 16;
    CGFloat marginTop = 0;
    if ([UIDevice acc_isIPhoneX]) {
        if (@available(iOS 11.0, *)) {
            marginTop += ACC_STATUS_BAR_NORMAL_HEIGHT;
        }
    }
    marginTop += 64; // close button's y position (20) and height (44)
    marginTop += 38; // offset
    CGPoint topLeftPoint = CGPointMake(marginLeft, marginTop);
    
    return topLeftPoint;
}

#pragma mark - Public Methods

- (nonnull UIView<ACCStickerProtocol> *)createStickerView:(ACCVideoReplyModel *)videoReplyModel
                                            locationModel:(AWEInteractionStickerLocationModel *)locationModel
{
    UIView<ACCStickerProtocol> *existingStickerView = [[self.stickerContainerView stickerViewsWithTypeId:ACCStickerTypeIdVideoReply] acc_match:^BOOL(ACCStickerViewType _Nonnull item) {
        return [item.contentView isKindOfClass:[ACCVideoReplyStickerView class]] || [item.contentView isKindOfClass:[ACCVideoReplyNewTypeStickerView class]];
    }];
    if (existingStickerView != nil) {
        return existingStickerView;
    }
    if ([self.delegation respondsToSelector:@selector(willCreateStickerView:)]) {
        [self.delegation willCreateStickerView:videoReplyModel];
    }
    
    UIView<ACCStickerContentProtocol> *stickerView = nil;
    if (ACCConfigInt(kConfigInt_video_reply_sticker_type) == 0) {
        videoReplyModel.viewType = ACCVideoReplyViewTypeMixCoverAndLabel;
        stickerView = [[ACCVideoReplyStickerView alloc] initWithModel:videoReplyModel];
    } else if (ACCConfigInt(kConfigInt_video_reply_sticker_type) == 1) {
        videoReplyModel.viewType = ACCVideoReplyViewTypeSeperateCoverAndLabel;
        stickerView = [[ACCVideoReplyNewTypeStickerView alloc] initWithModel:videoReplyModel];
    }
    
    ACCVideoReplyStickerConfig *config = [[ACCVideoReplyStickerConfig alloc] initWithOption:ACCVideoReplyStickerConfigOptionsPreview];
    // update time range
    config.timeRangeModel.pts = [NSDecimalNumber decimalNumberWithString:@"-1"];
    config.timeRangeModel.startTime = [AWEInteractionStickerLocationModel convertCGFloatToNSDecimalNumber:0.f];
    config.timeRangeModel.endTime = [AWEInteractionStickerLocationModel convertCGFloatToNSDecimalNumber:-1.f];
    // update position
    if (locationModel == nil) {
        CGPoint topLeftPoint = [self getTopLeftPosition];
        config.geometryModel = [ACCStickerUtils convertStickerViewFrame:CGRectMake(topLeftPoint.x,
                                                                                   topLeftPoint.y,
                                                                                   stickerView.frame.size.width,
                                                                                   stickerView.frame.size.height)
                                          fromContainerCoordinateSystem:self.stickerContainerView.originalFrame
                                               toPlayerCoordinateSystem:[self.stickerContainerView playerRect]];
    } else {
        config.geometryModel = [locationModel ratioGeometryModel];
    }
    @weakify(self);
    config.willDeleteCallback = ^{
        @strongify(self);
        [self.delegation willDeleteVideoReplyStickerView];
    };
    NSString *awemeId = videoReplyModel.awemeId ?: @"";
    if ([awemeId isEqualToString:@""]) {
        AWELogToolError2(@"video_reply_sticker", AWELogToolTagEffectPlatform, @"ACCVideoReplyStickerHandler awemeId is empty");
    }
    config.onPreviewCallback = ^{
        [ACCTracker() trackEvent:@"click_watch_video" params:nil];
        NSString *enterMethod = nil;
        if ([self.delegation respondsToSelector:@selector(getTrackEnterMethod)]) {
            enterMethod = [self.delegation getTrackEnterMethod];
        }
        enterMethod = enterMethod ?: @"";
        if ([enterMethod isEqualToString:@""]) {
            AWELogToolError2(@"video_reply_sticker", AWELogToolTagEffectPlatform, @"ACCVideoReplyStickerHandler enterMethod is empty");
        }
        [ACCRouter() transferToURLStringWithFormat:@"aweme://aweme/detail/%@?refer=%@&enter_method=%@", awemeId, @"video_reply", enterMethod];
    };
    if (ACCConfigBool(ACCConfigBOOL_allow_sticker_delete)) {
        @weakify(stickerView);
        config.deleteAction = ^{
            @strongify(self);
            @strongify(stickerView);
            [self.delegation willDeleteVideoReplyStickerView];
            [self.stickerContainerView removeStickerView:stickerView];
        };
    }
    
    UIView<ACCStickerProtocol> *stickerWrapView = [self.stickerContainerView addStickerView:stickerView
                                                                                     config:config]; // add stickerView to containerView
    return stickerWrapView;
}

- (void)removeVideoReplyStickerView
{
    NSArray<ACCStickerViewType> *stickerViews = [self.stickerContainerView stickerViewsWithTypeId:ACCStickerTypeIdVideoReply];
    @weakify(self);
    [stickerViews enumerateObjectsUsingBlock:^(ACCStickerViewType  _Nonnull stickerView, NSUInteger idx, BOOL * _Nonnull stop) {
        @strongify(self);
        [self.stickerContainerView removeStickerView:stickerView];
    }];
}

#pragma mark - ACCStickerMigrationProtocol Methods

+ (BOOL)fillCrossPlatformStickerByUserInfo:(nonnull NSDictionary *)userInfo
                                repository:(nonnull id<ACCPublishRepository>)sessionModel
                                   context:(nonnull id<ACCCrossPlatformMigrateContext>)context
                                   sticker:(NLESegmentSticker_OC *__autoreleasing *)sticker
{
    return NO;
}

+ (void)updateUserInfo:(NSDictionary *__autoreleasing *)userInfo
             repoModel:(nonnull id<ACCPublishRepository>)sessionModel
   byCrossPlatformSlot:(nonnull NLETrackSlot_OC *)slot
{
    
}

#pragma mark - ACCStickerHandler protocol methods

- (void)addInteractionStickerInfoToArray:(NSMutableArray *)interactionStickers
                                     idx:(NSInteger)stickerIndex
{
    for (UIView<ACCStickerProtocol> *sticker in [[self.stickerContainerView stickerViewsWithTypeId:ACCStickerTypeIdVideoReply] acc_filter:^BOOL(ACCStickerViewType  _Nonnull item) {
        return [item.contentView isKindOfClass:[ACCVideoReplyStickerView class]] || [item.contentView isKindOfClass:[ACCVideoReplyNewTypeStickerView class]];
    }]) {
        [self p_addInteractionStickerInfoWith:sticker toArray:interactionStickers idx:stickerIndex];
    }
}

- (BOOL)canHandleSticker:(UIView<ACCStickerProtocol> *)sticker
{
    return [[sticker contentView] isKindOfClass:[ACCVideoReplyStickerView class]] || [[sticker contentView] isKindOfClass:[ACCVideoReplyNewTypeStickerView class]];
}

- (void)apply:(nullable UIView<ACCStickerProtocol> *)sticker
        index:(NSUInteger)idx
{
    // do nothing
}

- (BOOL)canRecoverSticker:(ACCRecoverStickerModel *)sticker
{
    BOOL isVideoReplyType = sticker.interactionSticker.type == AWEInteractionStickerTypeVideoReply;
    BOOL isVideoReplyModel = [sticker.interactionSticker isKindOfClass:[AWEInteractionVideoReplyStickerModel class]];
    return isVideoReplyType & isVideoReplyModel;
}

- (void)recoverSticker:(ACCRecoverStickerModel *)sticker
{
    AWEInteractionVideoReplyStickerModel *videoReplyInteractionModel = (AWEInteractionVideoReplyStickerModel *)sticker.interactionSticker;
    AWEInteractionStickerLocationModel *locationModel = [videoReplyInteractionModel fetchLocationModelFromTrackInfo];
    if (videoReplyInteractionModel.adaptorPlayer) {
        [self.player resetStickerLocation:locationModel isRecover:YES];
    }
    [self createStickerView:videoReplyInteractionModel.videoReplyUserInfo locationModel:locationModel];
}

- (void)reset
{
    [[self.stickerContainerView stickerViewsWithTypeId:ACCStickerTypeIdVideoReply] enumerateObjectsUsingBlock:^(ACCStickerViewType  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([[obj contentView] isKindOfClass:[ACCVideoReplyStickerView class]] || [[obj contentView] isKindOfClass:[ACCVideoReplyNewTypeStickerView class]]) {
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
