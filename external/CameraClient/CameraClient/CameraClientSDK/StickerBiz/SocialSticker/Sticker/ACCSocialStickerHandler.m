//
//  ACCSocialStickerhandler.m
//  CameraClient-Pods-Aweme-CameraResource_base
//
//  Created by qiuhang on 2020/8/5.
//

#import "ACCSocialStickerHandler.h"
#import "ACCSocialStickerEditView.h"
#import "ACCSocialStickerConfig.h"
#import <CreationKitArch/ACCPublishRepository.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreationKitInfra/NSData+ACCAdditions.h>
#import <CreationKitArch/AWEInteractionStickerLocationModel+ACCSticker.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreationKitArch/ACCEditAndPublishConstants.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import "ACCStickerBizDefines.h"
#import "AWERepoStickerModel.h"
#import "ACCRepoQuickStoryModel.h"
#import <CreationKitArch/ACCRepoContextModel.h>
#import <CreationKitArch/ACCRepoChallengeModel.h>
#import <CreationKitArch/ACCRepoStickerModel.h>
#import <CreationKitInfra/ACCLogHelper.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <NLEPlatform/NLESegmentInfoSticker+iOS.h>
#import "NLESegmentSticker_OC+ACCAdditions.h"
#import "NLETrackSlot_OC+ACCAdditions.h"
#import <CreationKitArch/ACCRepoTrackModel.h>
#import "AWEInteractionHashtagStickerModel.h"
#import "AWEInteractionMentionStickerModel.h"
#import "ACCConfigKeyDefines.h"
#import "IESInfoSticker+ACCAdditions.h"
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <CameraClientModel/ACCCrossPlatformStickerType.h>

NSString * const kSocialStickerUserInfoUniqueIdKey = @"kSocialStickerUserInfoUniqueIdKey";
NSString * const kSocialStickerUserInfoDraftJsonDataKey = @"kSocialStickerUserInfoDraftJsonDataKey";

@interface ACCSocialStickerHandler ()

@property (nonatomic, strong) ACCSocialStickerEditView *socialStickerEditView;
@property (nonatomic, strong) id<ACCSocialStickerDataProvider> dataProvider;
@property (nonatomic, strong) AWEVideoPublishViewModel *publishModel;
@property (nonatomic, strong) NSMutableArray<ACCSocialStickerView *> *autoAddedStickerViewArray;
@property (nonatomic, strong) ACCSocialStickerModel *beganEditBindingSnaphostStickerModel;

@end

@implementation ACCSocialStickerHandler

#pragma mark - life cycle
- (instancetype)initWithDataProvider:(id<ACCSocialStickerDataProvider>)dataProvider
                        publishModel:(AWEVideoPublishViewModel *)publishModel {

    if (self = [super init]) {
        _dataProvider = dataProvider;
        _publishModel = publishModel;
        _autoAddedStickerViewArray = [@[] mutableCopy];
    }
    return self;
}

// init when edit real begin
- (void)setupEditViewIfNeed {

    if (self.socialStickerEditView) {
        return;
    }

    self.socialStickerEditView = [ACCSocialStickerEditView editViewWithPublishModel:self.publishModel];

    @weakify(self);
    self.socialStickerEditView.onEditFinishedBlock = ^(ACCSocialStickerView * _Nonnull socialStickerView) {
        @strongify(self);
        if (!socialStickerView.stickerModel.isNotEmpty) {
            [self.stickerContainerView removeStickerView:socialStickerView];
        }
        [self.socialStickerEditView removeFromSuperview];
        [self trackFinishEditWithFinalSocialStcikerModel:socialStickerView.stickerModel];
        self.beganEditBindingSnaphostStickerModel = nil;
    };
    self.socialStickerEditView.finishEditAnimationBlock = ^(ACCSocialStickerView * _Nonnull socialStickerView) {
        @strongify(self);
        ACCBLOCK_INVOKE(self.editViewOnFinishEdit, socialStickerView.stickerType);
    };
    self.socialStickerEditView.startEditBlock = ^(ACCSocialStickerView * _Nonnull socialStickerView){
        @strongify(self);
        ACCBLOCK_INVOKE(self.editViewOnStartEdit, socialStickerView.stickerType);
        // using copy to take a values snapshot
        self.beganEditBindingSnaphostStickerModel = [socialStickerView.stickerModel copy];
    };
}

#pragma mark - public

- (void)addAutoAddedStickerViewArray:(NSArray<ACCSocialStickerView *> *)stickerViewArray
{
    [self.autoAddedStickerViewArray addObjectsFromArray:stickerViewArray];
}

- (ACCSocialStickerView *)addSocialStickerWithModel:(ACCSocialStickerModel *)model
                                      locationModel:(AWEInteractionStickerLocationModel *)locationModel
                                   constructorBlock:(void (^)(ACCSocialStickerConfig *))constructorBlock
{
    return [self addSocialStickerWithModel:model
                             locationModel:locationModel
                     socialStickerUniqueId:nil
                          constructorBlock:constructorBlock];
}

