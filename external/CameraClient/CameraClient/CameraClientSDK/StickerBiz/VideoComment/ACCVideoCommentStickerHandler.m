//
//  ACCVideoCommentStickerHandler.m
//  CameraClient-Pods-Aweme
//
//  Created by Daniel on 2021/3/18.
//

#import "AWERepoStickerModel.h"
#import "ACCVideoCommentStickerHandler.h"

#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreativeKitSticker/ACCStickerUtils.h>

#import "ACCVideoCommentStickerView.h"
#import "ACCVideoCommentStickerConfig.h"
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
#import "ACCConfigKeyDefines.h"
#import "IESInfoSticker+ACCAdditions.h"
#import <CameraClientModel/ACCCrossPlatformStickerType.h>

@interface ACCVideoCommentStickerHandler ()

@property (nonatomic, strong) UIView<ACCStickerProtocol> *stickerWrapView;

@end

@implementation ACCVideoCommentStickerHandler

@synthesize repository;
@synthesize onSelectTimeCallback;
@synthesize willDeleteCallback;

- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

#pragma mark - Private Methods

- (void)p_addInteractionStickerInfoWith:(UIView<ACCStickerProtocol> *)stickerView
                                toArray:(NSMutableArray *)interactionStickers
                                    idx:(NSInteger)stickerIndex {
    ACCVideoCommentStickerView *videoCommentStickerView = (ACCVideoCommentStickerView *)(stickerView.contentView);
    AWEInteractionStickerModel *interactionStickerInfo = ({
        AWEInteractionStickerModel *interactionModel = [[AWEInteractionStickerModel alloc] init];
        interactionModel.stickerID = @"0";
        interactionModel.type = AWEInteractionStickerTypeComment;
        interactionModel.localStickerUniqueId = [NSString stringWithFormat:@"%@", @([[NSDate date] timeIntervalSince1970])];
        interactionModel.index = [interactionStickers count] + stickerIndex;
        interactionModel.adaptorPlayer = [self.player needAdaptPlayer];
        
        NSError *error = nil;
        NSDictionary *attr = @{@"comment_sticker_id":@"0"};
        NSData *data = [NSJSONSerialization dataWithJSONObject:attr options:kNilOptions error:&error];
        if (error) {
            AWELogToolError2(@"video_comment_sticker", AWELogToolTagRecord | AWELogToolTagEdit, @"ACCVideoCommentStickerHandler JSONArrayFromModels failed: %@", error);
        }
        NSString *attrStr = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
        interactionModel.attr = attrStr;
        interactionModel;
    });
    
    /* Location Model */
    CGPoint point = [videoCommentStickerView convertPoint:videoCommentStickerView.center
                                                   toView:[stickerView.stickerContainer containerView]];
    AWEInteractionStickerLocationModel *locationInfoModel = [[AWEInteractionStickerLocationModel alloc]
                                                             initWithGeometryModel:[stickerView
                                                                                    interactiveStickerGeometryWithCenterInPlayer:point
                                                                                    interactiveBoundsSize:videoCommentStickerView.bounds.size]
                                                             andTimeRangeModel:stickerView.stickerTimeRange];
    ACCShootSameStickerModel *shootSameStickerModel = [self.repository.repoSticker.shootSameStickerModels acc_match:^BOOL(ACCShootSameStickerModel * _Nonnull item) {
        return item.stickerType == AWEInteractionStickerTypeComment;
    }];
    shootSameStickerModel.locationModel = locationInfoModel;
    if (locationInfoModel.width && locationInfoModel.height) {
        AWEInteractionStickerLocationModel *finalLocation = [self.player resetStickerLocation:locationInfoModel isRecover:NO];
        if (finalLocation) {
            NSError *tempError;
            NSArray *arr = [MTLJSONAdapter JSONArrayFromModels:@[finalLocation] error:&tempError];
            if (tempError) {
                AWELogToolError2(@"video_comment_sticker", AWELogToolTagEffectPlatform, @"ACCVideoCommentStickerHandler JSONArrayFromModels failed: %@", tempError);
                tempError = nil;
            }
            NSData *arrJsonData = [NSJSONSerialization dataWithJSONObject:arr options:kNilOptions error:&tempError];
            if (tempError) {
                AWELogToolError2(@"video_comment_sticker", AWELogToolTagEffectPlatform, @"ACCVideoCommentStickerHandler dataWithJSONObject failed: %@", tempError);
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
    marginTop += 18; // offset
    CGPoint topLeftPoint = CGPointMake(marginLeft, marginTop);
    
    return topLeftPoint;
}

#pragma mark - ACCStickerMigrationProtocol Methods

+ (BOOL)fillCrossPlatformStickerByUserInfo:(NSDictionary *)userInfo
                                repository:(id<ACCPublishRepository>)sessionModel
                                   context:(id<ACCCrossPlatformMigrateContext>)context
                                   sticker:(NLESegmentSticker_OC *__autoreleasing *)sticker
{
    if (userInfo.acc_stickerType == ACCEditEmbeddedStickerTypeVideoComment) {
        AWERepoStickerModel *stickerModel = [sessionModel extensionModelOfClass:[AWERepoStickerModel class]];
        AWEInteractionStickerModel *interactionStickerModel = [stickerModel.interactionStickers acc_match:^BOOL(AWEInteractionStickerModel * _Nonnull item) {
            return item.trackInfo && item.type == AWEInteractionStickerTypeComment;
        }];
        if (interactionStickerModel == nil) {
            return YES;
        }
        
        NLESegmentImageSticker_OC *sticker_ = [[NLESegmentImageSticker_OC alloc] init];
        sticker_.stickerType = ACCCrossPlatformStickerTypeVideoComment;
        sticker_.imageFile = [[NLEResourceNode_OC alloc] init];
        sticker_.imageFile.resourceType = NLEResourceTypeImageSticker;
        sticker_.imageFile.resourceFile = context.resourcePath;
        
        sticker_.extraDict = [NSMutableDictionary dictionary];
        NSError *error = nil;
        sticker_.extraDict[ACCInteractionStickerTransferKey] = [MTLJSONAdapter JSONDictionaryFromModel:interactionStickerModel error:&error];
        if (error != nil) {
            AWELogToolError2(@"VideoCommentSticker", AWELogToolTagDraft, @"Interaction Sticker Model Convert To Json Error:%@", error);
        }
        sticker_.extraDict[@"sticker_id"] = interactionStickerModel.stickerID;
        sticker_.extraDict[ACCCrossPlatformiOSResourcePathKey] = context.resourcePath;
        ACCShootSameStickerModel *shootSameStickerModel = [stickerModel.shootSameStickerModels acc_match:^BOOL(ACCShootSameStickerModel * _Nonnull item) {
            return item.stickerType == AWEInteractionStickerTypeComment;
        }];
        ACCVideoCommentModel *videoCommentModel = [ACCVideoCommentModel createModelFromJSON:shootSameStickerModel.stickerModelStr];
        videoCommentModel.isDeleted = shootSameStickerModel.isDeleted ? @(1) : @(0);
        error = nil;
        NSMutableDictionary *dict = [[MTLJSONAdapter JSONDictionaryFromModel:videoCommentModel error:&error] mutableCopy];
        if (error) {
            
        }
        dict[@"emoji_width"] = @(60);
        dict[@"emoji_height"] = @(60);
        sticker_.extraDict[@"video_comment_sticker"] = [dict copy];
        
        *sticker = sticker_;
        return YES;
    }
    return NO;
}

+ (void)updateUserInfo:(NSDictionary *__autoreleasing *)userInfo
             repoModel:(id<ACCPublishRepository>)sessionModel
   byCrossPlatformSlot:(nonnull NLETrackSlot_OC *)slot
{
    if (slot.sticker.stickerType != ACCCrossPlatformStickerTypeVideoComment) {
        return;
    }
    NLESegmentSticker_OC *sticker = slot.sticker;
    NSError *error = nil;
    AWEInteractionStickerModel *interactionStickerModel = [MTLJSONAdapter modelOfClass:[AWEInteractionStickerModel class] fromJSONDictionary:[sticker.extraDict acc_dictionaryValueForKey:ACCInteractionStickerTransferKey] error:&error];
    if (interactionStickerModel == nil) {
        if (error != nil) {
            AWELogToolError2(@"VideoCommentSticker", AWELogToolTagDraft, @"Interaction Sticker Json Convert To Model Error:%@", error);
        }
        return;
    }
    
    interactionStickerModel.stickerID = [sticker.extraDict acc_stringValueForKey:@"sticker_id"];
    interactionStickerModel.localStickerUniqueId = [NSString stringWithFormat:@"%@", @([[NSDate date] timeIntervalSince1970])];
    AWERepoStickerModel *repoStickerModel = [sessionModel extensionModelOfClass:[AWERepoStickerModel class]];
    NSMutableArray *interactionStickers = [NSMutableArray array];
    [interactionStickers acc_addObject:interactionStickerModel];
    if (!ACC_isEmptyArray(repoStickerModel.interactionStickers)) {
        [interactionStickers addObjectsFromArray:repoStickerModel.interactionStickers];
    }
    repoStickerModel.interactionStickers = interactionStickers;
    
    error = nil;
    NSDictionary *videoCommentDict = [sticker.extraDict acc_dictionaryValueForKey:@"video_comment_sticker"];
    if (ACC_isEmptyDictionary(videoCommentDict)) {
        return;
    }
    ACCVideoCommentModel *videoCommentModel = [MTLJSONAdapter modelOfClass:[ACCVideoCommentModel class]
                                                        fromJSONDictionary:videoCommentDict
                                                                     error:&error];
    if (error) {
        AWELogToolError2(@"VideoCommentSticker", AWELogToolTagDraft, @"%@", error);
    }
    ACCShootSameStickerModel *shootSameStickerModel = [[ACCShootSameStickerModel alloc] init];
    shootSameStickerModel.stickerType = AWEInteractionStickerTypeComment;
    shootSameStickerModel.stickerModelStr = [videoCommentModel convertToJSONString];
    shootSameStickerModel.locationModel = [interactionStickerModel fetchLocationModelFromTrackInfo];
    if (videoCommentModel.isDeleted != nil) {
        shootSameStickerModel.deleted = [videoCommentModel.isDeleted boolValue];
    }
    if (repoStickerModel.shootSameStickerModels == nil) {
        repoStickerModel.shootSameStickerModels = [NSMutableArray array];
    }
    [repoStickerModel.shootSameStickerModels acc_addObject:shootSameStickerModel];
    
    NSMutableDictionary *temp_userInfo = [NSMutableDictionary dictionary];
    temp_userInfo.acc_stickerType = ACCEditEmbeddedStickerTypeVideoComment;
    *userInfo = temp_userInfo;
}

#pragma mark - ACCShootSameStickerHandlerProtocol Methods

- (UIView<ACCStickerProtocol> *)createStickerViewWithShootSameStickerModel:(ACCShootSameStickerModel *)shootSameStickerModel
                                                              isInRecorder:(BOOL)isInRecorder
{
    UIView<ACCStickerProtocol> *existingStickerView = [[self.stickerContainerView stickerViewsWithTypeId:ACCStickerTypeIdVideoComment] acc_match:^BOOL(ACCStickerViewType _Nonnull item) {
        return [item.contentView isKindOfClass:[ACCVideoCommentStickerView class]];
    }];
    if (existingStickerView != nil) {
        return existingStickerView;
    }
    AWEInteractionStickerLocationModel *locationModel = shootSameStickerModel.locationModel;
    ACCVideoCommentStickerView *stickerView = [[ACCVideoCommentStickerView alloc] init];
    @weakify(self);
    stickerView.triggerDragDeleteCallback = ^{
        @strongify(self);
        [self.logger logStickerViewWillDeleteWithEnterMethod:@"drag"];
    };
    [stickerView configWithModel:[ACCVideoCommentModel createModelFromJSON:shootSameStickerModel.stickerModelStr] completion:^{
        if (locationModel == nil) {
            CGPoint topLeftPoint = [self getTopLeftPosition];
            ACCStickerGeometryModel *geometryModel = [ACCStickerUtils convertStickerViewFrame:CGRectMake(topLeftPoint.x,
                                                                                                         topLeftPoint.y,
                                                                                                         stickerView.frame.size.width,
                                                                                                         stickerView.frame.size.height)
                                                                fromContainerCoordinateSystem:self.stickerContainerView.originalFrame
                                                                     toPlayerCoordinateSystem:[self.stickerContainerView playerRect]];
            [self.stickerWrapView recoverWithGeometryModel:geometryModel];
        } else {
            [self.stickerWrapView recoverWithGeometryModel:[locationModel ratioGeometryModel]];
        }
    }];
    ACCVideoCommentStickerConfig *config;
    if (isInRecorder) {
        config = [[ACCVideoCommentStickerConfig alloc] init];
        config.showSelectedHint = NO;
    } else {
        config = [[ACCVideoCommentStickerConfig alloc] initWithOption:ACCVideoCommentStickerConfigOptionsSelectTime];
        if (ACCConfigBool(ACCConfigBOOL_allow_sticker_delete)) {
            @weakify(self);
            @weakify(stickerView);
            config.deleteAction = ^{
                @strongify(self);
                @strongify(stickerView);
                [self.logger logStickerViewWillDeleteWithEnterMethod:@"click"];
                [self.stickerContainerView removeStickerView:stickerView];
            };
        }
    }
    // update time range
    if (isInRecorder) {
        NSString *startTime = [NSString stringWithFormat:@"%.4f", 0.f];
        NSString *endTime = [NSString stringWithFormat:@"%.4f", 0.f];
        config.timeRangeModel.startTime = [NSDecimalNumber decimalNumberWithString:startTime];
        config.timeRangeModel.endTime = [NSDecimalNumber decimalNumberWithString:endTime];
        shootSameStickerModel.locationModel.pts = [NSDecimalNumber decimalNumberWithString:@"-1"];
        shootSameStickerModel.locationModel.startTime = config.timeRangeModel.startTime;
        shootSameStickerModel.locationModel.endTime = config.timeRangeModel.endTime;
    } else {
        if (locationModel == nil || (locationModel.startTime.floatValue <= 0 && locationModel.endTime.floatValue <= 0)) {
            NSString *startTime = [NSString stringWithFormat:@"%.4f", 0.f];
            NSString *endTime = [NSString stringWithFormat:@"%.4f", self.player.stickerInitialEndTime];
            config.timeRangeModel.startTime = [NSDecimalNumber decimalNumberWithString:startTime];
            config.timeRangeModel.endTime = [NSDecimalNumber decimalNumberWithString:endTime];
        } else {
            config.timeRangeModel.startTime = locationModel.startTime;
            config.timeRangeModel.endTime = locationModel.endTime;
        }
    }
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
    config.typeId = ACCStickerTypeIdVideoComment;
    config.hierarchyId = @(ACCStickerHierarchyTypeMediumHigh);
    config.timeRangeModel.pts = [NSDecimalNumber decimalNumberWithString:@"-1"];
    config.minimumScale = 0.6;
    config.gestureInvalidFrameValue = self.repository.repoSticker.gestureInvalidFrameValue;
    @weakify(stickerView);
    config.onSelectTimeCallback = ^{
        @strongify(self);
        @strongify(stickerView);
        ACCBLOCK_INVOKE(self.onSelectTimeCallback, stickerView);
    };
    @weakify(shootSameStickerModel);
    config.willDeleteCallback = ^{
        @strongify(self);
        @strongify(shootSameStickerModel);
        shootSameStickerModel.deleted = YES;
        ACCShootSameStickerModel *editShootSameStickerModel = [self.repository.repoSticker.shootSameStickerModels acc_match:^BOOL(ACCShootSameStickerModel * _Nonnull item) {
            return item.stickerType == AWEInteractionStickerTypeComment;
        }];
        if (editShootSameStickerModel != shootSameStickerModel) {
            editShootSameStickerModel.deleted = YES;
        }
        ACCBLOCK_INVOKE(self.willDeleteCallback);
    };
    
    self.stickerWrapView = [self.stickerContainerView addStickerView:stickerView
                                                              config:config]; // add stickerView to containerView
    return self.stickerWrapView;
}

- (void)updateLocationModelWithShootSameStickerModel:(ACCShootSameStickerModel *)model
{
    UIView<ACCStickerProtocol> *stickerView = [[self.stickerContainerView stickerViewsWithTypeId:ACCStickerTypeIdVideoComment] acc_match:^BOOL(ACCStickerViewType _Nonnull item) {
        return [item.contentView isKindOfClass:[ACCVideoCommentStickerView class]];
    }];
    if (stickerView == nil) {
        return;
    }
    ACCStickerGeometryModel *geometryCopy = [stickerView.stickerGeometry copy];
    geometryCopy.preferredRatio = YES;
    if (stickerView.stickerTimeRange == nil) {
        AWEInteractionStickerLocationModel *stickerLocation = [[AWEInteractionStickerLocationModel alloc] initWithGeometryModel:geometryCopy
                                                                                                              andTimeRangeModel: [[ACCStickerTimeRangeModel alloc] init]];
        stickerLocation.pts = [NSDecimalNumber decimalNumberWithString:@"-1"];
        NSString *startTime = [NSString stringWithFormat:@"%.4f", stickerView.realStartTime];
        NSString *endTime = [NSString stringWithFormat:@"%.4f", stickerView.realStartTime + stickerView.realDuration];
        stickerLocation.startTime = [NSDecimalNumber decimalNumberWithString:startTime];
        stickerLocation.endTime = [NSDecimalNumber decimalNumberWithString:endTime];
        model.locationModel = stickerLocation;
    } else {
        AWEInteractionStickerLocationModel *stickerLocation = [[AWEInteractionStickerLocationModel alloc] initWithGeometryModel:geometryCopy
                                                                                                              andTimeRangeModel:stickerView.stickerTimeRange];
        model.locationModel = stickerLocation;
    }
}

#pragma mark - ACCStickerHandler protocol methods

- (void)addInteractionStickerInfoToArray:(NSMutableArray *)interactionStickers
                                     idx:(NSInteger)stickerIndex
{
    for (UIView<ACCStickerProtocol> *sticker in [[self.stickerContainerView stickerViewsWithTypeId:ACCStickerTypeIdVideoComment] acc_filter:^BOOL(ACCStickerViewType  _Nonnull item) {
        return [item.contentView isKindOfClass:[ACCVideoCommentStickerView class]];
    }]) {
        [self p_addInteractionStickerInfoWith:sticker toArray:interactionStickers idx:stickerIndex];
    }
}

- (BOOL)canHandleSticker:(UIView<ACCStickerProtocol> *)sticker
{
    return [[sticker contentView] isKindOfClass:[ACCVideoCommentStickerView class]];
}

- (void)apply:(nullable UIView<ACCStickerProtocol> *)sticker
        index:(NSUInteger)idx
{
    /* Convert sticker's contentView to an image */
    
    UIImage *image = nil;
    CGFloat imageScale = ACC_SCREEN_SCALE;
    CGFloat scale = [sticker.stickerGeometry.scale floatValue]  * [UIScreen mainScreen].scale;
    if (scale > imageScale) {
        imageScale = scale < 10 ? scale : 10;
    }
    if (sticker.hidden) {
        UIView<ACCStickerProtocol> *stickerCopy = [sticker copy];
        image = [[stickerCopy contentView] acc_imageWithViewOnScale:imageScale];
    } else {
        image = [[sticker contentView] acc_imageWithViewOnScale:imageScale];
    }
    if (!image || image.size.width == 0 || image.size.height == 0) {
        return;
    }
    NSData *imageData = UIImagePNGRepresentation(image);
    
    /* Save the image to disk */
    
    NSString *imagePath = [AWEDraftUtils generateModernSocialPathFromTaskId:self.repository.repoDraft.taskID index:idx];
    BOOL ret = [imageData acc_writeToFile:imagePath atomically:YES];
    if (![[NSFileManager defaultManager] fileExistsAtPath:imagePath]) {
        AWELogToolInfo(AWELogToolTagEdit,
                       @"videoCommentStickersForPublishInfo:create Failed:%@, write Failed:%@",
                       @(!image), @(ret));
    }
    
    /* Update userInfo */
    
    NSMutableDictionary *userInfo = [@{} mutableCopy];
    userInfo.acc_stickerType = ACCEditEmbeddedStickerTypeVideoComment;
    
    /* Apply sticker's image to VE and hide the stickerView */
    
    NSInteger stickerID = [self.player addInfoSticker:imagePath withEffectInfo:nil userInfo:userInfo];
    
    [self.player setStickerAbove:stickerID];
    [self.player setSticker:stickerID startTime:sticker.realStartTime duration:sticker.realDuration];
    
    /* Update sticker's position */
    
    ACCStickerGeometryModel *geometryCopy = [sticker.stickerGeometry copy];
    geometryCopy.preferredRatio = NO;
    AWEInteractionStickerLocationModel *stickerLocation = [[AWEInteractionStickerLocationModel alloc] initWithGeometryModel:geometryCopy
                                                                                                          andTimeRangeModel:sticker.stickerTimeRange];
    CGSize stickerSize = [self.player getInfoStickerSize:stickerID];
    CGFloat realScale = stickerSize.width > 0 ? image.size.width / stickerSize.width : 1;
    CGFloat offsetX = [stickerLocation.x floatValue];
    CGFloat offsetY = -[stickerLocation.y floatValue];
    CGFloat stickerAngle = [stickerLocation.rotation floatValue];
    CGFloat stickerScale = [stickerLocation.scale floatValue];
    stickerScale = stickerScale * realScale;
    [self.player setSticker:stickerID
                    offsetX:offsetX
                    offsetY:offsetY
                      angle:stickerAngle
                      scale:stickerScale];
    
    sticker.hidden = YES;
}

- (BOOL)canRecoverSticker:(ACCRecoverStickerModel *)sticker
{
    return sticker.infoSticker.acc_stickerType == ACCEditEmbeddedStickerTypeVideoComment;
}

- (void)recoverSticker:(ACCRecoverStickerModel *)sticker
{
    // Guard
    if (![self canRecoverSticker:sticker]) {
        return;
    }
    
    AWEInteractionStickerModel *interactionStickerModel = [self.repository.repoSticker.interactionStickers acc_match:^BOOL(AWEInteractionStickerModel * _Nonnull item) {
        return item.trackInfo && item.type == AWEInteractionStickerTypeComment;
    }];
    AWEInteractionStickerLocationModel *locationModel = [interactionStickerModel fetchLocationModelFromTrackInfo];
    if (interactionStickerModel.adaptorPlayer) {
        [self.player resetStickerLocation:locationModel isRecover:YES];
    }
}

- (void)reset
{
    [[self.stickerContainerView stickerViewsWithTypeId:ACCStickerTypeIdVideoComment] enumerateObjectsUsingBlock:^(ACCStickerViewType  _Nonnull obj,
                                                                                                                  NSUInteger idx,
                                                                                                                  BOOL * _Nonnull stop) {
        if ([[obj contentView] isKindOfClass:[ACCVideoCommentStickerView class]]) {
            if (ACC_FLOAT_GREATER_THAN(0.1, obj.realStartTime)) {
                obj.hidden = NO;
            } else {
                obj.hidden = YES;
            }
        }
    }];
    [self.player removeStickerWithType:ACCEditEmbeddedStickerTypeVideoComment];
}

@end