- (ACCSocialStickerView *)addSocialStickerWithModel:(ACCSocialStickerModel *)model
                                      locationModel:(AWEInteractionStickerLocationModel *)locationModel
                              socialStickerUniqueId:(NSString *)socialStickerUniqueId
                                   constructorBlock:(void (^)(ACCSocialStickerConfig *))constructorBlock
{
    if (!model) {
        return nil;
    }

    ACCSocialStickerView *socialStickerView  =  [[ACCSocialStickerView alloc] initWithStickerModel:model
                                                                             socialStickerUniqueId:socialStickerUniqueId];

    @weakify(self);
    socialStickerView.triggerDragDeleteCallback = ^{
        @strongify(self);
        [self.logger logStickerViewWillDeleteWithEnterMethod:@"drag"];
    };
    ACCSocialStickerConfig *config = [self stickerConfig:socialStickerView locationModel:locationModel];
    if (constructorBlock) {
        constructorBlock(config);
    }
    [self.stickerContainerView addStickerView:socialStickerView config:config];
    
    return socialStickerView;
}

- (ACCSocialStickerConfig *)stickerConfig:(ACCSocialStickerView *)socialStickerView
                            locationModel:(AWEInteractionStickerLocationModel *)locationModel
{
    ACCSocialStickerConfig *config = [[ACCSocialStickerConfig alloc] init];

    @weakify(self);
    if (ACCConfigBool(ACCConfigBOOL_allow_sticker_delete)) {
        @weakify(socialStickerView);
        config.deleteAction = ^{
            @strongify(self);
            @strongify(socialStickerView);
            [self.logger logStickerViewWillDeleteWithEnterMethod:@"click"];
            [self.stickerContainerView removeStickerView:socialStickerView];
        };
    }

    config.editText = ^{
        @strongify(self);
        [self editTextStickerView:socialStickerView];
    };

    config.selectTime = ^{
        @strongify(self);
        ACCBLOCK_INVOKE(self.onTimeSelect, socialStickerView);
    };

    config.secondTapCallback = ^(__kindof ACCBaseStickerView<ACCGestureResponsibleStickerProtocol> * _Nonnull contentView, UITapGestureRecognizer * _Nonnull gesture) {
        @strongify(self);
        [self editTextStickerView:socialStickerView];
    };

    config.willDeleteCallback = ^{
        @strongify(self);
        if ([self.autoAddedStickerViewArray containsObject:socialStickerView]) {
            if (socialStickerView.stickerModel.stickerType == ACCSocialStickerTypeMention) {
                [ACCTracker() trackEvent:@"delete_at_prop" params:@{@"to_user_id" : socialStickerView.stickerModel.mentionBindingModel.userId ?: @"",
                                                                    @"auto_at" : @(1),
                                                                    @"creation_id" : self.publishModel.repoContext.createId ?: @""}];
            } else if (socialStickerView.stickerModel.stickerType == ACCSocialStickerTypeHashTag) {
                [ACCTracker() trackEvent:@"delete_tag_prop" params:@{@"tag_name" : socialStickerView.stickerModel.contentString ?: @"",
                                                                     @"auto_tag" : @(1),
                                                                     @"creation_id" : self.publishModel.repoContext.createId ?: @""}];
            }
            [self.autoAddedStickerViewArray removeObject:socialStickerView];
        }
    };
    config.typeId = ACCStickerTypeIdSocial;
    config.hierarchyId = @(ACCStickerHierarchyTypeNormal); // hierarchy is equal to text sticker
    config.timeRangeModel.pts = [NSDecimalNumber decimalNumberWithString:@"-1"];
    config.gestureInvalidFrameValue = self.dataProvider.gestureInvalidFrameValue;

    if (locationModel) {
        if (locationModel.startTime.floatValue <= 0 && locationModel.endTime.floatValue <= 0.f) {
            NSString *startTime = [NSString stringWithFormat:@"%.4f", 0.f];
            NSString *endTime = [NSString stringWithFormat:@"%.4f", self.player.stickerInitialEndTime];
            config.timeRangeModel.startTime = [NSDecimalNumber decimalNumberWithString:startTime];
            config.timeRangeModel.endTime = [NSDecimalNumber decimalNumberWithString:endTime];
        } else {
            config.timeRangeModel.startTime = locationModel.startTime;
            config.timeRangeModel.endTime = locationModel.endTime;
        }
    } else {
        NSString *startTime = [NSString stringWithFormat:@"%.4f", 0.f];
        NSString *endTime = [NSString stringWithFormat:@"%.4f", self.player.stickerInitialEndTime];
        config.timeRangeModel.startTime = [NSDecimalNumber decimalNumberWithString:startTime];
        config.timeRangeModel.endTime = [NSDecimalNumber decimalNumberWithString:endTime];
        locationModel = [AWEInteractionStickerLocationModel new];
    }

    config.geometryModel = [locationModel ratioGeometryModel];

    return config;
}

- (void)addSocialStickerAndApplyWithModel:(ACCSocialStickerModel *)model
                            locationModel:(AWEInteractionStickerLocationModel *)locationModel
                    socialStickerUniqueId:(NSString *)socialStickerUniqueId
{
    if (!model) {
        return;
    }
    ACCSocialStickerView *socialStickerView = [[ACCSocialStickerView alloc] initWithStickerModel:model
                                                                             socialStickerUniqueId:socialStickerUniqueId];
    ACCSocialStickeHashTagBindingModel *hashTagModel = [ACCSocialStickeHashTagBindingModel modelWithHashTagName: self.publishModel.repoChallenge.challenge.challengeName];
    [socialStickerView bindingWithHashTagModel:hashTagModel];
    ACCSocialStickerConfig *config = [self stickerConfig:socialStickerView locationModel:locationModel];

    UIView<ACCStickerProtocol> *socialStickerContainerView = [self.stickerContainerView addStickerView:socialStickerView config:config];
    [self apply:socialStickerContainerView index:0];

    NSMutableArray *interactionStickers = [NSMutableArray array];
    [self addSocialInteractionStickerInfo:socialStickerContainerView toArray:interactionStickers idx:0];
    self.publishModel.repoSticker.interactionStickers = interactionStickers;
}

- (void)editTextStickerView:(ACCSocialStickerView *)stickerView {

    [self setupEditViewIfNeed];
    [self.stickerContainerView.overlayView addSubview:self.socialStickerEditView];
    [self.socialStickerEditView startEditStickerView:stickerView];
}

#pragma mark - ACCStickerHandler apply
- (void)apply:(UIView<ACCStickerProtocol> *)sticker index:(NSUInteger)idx {

    ACCSocialStickerView *socialStickerView = (ACCSocialStickerView *)sticker.contentView;

    CGFloat imageScale = ACC_SCREEN_SCALE;
    // FIXED : image is blurry when scale
    CGFloat scale = [sticker.stickerGeometry.scale floatValue]  * [UIScreen mainScreen].scale;
    if (scale > imageScale) {
        imageScale = scale < 10 ? scale : 10;
    }

    UIImage *image = nil;

    if (sticker.hidden) {
        UIView<ACCStickerProtocol> *stickerCopy = [sticker copy];
        stickerCopy.hidden = NO;
        image = [stickerCopy acc_imageWithViewOnScale:imageScale];
    } else {
        image = [sticker acc_imageWithViewOnScale:imageScale];
    }

    if (!image) {
        return;
    }

    NSData *imageData = UIImagePNGRepresentation(image);
    NSString *imagePath = [self.dataProvider socialStickerImagePathForDraftWithIndex:idx];
    BOOL ret = [imageData acc_writeToFile:imagePath atomically:YES];

    if ([[NSFileManager defaultManager] fileExistsAtPath:imagePath]) {

        NSMutableDictionary *userInfo = [@{} mutableCopy];
        userInfo.acc_stickerType = ACCEditEmbeddedStickerTypeSocial;

        userInfo[kSocialStickerUserInfoUniqueIdKey] = socialStickerView.socialStickerUniqueId ?: @"";
        if ([sticker.config isKindOfClass:[ACCCommonStickerConfig class]]) {
            ACCCommonStickerConfig *config = (ACCCommonStickerConfig *)sticker.config;
            userInfo[ACCStickerEditableKey] = config.editable;
            userInfo[ACCStickerDeleteableKey] = config.deleteable;
        }

        NSString *draftDataJsonString = [socialStickerView.stickerModel draftDataJsonString];
        userInfo[kSocialStickerUserInfoDraftJsonDataKey] = draftDataJsonString;

        ACCStickerGeometryModel *geometryCopy = [sticker.stickerGeometry copy];
        geometryCopy.preferredRatio = NO;
        AWEInteractionStickerLocationModel *stickerLocation = [[AWEInteractionStickerLocationModel alloc] initWithGeometryModel:geometryCopy andTimeRangeModel:sticker.stickerTimeRange];

        NSInteger stickerID = [self.player addInfoSticker:imagePath withEffectInfo:nil userInfo:userInfo];
        CGSize stickerSize = [self.player getInfoStickerSize:stickerID];
        CGFloat realScale = stickerSize.width > 0 ? image.size.width / stickerSize.width : 1;

        [self.player setStickerAbove:stickerID];
        [self.player setSticker:stickerID startTime:sticker.realStartTime duration:sticker.realDuration];

        // update sticker position
        CGFloat offsetX = [stickerLocation.x floatValue];
        CGFloat offsetY = -[stickerLocation.y floatValue];
        CGFloat stickerAngle = [stickerLocation.rotation floatValue];
        CGFloat scale = [stickerLocation.scale floatValue];
        scale = scale * realScale;

        [self.player setSticker:stickerID offsetX:offsetX offsetY:offsetY angle:stickerAngle scale:scale];
        sticker.hidden = YES;
        !self.onStickerApplySuccess ?: self.onStickerApplySuccess();
    } else {
        AWELogToolInfo(AWELogToolTagEdit,
                       @"socialStickersForPublishInfo:create Failed:%@, write Failed:%@",
                       @(!image), @(ret));
    }
}

#pragma mark - ACCStickerHandler store
- (void)addInteractionStickerInfoToArray:(NSMutableArray *)interactionStickers idx:(NSInteger)stickerIndex {

    for (UIView<ACCStickerProtocol> *sticker in [[self.stickerContainerView stickerViewsWithTypeId:ACCStickerTypeIdSocial] acc_filter:^BOOL(ACCStickerViewType  _Nonnull item) {
        return [item.contentView isKindOfClass:[ACCSocialStickerView class]];
    }]) {
        [self addSocialInteractionStickerInfo:sticker toArray:interactionStickers idx:stickerIndex];
    }
}

- (void)addSocialInteractionStickerInfo:(UIView<ACCStickerProtocol> *)stickerView
                                toArray:(NSMutableArray *)interactionStickers
                                    idx:(NSInteger)stickerIndex {

    ACCSocialStickerView *socialView = (ACCSocialStickerView *)(stickerView.contentView);
    ACCSocialStickerModel *stickerModel = socialView.stickerModel;
    
    AWEInteractionStickerModel *interactionStickerInfo = nil;
    
    { /* ························· server data binding unit ··························· */

        // added keyvalue  to server  by manual , auto serialization may case property name changed
        if (stickerModel.stickerType == ACCSocialStickerTypeMention) {
            interactionStickerInfo = [[AWEInteractionMentionStickerModel alloc] init];
            interactionStickerInfo.type = AWEInteractionStickerTypeMention;
            NSMutableDictionary *mentionedUserInfo = [NSMutableDictionary dictionaryWithCapacity:5];
            mentionedUserInfo[@"text_content"] = stickerModel.contentString ? : @"";

            if ([stickerModel hasVaildMentionBindingData]) {
                ACCSocialStickeMentionBindingModel *bindingModel = stickerModel.mentionBindingModel;
                [mentionedUserInfo addEntriesFromDictionary:@{@"user_id"  : bindingModel.userId ? : @"",
                                                              @"sec_uid"  : bindingModel.secUserId ? : @"",
                                                              @"user_name" : bindingModel.userName ? : @"",
                                                              @"followStatus" : @(bindingModel.followStatus)
                }];
            };

            ((AWEInteractionMentionStickerModel *)interactionStickerInfo).mentionedUserInfo = [mentionedUserInfo copy];

        } else if (stickerModel.stickerType == ACCSocialStickerTypeHashTag){

            interactionStickerInfo = [[AWEInteractionHashtagStickerModel alloc] init];
            interactionStickerInfo.type = AWEInteractionStickerTypeHashtag;
            // hashtag matched all string for binding content
            ((AWEInteractionHashtagStickerModel *)interactionStickerInfo).hashtagInfo = @{@"hashtag_name" : stickerModel.contentString ? : @""};
        }
    }
    
    /* ·························  model create unit ··························· */
    if (interactionStickerInfo == nil) {
        interactionStickerInfo = [AWEInteractionStickerModel new];
    }
    
    interactionStickerInfo.stickerID = stickerModel.effectIdentifier;
    interactionStickerInfo.type = acc_convertSocialStickerTypeToInteractionStickerType(stickerModel.stickerType);
    interactionStickerInfo.localStickerUniqueId = socialView.socialStickerUniqueId;
    interactionStickerInfo.index = [interactionStickers count] + stickerIndex;
    interactionStickerInfo.adaptorPlayer = [self.player needAdaptPlayer];
    interactionStickerInfo.isAutoAdded = stickerModel.isAutoAdded;
    

    { /* ························· unique check unit ··························· */

        if (ACC_isEmptyString(socialView.socialStickerUniqueId) ||
           [self isSocialStickerAlreayAdded:socialView toInteractionArray:[interactionStickers copy]]) {
            /// @Discussion @Guochen Yang, the func 'addInteractionStickerInfoToArray: idx' should only called once, but not expected  now.
            return;
        }
    }

    { /* ························· valid check unit ··························· */

        if (ACC_isEmptyString(stickerModel.contentString)) {
            return;
        }
    }

    { /* ························· location process unit ··························· */
        CGPoint point = [stickerView convertPoint:socialView.center toView:[stickerView.stickerContainer containerView]];
        AWEInteractionStickerLocationModel *locationInfoModel = [[AWEInteractionStickerLocationModel alloc] initWithGeometryModel:[stickerView interactiveStickerGeometryWithCenterInPlayer:point interactiveBoundsSize:socialView.bounds.size] andTimeRangeModel:stickerView.stickerTimeRange];
        
        BOOL enableSilentPublish = ACCConfigBool(ACCConfigBOOL_profile_as_story_enable_silent_publish);
        if ((self.publishModel.repoQuickStory.isAvatarQuickStory && self.publishModel.repoQuickStory.isAvatarDirectPush && !enableSilentPublish) ||
            (self.publishModel.repoQuickStory.isNewcomersStory && !enableSilentPublish) ||
            (self.publishModel.repoQuickStory.isProfileBgStory && self.publishModel.repoQuickStory.isAvatarDirectPush) ||
            (self.publishModel.repoQuickStory.isNewCityStory && self.publishModel.repoQuickStory.isAvatarDirectPush)) { //静默发布头像 or 新人视频
            NSDecimalNumber *offsetCenterX = [NSDecimalNumber decimalNumberWithString:@"0.5f"];
            NSDecimalNumber *offsetCenterY = [NSDecimalNumber decimalNumberWithString:@"0.54f"];
            NSDecimalNumber *offsetHeight = [NSDecimalNumber decimalNumberWithString:@"0.02f"];
            locationInfoModel.x = [locationInfoModel.x decimalNumberByAdding:offsetCenterX];
            locationInfoModel.y = [locationInfoModel.y decimalNumberByAdding:offsetCenterY];
            locationInfoModel.height = [locationInfoModel.height decimalNumberByAdding:offsetHeight];
        }
        if (locationInfoModel.width && locationInfoModel.height) {
            AWEInteractionStickerLocationModel *finalLocation = [self.player resetStickerLocation:locationInfoModel isRecover:NO];
            if (!finalLocation) {
                return;
            }
            [interactionStickerInfo storeLocationModelToTrackInfo:finalLocation];
        }
    }

    /* ························· congratulation, effective case! ··························· */
    [interactionStickers addObject:interactionStickerInfo];
}

- (BOOL)isSocialStickerAlreayAdded:(ACCSocialStickerView *)sticker
                toInteractionArray:(NSArray <AWEInteractionStickerModel *> *)array {

    for (AWEInteractionStickerModel * model in array) {
        if (!ACC_isEmptyString(model.localStickerUniqueId) &&
            [model.localStickerUniqueId isEqualToString:sticker.socialStickerUniqueId]) {
            return YES;
        }
    }
    return NO;
}

#pragma mark - Express Sticker

- (BOOL)canExpressSticker:(ACCEditorStickerConfig *)stickerConfig
{
    return [stickerConfig isKindOfClass:[ACCEditorMentionStickerConfig class]] || [stickerConfig isKindOfClass:[ACCEditorHashtagStickerConfig class]];
}

- (void)expressSticker:(ACCEditorStickerConfig *)stickerConfig
{
    [self expressSticker:stickerConfig withCompletion:^{
        
    }];
}

- (void)expressSticker:(ACCEditorStickerConfig *)stickerConfig withCompletion:(void (^)(void))completionHandler
{
    if ([self canExpressSticker:stickerConfig]) {
        ACCSocialStickerModel *socialStickerModel = nil;
        if ([stickerConfig isKindOfClass:[ACCEditorHashtagStickerConfig class]]) {
            ACCEditorHashtagStickerConfig *hashtagStickerConfig = (ACCEditorHashtagStickerConfig *)stickerConfig;
            socialStickerModel = [hashtagStickerConfig socialStickerModel];
        } else if ([stickerConfig isKindOfClass:[ACCEditorMentionStickerConfig class]]) {
            ACCEditorMentionStickerConfig *mentionStickerConfig = (ACCEditorMentionStickerConfig *)stickerConfig;
            socialStickerModel = [mentionStickerConfig socialStickerModel];
        }
        
        if (socialStickerModel != nil) {
            AWEInteractionStickerLocationModel *locationModel = [stickerConfig locationModel];
            locationModel.startTime = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.4f", 0.f]];
            locationModel.endTime = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.4f", self.player.stickerInitialEndTime]];
            ACCSocialStickerView *stickerView = [self addSocialStickerWithModel:socialStickerModel locationModel:locationModel constructorBlock:^(ACCSocialStickerConfig *config) {
                config.deleteable = @(stickerConfig.deleteable);
                config.editable = @(stickerConfig.editable);
                if ([config.editable isEqual:@NO]) {
                    config.secondTapCallback = nil;
                }
                config.alignPoint = stickerConfig.location.alignPoint;
                config.alignPosition = stickerConfig.location.alignPosition;
            }];
            if (!stickerConfig.location.persistentAlign) {
                [self.stickerContainerView stickerViewWithContentView:stickerView].config.alignPosition = nil;
            }
        }
    }
}

#pragma mark - ACCStickerHandler recover
- (void)recoverSticker:(ACCRecoverStickerModel *)sticker {

    if ([self canRecoverSticker:sticker]) {

        NSString *socialStickerUniqueId = [sticker.infoSticker.userinfo acc_stringValueForKey:kSocialStickerUserInfoUniqueIdKey];
        if (ACC_isEmptyString(socialStickerUniqueId)) {
            return;
        }

        AWEInteractionStickerModel *interactionStickerModel = [self.dataProvider.interactionStickers acc_match:^BOOL(AWEInteractionStickerModel * _Nonnull item) {
            return item.trackInfo &&
            (item.type == AWEInteractionStickerTypeHashtag || item.type == AWEInteractionStickerTypeMention) &&
            [item.localStickerUniqueId isEqualToString:socialStickerUniqueId];
        }];

        ACCSocialStickerModel *socialStickerModel = [self socialStickerModelWithInfoSticker:sticker.infoSticker
                                                                    interactionStickerModel:interactionStickerModel];
        if (socialStickerModel) {
            AWEInteractionStickerLocationModel *locationModel = [interactionStickerModel fetchLocationModelFromTrackInfo];
            if (interactionStickerModel.adaptorPlayer) {
                locationModel = [self.player resetStickerLocation:locationModel isRecover:YES];
            }
            
            NSNumber *deleteable = [sticker.infoSticker.userinfo acc_objectForKey:ACCStickerDeleteableKey];
            NSNumber *editable = [sticker.infoSticker.userinfo acc_objectForKey:ACCStickerEditableKey];
            
            [self addSocialStickerWithModel:socialStickerModel
                              locationModel:locationModel
                      socialStickerUniqueId:socialStickerUniqueId
                           constructorBlock:^(ACCSocialStickerConfig *config) {
                config.deleteable = deleteable;
                config.editable = editable;
            }];
        }
    }
}

- (BOOL)canRecoverSticker:(ACCRecoverStickerModel *)sticker {
    return [sticker.infoSticker acc_stickerType] == ACCEditEmbeddedStickerTypeSocial;
}

#pragma mark - ACCStickerHandler handler result
- (BOOL)canHandleSticker:(UIView<ACCStickerProtocol> *)sticker {
    return [sticker.contentView isKindOfClass:[ACCSocialStickerView class]];
}

#pragma mark - ACCStickerHandler life cycle

- (void)reset {
    [[self.stickerContainerView stickerViewsWithTypeId:ACCStickerTypeIdSocial] enumerateObjectsUsingBlock:^(ACCStickerViewType  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([[obj contentView] isKindOfClass:[ACCSocialStickerView class]]) {
            if (ACC_FLOAT_GREATER_THAN(0.1, obj.realStartTime)) {
                obj.hidden = NO;
            } else {
                obj.hidden = YES;
            }
        }
    }];

    [self.player removeStickerWithType:ACCEditEmbeddedStickerTypeSocial];
}

#pragma mark - utilitys
- (ACCSocialStickerModel *)socialStickerModelWithInfoSticker:(IESInfoSticker *)infoSticker
                                     interactionStickerModel:(AWEInteractionStickerModel *)interactionStickerModel {

    if (!infoSticker || !interactionStickerModel) {
        return nil;
    }

    NSNumber *matchedSocialStickerType = acc_convertSocialStickerTypeFromInteractionStickerType(interactionStickerModel.type);
    if (matchedSocialStickerType == nil) {
        return nil;
    }

    NSString *draftJsonString = [infoSticker.userinfo acc_stringValueForKey:kSocialStickerUserInfoDraftJsonDataKey];
    if (ACC_isEmptyString(draftJsonString)) {
        return nil;
    }

    ACCSocialStickerModel *socialStickerModel = [[ACCSocialStickerModel alloc] initWithStickerType:matchedSocialStickerType.integerValue
                                                                                  effectIdentifier:interactionStickerModel.stickerID];
    [socialStickerModel recoverDataFromDraftJsonString:draftJsonString];

    return socialStickerModel;
}

#pragma mark - track
- (void)trackFinishEditWithFinalSocialStcikerModel:(ACCSocialStickerModel *)stickerModel {

    if (!stickerModel.isNotEmpty ||
        stickerModel.stickerType != self.beganEditBindingSnaphostStickerModel.stickerType) {
        return;
    }

    if (stickerModel.stickerType == ACCSocialStickerTypeMention) {

        BOOL isBothBindNoUser = (ACC_isEmptyString(stickerModel.mentionBindingModel.userId) &&
                                 ACC_isEmptyString(self.beganEditBindingSnaphostStickerModel.mentionBindingModel.userId));

        BOOL isFirstEdit = ACC_isEmptyString(self.beganEditBindingSnaphostStickerModel.contentString);

        BOOL isBindSameUser = ([stickerModel.mentionBindingModel.userId isEqualToString:self.beganEditBindingSnaphostStickerModel.mentionBindingModel.userId]);

        // in other word, case :'both bind no user & is not first edit'  equal to case 'bind same user'
        if ((isBothBindNoUser || isBindSameUser) && !isFirstEdit) {
            return;
        }

        [ACCTracker() trackEvent:@"add_at_prop" params:@{@"to_user_id" : stickerModel.mentionBindingModel.userId ?: @"",
                                                         @"auto_at" : @(0),
                                                         @"creation_id" : self.publishModel.repoContext.createId ?: @""
        }];
        
        // 分析师确认上面老的会被下掉，所以直接新增埋点
        NSMutableDictionary *params = [NSMutableDictionary dictionary];
        [params addEntriesFromDictionary:self.publishModel.repoTrack.referExtra?:@{}];
        [params addEntriesFromDictionary:stickerModel.trackInfo?:@{}];
        params[@"enter_from"] = self.publishModel.repoTrack.enterFrom ?:@"video_edit_page";
        [ACCTracker() trackEvent:@"add_hashtag_at_sticker" params:[params copy]];

    } else {

        // hashtag is easy to track, just need check content string
        if ([self.beganEditBindingSnaphostStickerModel.contentString isEqualToString:stickerModel.contentString]) {
            return;
        }

        [ACCTracker() trackEvent:@"add_tag_prop" params:@{@"tag_name" : stickerModel.contentString ? : @"",
                                                          @"auto_tag" : @(0),
                                                          @"creation_id" : self.publishModel.repoContext.createId ?: @""
        }];
        
        // 分析师确认上面老的会被下掉，所以直接新增埋点
        NSMutableDictionary *params = [NSMutableDictionary dictionary];
        [params addEntriesFromDictionary:self.publishModel.repoTrack.referExtra?:@{}];
        [params addEntriesFromDictionary:stickerModel.trackInfo?:@{}];
        params[@"enter_from"] = self.publishModel.repoTrack.enterFrom ?:@"video_edit_page";
        [ACCTracker() trackEvent:@"add_hashtag_at_sticker" params:[params copy]];
    }

}

#pragma mark - ACCStickerMigrationProtocol

+ (BOOL)fillCrossPlatformStickerByUserInfo:(NSDictionary *)userInfo repository:(id<ACCPublishRepository>)sessionModel context:(id<ACCCrossPlatformMigrateContext>)context sticker:(NLESegmentSticker_OC *__autoreleasing *)sticker
{
    if (userInfo.acc_stickerType == ACCEditEmbeddedStickerTypeSocial) {
        NSString *socialStickerUniqueId = [userInfo acc_stringValueForKey:kSocialStickerUserInfoUniqueIdKey];
        if (ACC_isEmptyString(socialStickerUniqueId)) {
            return YES;
        }
        
        ACCRepoStickerModel *stickerModel = [sessionModel extensionModelOfClass:[ACCRepoStickerModel class]];
        AWEInteractionStickerModel *interactionStickerModel = [stickerModel.interactionStickers acc_match:^BOOL(AWEInteractionStickerModel * _Nonnull item) {
            return item.trackInfo
            && (item.type == AWEInteractionStickerTypeHashtag || item.type == AWEInteractionStickerTypeMention)
            && [item.localStickerUniqueId isEqualToString:socialStickerUniqueId];
        }];
        
        if (interactionStickerModel == nil) {
            return YES;
        }
        
        ACCCrossPlatformStickerType stickerType = interactionStickerModel.type == AWEInteractionStickerTypeHashtag ? ACCCrossPlatformStickerTypeHashtag : ACCCrossPlatformStickerTypeMention;
        NLESegmentImageSticker_OC *sticker_ = [[NLESegmentImageSticker_OC alloc] init];
        sticker_.stickerType = stickerType;
        sticker_.imageFile = [[NLEResourceNode_OC alloc] init];
        sticker_.imageFile.resourceType = NLEResourceTypeImageSticker;
        sticker_.imageFile.resourceFile = context.resourcePath;
        
        NSError *error = nil;
        sticker_.extraDict = [NSMutableDictionary dictionary];
        sticker_.extraDict[ACCInteractionStickerTransferKey] = [MTLJSONAdapter JSONDictionaryFromModel:interactionStickerModel error:&error] ?: @{};
        if (error != nil) {
            AWELogToolError2(@"SocialSticker", AWELogToolTagDraft, @"Interaction Sticker Model Convert To Json Error:%@", error);
        }
        sticker_.extraDict[@"sticker_id"] = interactionStickerModel.stickerID;
        sticker_.extraDict[ACCCrossPlatformiOSResourcePathKey] = context.resourcePath;
        sticker_.extraDict[ACCStickerDeleteableKey] = userInfo[ACCStickerDeleteableKey];
        sticker_.extraDict[ACCStickerEditableKey] = userInfo[ACCStickerEditableKey];
        *sticker = sticker_;
        
        return YES;
    }
    return NO;
}

+ (void)updateUserInfo:(NSDictionary *__autoreleasing *)userInfo repoModel:(id<ACCPublishRepository>)sessionModel byCrossPlatformSlot:(nonnull NLETrackSlot_OC *)slot
{
    if (slot.sticker.stickerType == ACCCrossPlatformStickerTypeHashtag
        || slot.sticker.stickerType == ACCCrossPlatformStickerTypeMention) {
        NLESegmentSticker_OC *sticker = slot.sticker;
        NSError *error = nil;
        AWEInteractionStickerModel *interactionStickerModel = [MTLJSONAdapter modelOfClass:[AWEInteractionStickerModel class] fromJSONDictionary:[sticker.extraDict acc_dictionaryValueForKey:ACCInteractionStickerTransferKey] error:&error];
        if (interactionStickerModel == nil) {
            if (error != nil) {
                AWELogToolError2(@"SocialSticker", AWELogToolTagDraft, @"Interaction Sticker Json Convert To Model Error:%@", error);
            }
            return;
        }
        
        interactionStickerModel.stickerID = [sticker.extraDict acc_stringValueForKey:@"sticker_id"];
        
        NSDictionary *structDict = [sticker.extraDict btd_dictionaryValueForKey:@"struct"];
        if (structDict && [structDict isKindOfClass:NSDictionary.class]) {
            // 先看本地是否存在，否则随机生成的ID肯定不一致，从而导致mention和hastag贴纸没法恢复
            interactionStickerModel.localStickerUniqueId = [structDict acc_stringValueForKey:@"localStickerUniqueId"];
        }
        if (!interactionStickerModel.localStickerUniqueId) {
            // 如果本地不存在数据，则这个草稿可能来自于跨端迁移，则临时生成一个随机值
            interactionStickerModel.localStickerUniqueId = [NSString stringWithFormat:@"%@", @([[NSDate date] timeIntervalSince1970])];
        }
        
        NSNumber *matchedSocialStickerType = acc_convertSocialStickerTypeFromInteractionStickerType(interactionStickerModel.type);
        if (matchedSocialStickerType == nil) {
            return;
        }
        
        ACCRepoStickerModel *repoStickerModel = [sessionModel extensionModelOfClass:[ACCRepoStickerModel class]];
        NSMutableArray *interactionStickers = [NSMutableArray array];
        [interactionStickers addObject:interactionStickerModel];
        if (!ACC_isEmptyArray(repoStickerModel.interactionStickers)) {
            [interactionStickers addObjectsFromArray:repoStickerModel.interactionStickers];
        }
        repoStickerModel.interactionStickers = interactionStickers;
        
        NSMutableDictionary *temp_userInfo = [NSMutableDictionary dictionary];
        temp_userInfo.acc_stickerType = ACCEditEmbeddedStickerTypeSocial;
        temp_userInfo[kSocialStickerUserInfoUniqueIdKey] = interactionStickerModel.localStickerUniqueId ?: @"";
        temp_userInfo[ACCStickerDeleteableKey] = [sticker.extraDict acc_objectForKey:ACCStickerDeleteableKey];
        temp_userInfo[ACCStickerEditableKey] = [sticker.extraDict acc_objectForKey:ACCStickerEditableKey];

        ACCSocialStickerModel *stickerModel = [[ACCSocialStickerModel alloc] initWithStickerType:matchedSocialStickerType.integerValue effectIdentifier:interactionStickerModel.stickerID];
        if (interactionStickerModel.type == AWEInteractionStickerTypeHashtag) {
            AWEInteractionHashtagStickerModel *hashtagSticker = ([interactionStickerModel isKindOfClass:[AWEInteractionHashtagStickerModel class]]) ? (AWEInteractionHashtagStickerModel *)interactionStickerModel : nil;
            stickerModel.contentString = [hashtagSticker.hashtagInfo acc_stringValueForKey:@"hashtag_name"];
        } else {
            AWEInteractionMentionStickerModel *mentionSticker = ([interactionStickerModel isKindOfClass:[AWEInteractionMentionStickerModel class]]) ? (AWEInteractionMentionStickerModel *)interactionStickerModel : nil;
            stickerModel.contentString = [mentionSticker.mentionedUserInfo acc_stringValueForKey:@"text_content"];
        }
        
        if (sticker.stickerType == ACCCrossPlatformStickerTypeMention) {
            AWEInteractionMentionStickerModel *mentionSticker = ([interactionStickerModel isKindOfClass:[AWEInteractionMentionStickerModel class]]) ? (AWEInteractionMentionStickerModel *)interactionStickerModel : nil;
            NSDictionary *mentionedDic = mentionSticker.mentionedUserInfo;
            ACCSocialStickeMentionBindingModel *bindingModel = [ACCSocialStickeMentionBindingModel modelWithSecUserId:[mentionedDic acc_stringValueForKey:@"sec_uid"]
                                                                                                               userId:[mentionedDic acc_stringValueForKey:@"user_id"]
                                                                                                             userName:[mentionedDic acc_stringValueForKey:@"user_name"]
                                                                                                         followStatus:[mentionedDic acc_integerValueForKey:@"followStatus"]];
            stickerModel.mentionBindingModel = bindingModel;
        }
        temp_userInfo[kSocialStickerUserInfoDraftJsonDataKey] = [stickerModel draftDataJsonString];
        
        *userInfo = temp_userInfo;
    }
}


@end
