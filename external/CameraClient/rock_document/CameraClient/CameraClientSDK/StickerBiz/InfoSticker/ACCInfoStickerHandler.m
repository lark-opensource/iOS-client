//
//  ACCInfoStickerHandler.m
//  CameraClient-Pods-Aweme
//
//  Created by yangguocheng on 2020/11/16.
//

#import "AWERepoVideoInfoModel.h"
#import "ACCInfoStickerHandler.h"
#import "ACCStickerBizDefines.h"
#import "ACCInfoStickerContentView.h"
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreationKitArch/AWEInteractionStickerLocationModel+ACCSticker.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreationKitArch/ACCEditAndPublishConstants.h>
#import <NLEPlatform/NLESegmentInfoSticker+iOS.h>
#import "NLESegmentSticker_OC+ACCAdditions.h"
#import "NLETrackSlot_OC+ACCAdditions.h"
#import "ACCImageAlbumStickerModel.h"
#import <CreativeKit/ACCMacros.h>
#import <CreationKitArch/ACCPublishRepository.h>
#import "AWERepoStickerModel.h"
#import <CameraClient/IESEffectModel+DStickerAddditions.h>
#import <CreationKitInfra/ACCRACWrapper.h>
#import "ACCEditStickerSelectTimeManager.h"
#import "ACCModernPinStickerViewControllerInputData.h"
#import "ACCModernPinStickerViewController.h"
#import "ACCVideoEditStickerContainerConfig.h"
#import <CreativeKitSticker/ACCStickerContainerView+ACCStickerCopying.h>
#import "ACCStickerGroup.h"
#import <CreationKitInfra/ACCToastProtocol.h>
#import <CameraClient/ACCDraftProtocol.h>
#import <CreationKitArch/ACCRepoDraftModel.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import <CreativeKit/ACCMonitorProtocol.h>
#import <CameraClient/ACCRepoQuickStoryModel.h>
#import <CameraClient/ACCRepoImageAlbumInfoModel.h>
#import <CreationKitArch/AWEInfoStickerInfo.h>
#import "AWEInfoStickerManager.h"
#import "ACCConfigKeyDefines.h"
#import "IESInfoSticker+ACCAdditions.h"

#import <EffectPlatformSDK/IESThirdPartyStickerModel.h>
#import <CreationKitInfra/NSString+ACCAdditions.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import <CameraClientModel/ACCCrossPlatformStickerType.h>
#import <CameraClientModel/ACCVideoCanvasType.h>

static CGFloat const kAWEInfoStickerTotalDuration = -1;
static CGFloat const kAWEInfoCustomStickerDefaultLength = 145;
static CGFloat const kACCVInfoStickerMinLength = 22.f;  //kVideoStickerEditCircleViewEdgeInset

@interface ACCInfoStickerHandler ()

@property (nonatomic, strong) ACCEditStickerSelectTimeManager *selectTimeManager;
@property (nonatomic, strong) AWEInfoStickerManager *stickerManager;

@end

@implementation ACCInfoStickerHandler

- (AWEInfoStickerManager *)stickerManager
{
    if (!_stickerManager) {
        _stickerManager = [[AWEInfoStickerManager alloc] init];
    }
    return _stickerManager;
}

- (NSInteger)addInfoSticker:(IESEffectModel *)sticker
               stickerProps:(IESInfoStickerProps *)stickerProps
        targetMaxEdgeNumber:(NSNumber *)targetMaxEdgeNumber
                       path:(NSString *)path
                    tabName:(NSString *)tabName
        userInfoConstructor:(void (^)(NSMutableDictionary * _Nonnull))userInfoConstructor
                constructor:(void (^)(ACCInfoStickerConfig * _Nonnull, CGSize))constructor
               onCompletion:(void (^)(void))completionBlock
{
    return [self addInfoSticker:sticker
                   stickerProps:stickerProps
            targetMaxEdgeNumber:targetMaxEdgeNumber
              infoStickerConfig:nil
                           path:path
                        tabName:tabName
            userInfoConstructor:userInfoConstructor
                    constructor:constructor
                   onCompletion:completionBlock];
}

- (NSInteger)addInfoSticker:(IESEffectModel *)sticker
               stickerProps:(nullable IESInfoStickerProps *)stickerProps
        targetMaxEdgeNumber:(NSNumber *)targetMaxEdgeNumber
          infoStickerConfig:(ACCEditorInfoStickerConfig *)infoStickerConfig
                       path:(NSString *)path
                    tabName:(NSString *)tabName
        userInfoConstructor:(void (^)(NSMutableDictionary *userInfo))userInfoConstructor
                constructor:(void (^)(ACCInfoStickerConfig * _Nonnull config, CGSize size))constructor
               onCompletion:(void (^)(void))completionBlock
{
    __block NSInteger stickerId; // do not remove `__block`
    __block NSMutableArray *params = [NSMutableArray new];
    
    if (!ACC_isEmptyArray(infoStickerConfig.effectInfos)) {
        [params addObjectsFromArray:infoStickerConfig.effectInfos];
    }

    dispatch_block_t configApplyStickerBlockAndInvoke = ^(void) {
        [self applyContainerSticker:stickerId effectModel:sticker thirdPartyModel:nil targetMaxEdgeNumber:targetMaxEdgeNumber stickerProps:stickerProps  configConstructor:^(ACCInfoStickerConfig * _Nonnull config, CGSize size) {
            if (constructor) {
                constructor(config, size);
            }
        } onCompletion:completionBlock];
    };

    NSDictionary *userInfo = ({
        NSMutableDictionary *info = [NSMutableDictionary dictionary];
        // Larry.lai: don't remove stickerID, this need to be persist
        info[@"stickerID"] = sticker.effectIdentifier ?: @"";
        info[@"tabName"] = tabName ?: @"";
        info[@"customStickerFilePath"] = sticker.customStickerFilePath ?: @"";
        info[@"useRemoveBg"] = @(sticker.useRemoveBg);
        if ([sticker isUploadSticker]) {
            info.acc_stickerType = ACCEditEmbeddedStickerTypeCustom;
        }
        info[kACCStickerUUIDKey] = [NSUUID UUID].UUIDString ?: @"";
        if (userInfoConstructor) {
            userInfoConstructor(info);
        }
        [info copy];
    });
    if ([sticker isTypeWeather]) {
        // 温度贴纸，parameter唯一，为温度
        @weakify(self);
        [self.stickerManager fetchTemperatureCompletion:^(NSError *error, NSString *temperature) {
            @strongify(self);
            if (error) {
                AWELogToolError(AWELogToolTagEdit, @"fetchTemperature error: %@", error);
                [ACCToast()
                    showError:ACCLocalizedString(@"com_mig_cannot_acquire_local_temperature", @"无法获取本地温度")];
                return;
            }
            if (temperature) {
                [params addObject:temperature];
            }
            stickerId = [self.editService.sticker addInfoSticker:path withEffectInfo:params userInfo:userInfo];
            ACCBLOCK_INVOKE(configApplyStickerBlockAndInvoke);
        }];
    } else if ([sticker isTypeTime] || [sticker isTypeDate]) {
        // 日期、时间贴纸，parameter唯一，为时间戳
        NSString *time = [self.stickerManager fetchCurrentTime];
        if (time) {
            [params addObject:time];
        }
        stickerId = [self.editService.sticker addInfoSticker:path withEffectInfo:params userInfo:userInfo];
        ACCBLOCK_INVOKE(configApplyStickerBlockAndInvoke);
    } else if ([sticker isTypeMagnifier]) {
        NSMutableDictionary *dictionary = [userInfo mutableCopy];
        dictionary.acc_stickerType = ACCEditEmbeddedStickerTypeMagnifier;
        userInfo = [dictionary copy];
        stickerId = [self.editService.sticker addInfoSticker:path withEffectInfo:params userInfo:userInfo];
        ACCBLOCK_INVOKE(configApplyStickerBlockAndInvoke);
    } else {
        if ([sticker isDaily]) {
            NSMutableDictionary *dictionary = [userInfo mutableCopy];
            dictionary.acc_stickerType = ACCEditEmbeddedStickerTypeDaily;
            dictionary[ACCEffectIdentifierKey] = sticker.effectIdentifier;
            userInfo = [dictionary copy];
        }
        stickerId = [self.editService.sticker addInfoSticker:path withEffectInfo:params userInfo:userInfo];
        
        // 设置信息化贴纸的关联动画资源
        if (infoStickerConfig.associatedAnimationEffectModel.downloaded) {
            @weakify(self);
            [ACCDraft() saveInfoStickerPath:infoStickerConfig.associatedAnimationEffectModel.filePath draftID:self.repository.repoDraft.taskID completion:^(NSError *draftError, NSString *draftStickerPath) {
                
                @strongify(self);
                // 动画资源设置出错了不block，log下即可
                if (draftError || draftStickerPath.length == 0) {
                    AWELogToolError(AWELogToolTagEdit, @"save info sticker to draft failed: %@", draftError);
                } else {
                    [self.editService.sticker setStickerAnimationWithStckerID:stickerId animationType:3 filePath:draftStickerPath duration:infoStickerConfig.associatedAnimationDuration];
                }
                ACCBLOCK_INVOKE(configApplyStickerBlockAndInvoke);
            }];
        } else {
            ACCBLOCK_INVOKE(configApplyStickerBlockAndInvoke);
        }
    }
    return stickerId;
}

#pragma mark - Sticker Expess

- (BOOL)canExpressSticker:(ACCEditorStickerConfig *)stickerConfig
{
    return [stickerConfig isKindOfClass:[ACCEditorInfoStickerConfig class]];
}

- (void)expressSticker:(ACCEditorStickerConfig *)stickerConfig
{
    [self expressSticker:stickerConfig onCompletion:^{
    
    }];
}

- (void)expressSticker:(ACCEditorStickerConfig *)stickerConfig onCompletion:(nonnull void (^)(void))completionHandler
{
    if ([self canExpressSticker:stickerConfig]) {
        ACCEditorInfoStickerConfig *infoStickerConfig = (ACCEditorInfoStickerConfig *)stickerConfig;
        AWEInteractionStickerLocationModel *locationModel = [stickerConfig locationModel];

        @weakify(self);
        [ACCDraft() saveInfoStickerPath:infoStickerConfig.effectModel.filePath draftID:self.repository.repoDraft.taskID completion:^(NSError *draftError, NSString *draftStickerPath) {
            if (draftError || ACC_isEmptyString(draftStickerPath)) {
                [ACCToast() showError:ACCLocalizedCurrentString(@"error_retry")];
                AWELogToolError(AWELogToolTagEdit, @"save info sticker to draft failed: %@", draftError);
                return;
            }
            @strongify(self);
            [self addInfoSticker:infoStickerConfig.effectModel stickerProps:({
                IESInfoStickerProps *props = [[IESInfoStickerProps alloc] init];
                props.offsetX = ([locationModel.x floatValue] - 0.5) * self.repository.repoVideoInfo.playerFrame.size.width;
                props.offsetY = (0.5 - [locationModel.y floatValue]) * self.repository.repoVideoInfo.playerFrame.size.height;
                props.angle = [locationModel.rotation floatValue];
                props.scale = [locationModel.scale floatValue];
                props;
            })
             targetMaxEdgeNumber:infoStickerConfig.maxEdgeNumber
               infoStickerConfig:infoStickerConfig
                            path:draftStickerPath
                         tabName:@""
             userInfoConstructor:^(NSMutableDictionary * _Nonnull userInfo) {
                userInfo[ACCStickerDeleteableKey] = @(infoStickerConfig.deleteable);
            }
                     constructor:^(ACCInfoStickerConfig * _Nonnull config, CGSize size) {
                config.deleteable = @(stickerConfig.deleteable);
            } onCompletion:completionHandler];
        }];

    } else if (completionHandler) {
        completionHandler();
    }
}

#pragma mark -

- (void)applyContainerSticker:(NSInteger)stickerId
                  effectModel:(nullable IESEffectModel *)effectModel
              thirdPartyModel:(nullable IESThirdPartyStickerModel *)thirdPartyModel
                 stickerProps:(nullable IESInfoStickerProps *)stickerProps
            configConstructor:(nullable void (^)(ACCInfoStickerConfig *config, CGSize size))constructor
                 onCompletion:(nullable void (^)(void))completionBlock
{
    [self applyContainerSticker:stickerId effectModel:effectModel thirdPartyModel:thirdPartyModel targetMaxEdgeNumber:nil stickerProps:stickerProps configConstructor:constructor onCompletion:completionBlock];
}

- (void)applyContainerSticker:(NSInteger)stickerId
                  effectModel:(IESEffectModel *)effectModel
              thirdPartyModel:(nullable IESThirdPartyStickerModel *)thirdPartyModel
          targetMaxEdgeNumber:(NSNumber *)targetMaxEdgeNumber
                 stickerProps:(IESInfoStickerProps *)stickerProps
            configConstructor:(nullable void (^)(ACCInfoStickerConfig * _Nonnull, CGSize))constructor
                 onCompletion:(void (^)(void))completionBlock
{
    BOOL isLyricSticker = NO;
    if (effectModel != nil) {
        isLyricSticker = [effectModel isTypeMusicLyric];
    }
    if (isLyricSticker) {
        return;
    }

    if (stickerId < 0) {
        return;
    }

    if (stickerProps) {
        [[self editService].sticker setSticker:stickerId
                                       offsetX:stickerProps.offsetX
                                       offsetY:stickerProps.offsetY
                                         angle:stickerProps.angle
                                         scale:stickerProps.scale];
    }

    IESInfoStickerProps *props = [[IESInfoStickerProps alloc] init];
    [[self editService].sticker setStickerAboveForInfoSticker:stickerId];

    CGSize stickerSize = [[self editService].sticker getInfoStickerSize:stickerId];
    CGFloat aspectRatio = 0.0;
    if (effectModel.isUploadSticker) {
        aspectRatio = MAX(stickerSize.width,stickerSize.height) / kAWEInfoCustomStickerDefaultLength;
        if (aspectRatio > 0) {
            [[self editService].sticker setStickerScale:stickerId scale:1 / aspectRatio];
        }
    }
    if (targetMaxEdgeNumber != nil) {
        aspectRatio = MAX(stickerSize.width, stickerSize.height) / [targetMaxEdgeNumber floatValue];
        if (aspectRatio > 0) {
            [[self editService].sticker setStickerScale:stickerId scale:1 / aspectRatio];
        }
    }
    [[self editService].sticker getStickerId:stickerId props:props];
    [[self editService].sticker setSticker:stickerId startTime:0 duration:kAWEInfoStickerTotalDuration];
    props.startTime = 0;
    props.duration = [self.repository.repoVideoInfo.video totalVideoDuration];
    stickerSize = [[self editService].sticker getstickerEditBoxSize:stickerId];
    stickerSize = CGSizeMake(stickerSize.width / props.scale, stickerSize.height / props.scale);
    ACCInfoStickerContentView *stickerContentView =
    [self configInfoSticker:stickerId
                effectModel:effectModel
            thirdPartyModel:thirdPartyModel
                      props:props
                stickerSize:stickerSize
                configBlock:^(CGSize realStickerSize, ACCInfoStickerConfig *config) {
        if ([effectModel isTypeMagnifier]) {
            CGSize containerSize = [self.stickerContainerView containerView].bounds.size;
            if (realStickerSize.width > 0) {
                config.maximumScale = containerSize.width / realStickerSize.width;
            }
        } else if ([effectModel isDaily]) {
            config.type = ACCInfoStickerTypeDaily;
            config.effectIdentifier = effectModel.effectIdentifier;
        }

        if (constructor) {
            constructor(config, realStickerSize);
        }
    }
           stickerContainer:self.stickerContainerView
               onCompletion:completionBlock];

    stickerContentView.isCustomUploadSticker = effectModel.isUploadSticker;
}

- (void)recoveryOneInfoSticker:(IESInfoSticker *)oneInfoSticker stickerContainer:(nonnull ACCStickerContainerView *)stickerContainer configConstructor:(nullable void (^)(ACCInfoStickerConfig * _Nonnull, CGSize))constructor onCompletion:(nonnull void (^)(void))completion
{
    if (!oneInfoSticker.userinfo) { // avoid cutsame sticker to be recovered
        return;
    }
    BOOL isMagnifierSticker = oneInfoSticker.acc_stickerType == ACCEditEmbeddedStickerTypeMagnifier;
    BOOL isDailySticker = oneInfoSticker.acc_stickerType == ACCEditEmbeddedStickerTypeDaily;
    NSString *effectIdentifier = [oneInfoSticker.userinfo acc_stringValueForKey:ACCEffectIdentifierKey];
    NSNumber *deleteable = [oneInfoSticker.userinfo acc_objectForKey:ACCStickerDeleteableKey];
    NSNumber *groupID = [oneInfoSticker.userinfo acc_objectForKey:kACCStickerGroupIDKey];
    NSNumber *supportedGestureType = [oneInfoSticker.userinfo acc_objectForKey:kACCStickerSupportedGestureTypeKey];
    NSNumber *minimumScale = [oneInfoSticker.userinfo acc_objectForKey:kACCStickerMinimumScaleKey];

    if (oneInfoSticker.userinfo.acc_isBizInfoSticker) {
        IESInfoStickerProps *props = [IESInfoStickerProps new];
        [[self editService].sticker getStickerId:oneInfoSticker.stickerId props:props];

        CGFloat videoDuration = self.repository.repoVideoInfo.video.totalVideoDuration;
        if (props.duration < 0 || props.duration > videoDuration) {
            props.duration = videoDuration;
        }

        if (isnan(props.offsetX)) {
            props.offsetX = 0;
        }
        if (isnan(props.offsetY)) {
            props.offsetY = 0;
        }

        if (props.scale <= CGFLOAT_MIN) {
            props.scale = 1.0;
            
            AWELogToolError2(@"sticker_props_error", AWELogToolTagEdit, @"props.scale == 0, stickerID: %@", oneInfoSticker.userinfo[@"stickerID"]);
            
            [ACCMonitor() trackService:@"sticker_props_error"
                                status:1
                                 extra:@{
                                     @"stickerID": (oneInfoSticker.userinfo[@"stickerID"]? : @"")
                                }];
        }
        
        ACCInfoStickerContentView *contentView =
        [self configInfoSticker:oneInfoSticker.stickerId
                    effectModel:nil
                thirdPartyModel:nil
                          props:props
                    stickerSize:CGSizeZero
                    configBlock:^(CGSize realStickerSize, ACCInfoStickerConfig *config) {
            config.deleteable = deleteable;
            config.groupId = groupID;
            if (supportedGestureType) {
                config.supportedGestureType = supportedGestureType.integerValue;
                config.supportGesture = ^BOOL(ACCStickerGestureType gestureType, id  _Nullable contextId, UIGestureRecognizer * _Nonnull gestureRecognizer) {
                    return supportedGestureType.integerValue & gestureType;
                };
            }
            if (minimumScale) {
                config.minimumScale = minimumScale.floatValue;
            }
            config.timeRangeModel.startTime = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.4f", props.startTime * 1000]];
            config.timeRangeModel.endTime = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.4f", (props.startTime + props.duration) * 1000]];
            if (isMagnifierSticker) {
                CGSize containerSize = [self.stickerContainerView containerView].bounds.size;
                if (realStickerSize.width > 0) {
                    config.maximumScale = containerSize.width / realStickerSize.width;
                }
            } else if (isDailySticker) {
                config.type = ACCInfoStickerTypeDaily;
                config.effectIdentifier = effectIdentifier;
            }
            ACCBLOCK_INVOKE(constructor, config, realStickerSize);
        }
               stickerContainer:stickerContainer onCompletion:completion];
        
        VEStickerPinStatus curStatus = [[self editService].sticker getStickerPinStatus:oneInfoSticker.stickerId];
        if (curStatus == VEStickerPinStatus_Pinned) {
            UIView *stickerWrapper = [self.stickerContainerView stickerViewWithContentView:contentView];
            if ([stickerWrapper isKindOfClass:ACCBaseStickerView.class]) {
                ACCBaseStickerView *baseStickerWrapper = (id)stickerWrapper;
                baseStickerWrapper.foreverHidden = YES;
            }
            stickerWrapper.hidden = YES;
        }
    }
}

- (ACCInfoStickerContentView *)configInfoSticker:(NSInteger)stickerId
                                     effectModel:(IESEffectModel *)effectModel
                                 thirdPartyModel:(nullable IESThirdPartyStickerModel *)thirdPartyModel
                                           props:(IESInfoStickerProps *)props
                                     stickerSize:(CGSize)tmpStickerSize
                                     configBlock:(void(^)(CGSize realStickerSize, ACCInfoStickerConfig *config))configBlock
                                stickerContainer:(ACCStickerContainerView *)stickerContainer
                                    onCompletion:(void (^)(void))completionBlock
{
    if (stickerId < 0) {
        return nil;
    }
    if (![effectModel isAnimatedDateSticker]) {
        [[self editService].sticker setSticker:stickerId startTime:0 duration:kAWEInfoStickerTotalDuration];
    }
    CGSize stickerSize = tmpStickerSize;
    if (CGSizeEqualToSize(stickerSize, CGSizeZero) &&
        props.scale > CGFLOAT_MIN) {
        stickerSize = [[self editService].sticker getstickerEditBoxSize:stickerId];
        stickerSize = CGSizeMake(stickerSize.width / props.scale, stickerSize.height / props.scale);
    }

    ACCInfoStickerConfig *config = [[ACCInfoStickerConfig alloc] init];
    config.typeId = ACCStickerTypeIdInfo;
    config.hierarchyId = @(ACCStickerHierarchyTypeVeryLow);
    if (self.repository.repoQuickStory.isAvatarQuickStory || self.repository.repoVideoInfo.canvasType == ACCVideoCanvasTypeSinglePhoto || self.repository.repoVideoInfo.canvasType == ACCVideoCanvasTypeMusicStory ||
        self.repository.repoVideoInfo.canvasType == ACCVideoCanvasTypeRePostVideo ||
        self.repository.repoVideoInfo.canvasType == ACCVideoCanvasTypeLivePhoto) {
        config.pinable = NO;
    }
    config.timeRangeModel.pts = [NSDecimalNumber decimalNumberWithString:@"-1"];
    config.timeRangeModel.startTime = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.4f", 0.f]];
    config.timeRangeModel.endTime = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.4f", self.player.stickerInitialEndTime]];
    config.minimumScale = (kACCVInfoStickerMinLength / MAX(10, MIN(stickerSize.width, stickerSize.height)));
    config.boxMargin = UIEdgeInsetsMake(10, 10, 10, 10);
    config.boxPadding = UIEdgeInsetsMake(6, 6, 6, 6);
    config.changeAnchorForRotateAndScale = NO;
    config.gestureInvalidFrameValue = self.repository.repoSticker.gestureInvalidFrameValue;
    config.isImageAlbum = self.repository.repoImageAlbumInfo.isImageAlbumEdit;
    
    ACCInfoStickerContentView *contentView = [[ACCInfoStickerContentView alloc] initWithFrame:CGRectMake(0, 0, stickerSize.width, stickerSize.height)];
    @weakify(self, contentView);
    contentView.triggerDragDeleteCallback = ^{
        @strongify(self, contentView);
        [self trackEvent:@"prop_delete" params:@{
            @"enter_method": @"drag",
            @"enter_from" : self.repository.repoTrack.enterFrom ?: @"",
            @"prop_id" : contentView.stickerInfos.userInfo[@"stickerID"] ? : @"",
        }];
    };
    AWEInteractionStickerLocationModel *locationModel = [AWEInteractionStickerLocationModel new];
    locationModel.x = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.4f", props.offsetX]];
    locationModel.y = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.4f", -props.offsetY]];
    locationModel.scale = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.4f", props.scale]];
    locationModel.rotation = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.4f", props.angle]];
    config.geometryModel = [locationModel geometryModel];
    contentView.stickerInfos = props;
    contentView.stickerId = stickerId;
    contentView.config = config;
    contentView.editService = [self editService];

    contentView.didCancledPinCallback = ^(ACCInfoStickerContentView * _Nonnull theView) {
        @strongify(self);
        NSMutableDictionary *params = @{}.mutableCopy;
        params[@"shoot_way"] = self.repository.repoTrack.referString ? : @"";
        params[@"enter_from"] = @"video_edit_page";
        params[@"creation_id"] = self.repository.repoContext.createId ? : @"";
        params[@"content_source"] = self.repository.repoTrack.referExtra[@"content_source"] ? : @"";
        params[@"content_type"] = self.repository.repoTrack.referExtra[@"content_type"] ? : @"";
        params[@"prop_id"] = theView.stickerInfos.userInfo[@"stickerID"]? : @"";
        params[@"is_diy_prop"] = @(theView.isCustomUploadSticker);
        [ACCTracker() trackEvent:@"prop_pin_cancel" params:params needStagingFlag:NO];
    };

    config.gestureCanStartCallback = ^BOOL(__kindof ACCBaseStickerView<ACCGestureResponsibleStickerProtocol> * _Nonnull wrapperView, UIGestureRecognizer * _Nonnull gesture) {
        @strongify(self);
        if (![gesture isKindOfClass:UITapGestureRecognizer.class]) {
            // 临时设置预览为60帧渲染，用于低帧率的视频渲染信息化贴纸出现卡顿的场景
            [[self editService].preview setHighFrameRateRender:YES];

            if ([[wrapperView contentView] conformsToProtocol:@protocol(ACCStickerEditContentProtocol)]) {
                ACCInfoStickerContentView *contentView = (id)[wrapperView contentView];
                [self trackEvent:@"prop_adjust" params:@{
                                                         @"enter_from" : @"video_edit_page",
                                                         @"prop_id" : contentView.stickerInfos.userInfo[@"stickerID"] ? : @"",
                                                         @"enter_method" : @"finger_gesture"
                                                         }];
            }
        }

        return YES;
    };
    config.gestureEndCallback = ^(__kindof ACCBaseStickerView<ACCGestureResponsibleStickerProtocol> * _Nonnull contentView, UIGestureRecognizer * _Nonnull gesture) {
        @strongify(self);
        if (![gesture isKindOfClass:UITapGestureRecognizer.class]) {
            // fix 操作（pinch、pan）贴纸结束，闪屏的问题。
            [[self editService].preview setHighFrameRateRender:NO];
        }
    };
    config.onceTapCallback = ^(__kindof ACCBaseStickerView<ACCGestureResponsibleStickerProtocol> * _Nonnull wrapperView, UITapGestureRecognizer * _Nonnull gesture) {
        @strongify(self, contentView);
        if ([[wrapperView contentView] conformsToProtocol:@protocol(ACCStickerEditContentProtocol)]) {
            UIView<ACCStickerEditContentProtocol> *cmpContent = (id)[wrapperView contentView];
            cmpContent.transparent = NO;
            [self trackEvent:@"prop_more_click" params:@{
                @"enter_from" : @"video_edit_page",
                @"is_diy_prop": @(contentView.isCustomUploadSticker)
            }];
        }
    };
    config.externalHandlePanGestureAction = ^(__kindof UIView<ACCStickerProtocol> * _Nonnull theView, CGPoint point) {
        @strongify(self);
        CGFloat offsetX = [theView.stickerGeometry.x floatValue];
        CGFloat offsetY = -[theView.stickerGeometry.y floatValue];

        ACCInfoStickerContentView *contentView = (id)theView.contentView;
        contentView.transparent = NO;
        contentView.shouldShowAuthor = NO;
        CGFloat stickerAngle = contentView.stickerInfos.angle;
        contentView.stickerInfos.offsetX = offsetX;
        contentView.stickerInfos.offsetY = offsetY;
        [[self editService].sticker setSticker:contentView.stickerId offsetX:offsetX offsetY:offsetY angle:stickerAngle scale:1];
    };
    config.externalHandlePinchGestureeAction = ^(__kindof UIView<ACCStickerProtocol> * _Nonnull theView, CGFloat scale) {
        @strongify(self);
        ACCInfoStickerContentView *contentView = (id)theView.contentView;
        contentView.transparent = NO;
        contentView.shouldShowAuthor = NO;
        [[self editService].sticker setSticker:contentView.stickerId
                                      offsetX:contentView.stickerInfos.offsetX
                                      offsetY:contentView.stickerInfos.offsetY
                                        angle:contentView.stickerInfos.angle
                                        scale:scale];
        IESInfoStickerProps *props = [IESInfoStickerProps new];
        [[self editService].sticker getStickerId:contentView.stickerId props:props];
        contentView.stickerInfos = props;
    };
    config.externalHandleRotationGestureAction = ^(__kindof UIView<ACCStickerProtocol> * _Nonnull theView, CGFloat rotation) {
        @strongify(self);
        ACCInfoStickerContentView *contentView = (id)theView.contentView;
        contentView.transparent = NO;
        contentView.shouldShowAuthor = NO;
        CGFloat stickerAngle = rotation * 180.0 / M_PI;
        [[self editService].sticker setSticker:contentView.stickerId
                                      offsetX:contentView.stickerInfos.offsetX
                                      offsetY:contentView.stickerInfos.offsetY
                                        angle:stickerAngle
                                        scale:1];

        contentView.stickerInfos.angle = rotation * 180.0 / M_PI;
    };
    config.willDeleteCallback = ^{
        @strongify(self, contentView);
        __block NSInteger removeIdx = NSNotFound;
        [self.repository.repoSticker.infoStickerArray enumerateObjectsUsingBlock:^(AWEInfoStickerInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *stickerID = ACCDynamicCast(contentView.stickerInfos.userInfo[@"stickerID"], NSString);
            if (stickerID &&
                [obj.stickerID isEqualToString:stickerID]) {
                removeIdx = idx;
                *stop = YES;
            }
        }];
        if (removeIdx != NSNotFound) {
            [self.repository.repoSticker.infoStickerArray removeObjectAtIndex:removeIdx];
            [[NSNotificationCenter defaultCenter] postNotificationName:ACCVideoChallengeChangeKey object:nil];
        }
        
        [[self editService].sticker removeInfoSticker:contentView.stickerId];
    };

    UIView<ACCStickerProtocol> __block __weak *wrapperView = nil;
    config.selectTime = ^{
        @strongify(self, contentView);
        [self trackEvent:@"prop_time_set" params:@{
                                                   @"enter_from" : @"video_edit_page",
                                                   @"prop_id" : contentView.stickerInfos.userInfo[@"stickerID"] ? : @"",
                                                   @"enter_method" : @"click",
                                                   @"is_diy_prop" : @(contentView.isCustomUploadSticker)
                                                   }];

        [[self editService].preview pause];
        [self modernEditStickerDuration:wrapperView];
    };
    config.pinAction = ^{
        @strongify(self, contentView);
        NSMutableDictionary *params = @{}.mutableCopy;
        params[@"shoot_way"] = self.repository.repoTrack.referString ? : @"";
        params[@"enter_from"] = @"video_edit_page";
        params[@"creation_id"] = self.repository.repoContext.createId ? : @"";
        params[@"content_source"] = self.repository.repoTrack.referExtra[@"content_source"] ? : @"";
        params[@"content_type"] = self.repository.repoTrack.referExtra[@"content_type"] ? : @"";
        params[@"prop_id"] = contentView.stickerInfos.userInfo[@"stickerID"] ? : @"";
        params[@"is_diy_prop"] = @(contentView.isCustomUploadSticker);
        [ACCTracker() trackEvent:@"prop_pin" params:params needStagingFlag:NO];

        [[self editService].preview pause];
        [self jumpToPinStickerViewControllerWithSticker:contentView];
    };
    config.didChangedTimeRange = ^(__kindof ACCBaseStickerView * _Nonnull stickerView) {
        @strongify(self);
        ACCInfoStickerContentView *contentView = (id)stickerView.contentView;
        if (![effectModel isAnimatedDateSticker] || stickerView.realDuration != 0) {
            CGFloat startTime = stickerView.realStartTime;
            CGFloat duration = stickerView.realDuration;
            [[self editService].sticker setSticker:contentView.stickerId startTime:startTime duration:duration];
        }
        IESInfoStickerProps *props = [IESInfoStickerProps new];
        [[self editService].sticker getStickerId:contentView.stickerId props:props];
        contentView.stickerInfos.startTime = props.startTime;
        contentView.stickerInfos.duration = props.duration;
    };
    
    @weakify(stickerContainer);

    if (ACCConfigBool(ACCConfigBOOL_allow_sticker_delete) || self.repository.repoImageAlbumInfo.isImageAlbumEdit) {
        config.deleteAction = ^{
            @strongify(stickerContainer, contentView, self);
            [self trackEvent:@"prop_delete" params:@{
                @"enter_method": @"click",
                @"enter_from" : self.repository.repoTrack.enterFrom ?: @"",
                @"prop_id" : contentView.stickerInfos.userInfo[@"stickerID"] ? : @"",
            }];
            [stickerContainer removeStickerView:wrapperView];
        };
    }
    
    if (configBlock) {
        configBlock(stickerSize, config);
    }
    
    wrapperView = [stickerContainer addStickerView:contentView config:config];
    wrapperView.stickerGeometry.preferredRatio = NO;
    
    NSDictionary *extraDict = [thirdPartyModel.extra acc_jsonDictionary];
    NSString *authorName = [extraDict acc_stringValueForKey:@"author_name"];
    if (authorName.length > 0) {
        contentView.hintView = wrapperView.selectedHintView;
        contentView.authorName = authorName;
        contentView.shouldShowAuthor = YES;
    }

    if (completionBlock) {
        completionBlock();
    }
    
    return contentView;
}

- (void)recoveryInfoStickersPinStatus:(ACCStickerContainerView *)stickerContainer originPinStatus:(NSDictionary<NSNumber *, NSNumber *> *)originPinStatus
{
    [[stickerContainer stickerViewsWithTypeId:ACCStickerTypeIdInfo] enumerateObjectsUsingBlock:^(ACCStickerViewType  _Nonnull stickerWrapper, NSUInteger idx, BOOL * _Nonnull stop) {
        ACCInfoStickerContentView *infoContentView = (id)stickerWrapper.contentView;
        VEStickerPinStatus curStatus = [[self editService].sticker getStickerPinStatus:infoContentView.stickerId];
        VEStickerPinStatus originStatus = [originPinStatus[@(infoContentView.stickerId)] integerValue];

        if (curStatus != originStatus) {
            IESInfoStickerProps *props = [IESInfoStickerProps new];
            [[self editService].sticker getStickerId:infoContentView.stickerId props:props];

            ACCStickerGeometryModel *geoModel = stickerWrapper.stickerGeometry;
            geoModel.x = [[NSDecimalNumber alloc] initWithFloat:props.offsetX];
            geoModel.y = [[NSDecimalNumber alloc] initWithFloat:-props.offsetY];
            geoModel.rotation = [[NSDecimalNumber alloc] initWithFloat:props.angle];
            geoModel.scale = [[NSDecimalNumber alloc] initWithFloat:props.scale];

            [stickerWrapper recoverWithGeometryModel:geoModel];
        }
    }];
}

#pragma mark - Hint logic

- (void)modernEditStickerDuration:(UIView<ACCStickerProtocol> *)stickerView
{
    [[self selectTimeManager] modernEditStickerDuration:stickerView];
}

#pragma mark - Tracker

- (void)trackEvent:(NSString *)event params:(NSDictionary *)params
{
    if (self.repository.repoContext.recordSourceFrom == AWERecordSourceFromIM ||
        self.repository.repoContext.recordSourceFrom == AWERecordSourceFromIMGreet) {
        return;
    }
    NSMutableDictionary *dict = [self.repository.repoTrack.referExtra mutableCopy];
    [dict addEntriesFromDictionary:params];
    [ACCTracker() trackEvent:event params:dict needStagingFlag:NO];
}

- (BOOL)canRecoverSticker:(ACCRecoverStickerModel *)sticker
{
    return sticker.infoSticker.acc_isBizInfoSticker;
}

- (void)recoverSticker:(ACCRecoverStickerModel *)sticker
{
    !self.recoveryInfoSticker ?: self.recoveryInfoSticker(sticker.infoSticker);
}

- (void)addInteractionStickerInfoToArray:(nonnull NSMutableArray *)interactionStickers idx:(NSInteger)stickerIndex
{

}

- (ACCEditStickerSelectTimeManager *)selectTimeManager
{
    if (!_selectTimeManager) {
        _selectTimeManager = [[ACCEditStickerSelectTimeManager alloc] initWithEditService:self.editService repository:self.repository player:self.player stickerContainer:self.stickerContainerView transitionService:self.transitionService];
    }
    return _selectTimeManager;
}

- (void)jumpToPinStickerViewControllerWithSticker:(ACCInfoStickerContentView *)stickerView
{
    //input data
    ACCModernPinStickerViewControllerInputData *inputData = [ACCModernPinStickerViewControllerInputData new];
    inputData.repository = self.repository;
    inputData.editService = [self editService];
    inputData.startTime = stickerView.stickerInfos.startTime;
    inputData.duration = MIN(self.repository.repoVideoInfo.video.totalVideoDuration,
                             MAX(stickerView.stickerInfos.duration, 0.0));
    inputData.stickerId = stickerView.stickerId;
    inputData.playerRect = [self editService].mediaContainerView.frame;
    inputData.currTime = [self editService].preview.currentPlayerTime;
    inputData.stickerInfos = stickerView.stickerInfos;
    inputData.isCustomUploadSticker = stickerView.isCustomUploadSticker;

    @weakify(self);
    ACCStickerContainerView *stickerContainer = [self.stickerContainerView
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
        [stickerContainerView configWithPlayerFrame:self.stickerContainerView.frame allowMask:NO];
    } enumerateStickerUsingBlock:^(__kindof ACCBaseStickerView * _Nonnull stickerView, NSUInteger idx, ACCStickerGeometryModel * _Nonnull geometryModel, ACCStickerTimeRangeModel * _Nonnull timeRangeModel) {
        stickerView.config.showSelectedHint = NO;
        stickerView.config.secondTapCallback = NULL;
        geometryModel.preferredRatio = NO;
        stickerView.stickerGeometry.preferredRatio = NO;
    }];
    [stickerContainer setShouldHandleGesture:YES];
    [self configStickerContainerForPinVc:stickerContainer];
    NSMutableDictionary *copyDict = [[NSMutableDictionary alloc] init];
    [[stickerContainer stickerViewsWithTypeId:ACCStickerTypeIdInfo] enumerateObjectsUsingBlock:^(ACCStickerViewType  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.contentView isKindOfClass:ACCInfoStickerContentView.class]) {
            ACCInfoStickerContentView *infoContentView = (id)obj.contentView;
            copyDict[@(infoContentView.stickerId)] = infoContentView;
        }
        obj.config.onceTapCallback = nil;
    }];

    inputData.stickerContainerView = stickerContainer;
    inputData.transitionService = self.transitionService;

    //create pin vc
    NSDictionary *bachupStatus = [[self selectTimeManager] backupStickerInfosPinStatus];
    [inputData setWillDismissBlock:^(BOOL save) {
        @strongify(self);

        if (save) {
            [self applyStickerInfosChange:copyDict];
        } else {
            [[self selectTimeManager] recoveryInfoStickerChanges:stickerContainer originPinStatus:bachupStatus];
        }
        
        [self.repository.repoVideoInfo.video.infoStickers enumerateObjectsUsingBlock:^(IESInfoSticker * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.isSrtInfoSticker) {
                [[self editService].sticker setSticker:obj.stickerId alpha:1.0];
            }
        }];
    }];
    
    @weakify(stickerContainer);
    [inputData setDidFailedBlock:^{
        @strongify(self);
        @strongify(stickerContainer);
        NSInteger __block findStickerId = NSNotFound;
        [[stickerContainer stickerViewsWithTypeId:ACCStickerTypeIdInfo] enumerateObjectsUsingBlock:^(ACCStickerViewType  _Nonnull stickerWrapper, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([stickerWrapper.contentView isKindOfClass:ACCInfoStickerContentView.class]) {
                ACCInfoStickerContentView *infoContentView = (id)stickerWrapper.contentView;
                if (infoContentView.isTransparent == NO) {
                    findStickerId = infoContentView.stickerId;
                    *stop = YES;
                }
            }
        }];

        if (findStickerId != NSNotFound) {
            [[self.stickerContainerView stickerViewsWithTypeId:ACCStickerTypeIdInfo] enumerateObjectsUsingBlock:^(ACCStickerViewType  _Nonnull stickerWrapper, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([stickerWrapper.contentView isKindOfClass:ACCInfoStickerContentView.class]) {
                    ACCInfoStickerContentView *infoContentView = (id)stickerWrapper.contentView;
                    if (infoContentView.stickerId == findStickerId) {
                        stickerWrapper.hidden = NO;
                        if ([stickerWrapper isKindOfClass:ACCBaseStickerView.class]) {
                            ACCBaseStickerView *baseStickerWrapper = (id)stickerWrapper;
                            baseStickerWrapper.foreverHidden = NO;
                        }

                        IESInfoStickerProps *props = [IESInfoStickerProps new];
                        [[self editService].sticker getStickerId:infoContentView.stickerId props:props];

                        ACCStickerGeometryModel *geoModel = [stickerWrapper.stickerGeometry copy];
                        geoModel.x = [[NSDecimalNumber alloc] initWithFloat:props.offsetX];
                        geoModel.y = [[NSDecimalNumber alloc] initWithFloat:-props.offsetY];
                        geoModel.rotation = [[NSDecimalNumber alloc] initWithFloat:props.angle];
                        geoModel.scale = [[NSDecimalNumber alloc] initWithFloat:props.scale];

                        [stickerWrapper recoverWithGeometryModel:geoModel];
                        infoContentView.stickerInfos = props;

                        [[self editService].sticker setSticker:infoContentView.stickerId
                                                          offsetX:infoContentView.stickerInfos.offsetX
                                                          offsetY:infoContentView.stickerInfos.offsetY
                                                            angle:infoContentView.stickerInfos.angle
                                                            scale:1.0];
                        [[self editService].sticker setStickerScale:infoContentView.stickerId scale:infoContentView.stickerInfos.scale];
                        [[self editService].sticker setSticker:infoContentView.stickerId
                                                    startTime:infoContentView.stickerInfos.startTime
                                                     duration:infoContentView.stickerInfos.duration];

                        *stop = YES;
                    }
                }
            }];
        }
    }];
    ACCModernPinStickerViewController *pinStickerController = [[ACCModernPinStickerViewController alloc] initWithInputData:inputData];

    //show vc
    [self.transitionService presentViewController:pinStickerController completion:nil];
}

- (void)configStickerContainerForPinVc:(UIView<ACCStickerContainerProtocol> *)stickerContainer
{
    @weakify(self, stickerContainer);
    [stickerContainer.allStickerViews enumerateObjectsUsingBlock:^(ACCStickerViewType  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.config.typeId isEqualToString:ACCStickerTypeIdInfo]) {
            obj.config.onceTapCallback = ^(__kindof ACCBaseStickerView<ACCGestureResponsibleStickerProtocol> * _Nonnull wrapperView, UITapGestureRecognizer * _Nonnull gesture) {
                @strongify(self, stickerContainer);
                [self highlightSticker:[wrapperView contentView] allStickers:stickerContainer.allStickerViews];
            };
        } else {
            obj.config.supportGesture = ^BOOL(ACCStickerGestureType gestureType, id _Nullable contextId, UIGestureRecognizer *gestureRecognizer) {
                return NO;
            };
        }
    }];
}

- (void)applyStickerInfosChange:(NSDictionary<NSNumber *, ACCInfoStickerContentView *> *)copyStickerViews
{
    [[self.stickerContainerView stickerViewsWithTypeId:ACCStickerTypeIdInfo] enumerateObjectsUsingBlock:^(ACCStickerViewType  _Nonnull stickerWrapper, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([stickerWrapper.contentView isKindOfClass:ACCInfoStickerContentView.class]) {
            ACCInfoStickerContentView *infoContentView = (id)stickerWrapper.contentView;
            ACCInfoStickerContentView *cmpView = copyStickerViews[@(infoContentView.stickerId)];

            if (cmpView.isTransparent == NO) {
                stickerWrapper.hidden = YES;
                if ([stickerWrapper isKindOfClass:ACCBaseStickerView.class]) {
                    [(ACCBaseStickerView *)stickerWrapper setForeverHidden:YES];
                }
            } else {
                infoContentView.transparent = NO;

                IESInfoStickerProps *props = [IESInfoStickerProps new];
                [[self editService].sticker getStickerId:infoContentView.stickerId props:props];

                ACCStickerGeometryModel *geoModel = [stickerWrapper.stickerGeometry copy];
                geoModel.x = [[NSDecimalNumber alloc] initWithFloat:props.offsetX];
                geoModel.y = [[NSDecimalNumber alloc] initWithFloat:-props.offsetY];
                geoModel.rotation = [[NSDecimalNumber alloc] initWithFloat:props.angle];
                geoModel.scale = [[NSDecimalNumber alloc] initWithFloat:props.scale];

                [stickerWrapper recoverWithGeometryModel:geoModel];
                infoContentView.stickerInfos = props;

                VEStickerPinStatus curStatus = [[self editService].sticker getStickerPinStatus:infoContentView.stickerId];
                if (curStatus == VEStickerPinStatus_None) {
                    stickerWrapper.hidden = NO;
                    if ([stickerWrapper isKindOfClass:ACCBaseStickerView.class]) {
                        ACCBaseStickerView *baseStickerWrapper = (id)stickerWrapper;
                        baseStickerWrapper.foreverHidden = NO;
                    }
                }
            }
        }
    }];

    NSArray<ACCStickerTypeId> *typeIds = [[ACCStickerGroup commonInfoStickerIds] mtl_arrayByRemovingObject:ACCStickerTypeIdInfo];
    [typeIds enumerateObjectsUsingBlock:^(ACCStickerTypeId _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [[self.stickerContainerView stickerViewsWithTypeId:obj] enumerateObjectsUsingBlock:^(ACCStickerViewType  _Nonnull stickerWrapper, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([stickerWrapper.contentView conformsToProtocol:@protocol(ACCStickerEditContentProtocol)]) {
                UIView<ACCStickerEditContentProtocol> *contentView = (id)stickerWrapper.contentView;
                contentView.transparent = NO;
            }
        }];
    }];
}

- (void)highlightSticker:(UIView *)sticker allStickers:(NSArray<ACCStickerViewType> *)allStickers
{
    [allStickers enumerateObjectsUsingBlock:^(ACCStickerViewType  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.contentView conformsToProtocol:@protocol(ACCStickerEditContentProtocol)]) {
            UIView<ACCStickerEditContentProtocol> *cmpContent = (id)(obj.contentView);
            cmpContent.transparent = (sticker != cmpContent);
        }
    }];
    
    [self.repository.repoVideoInfo.video.infoStickers enumerateObjectsUsingBlock:^(IESInfoSticker * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.isSrtInfoSticker) {
            [[self editService].sticker setSticker:obj.stickerId alpha:0.34];
        }
    }];
}

- (void)updateSticker:(NSInteger)stickerId withNewId:(NSInteger)newId {
    ACCInfoStickerContentView *infoSticker = (id)[[self.stickerContainerView stickerViewsWithTypeId:ACCStickerTypeIdInfo] acc_match:^BOOL(ACCStickerViewType  _Nonnull item) {
        if ([item.contentView isKindOfClass:ACCInfoStickerContentView.class]) {
            ACCInfoStickerContentView *infoSticker = (id)item.contentView;
            return infoSticker.stickerId == stickerId;
        }
        return NO;
    }].contentView;
    infoSticker.stickerInfos.stickerId = infoSticker.stickerId = newId;
}

#pragma mark - Private Methods

+ (ACCCrossPlatformStickerType)infoStickerTypeFor:(NSDictionary *)userInfo
{
    if (userInfo == nil) {
        return ACCCrossPlatformStickerTypeInfo;
    }
    if (userInfo.acc_stickerType == ACCEditEmbeddedStickerTypeMagnifier) {
        return ACCCrossPlatformStickerTypeMagnifier;
    }
    if (userInfo.acc_stickerType == ACCEditEmbeddedStickerTypeDaily) {
        return ACCCrossPlatformStickerTypeDaily;
    }
    if (userInfo.acc_stickerType == ACCEditEmbeddedStickerTypeCustom) {
        return ACCCrossPlatformStickerTypeCustom;
    }
    if (userInfo.acc_stickerType == ACCEditEmbeddedStickerTypeWish) {
        return ACCCrossPlatformStickerTypeWish;
    }
    
    return ACCCrossPlatformStickerTypeInfo;
}

#pragma mark - ACCStickerMigrationProtocol

+ (BOOL)fillCrossPlatformStickerByUserInfo:(NSDictionary *)userInfo repository:(id<ACCPublishRepository>)sessionModel context:(id<ACCCrossPlatformMigrateContext>)context sticker:(NLESegmentSticker_OC *__autoreleasing *)sticker
{
    if (userInfo.acc_isBizInfoSticker) {
        ACCCrossPlatformStickerType stickerType = [self infoStickerTypeFor:userInfo];

        NLESegmentSticker_OC *sticker_;
        if (stickerType == ACCCrossPlatformStickerTypeCustom) {
            sticker_ = [[NLESegmentImageSticker_OC alloc] init];
        } else {
            sticker_ = [[NLESegmentInfoSticker_OC alloc] init];
        }
        sticker_.stickerType = stickerType;
        if (sticker_ == nil) {
            return YES;
        }
        
        sticker_.extraDict = [NSMutableDictionary dictionary];
        sticker_.extraDict[@"tab_id"] = userInfo[@"tabName"];
        sticker_.extraDict[ACCCrossPlatformiOSResourcePathKey] = context.resourcePath;
        sticker_.extraDict[ACCStickerDeleteableKey] = userInfo[ACCStickerDeleteableKey];
        sticker_.extraDict[ACCStickerEditableKey] = userInfo[ACCStickerEditableKey];
        sticker_.extraDict[kACCStickerGroupIDKey] = userInfo[kACCStickerGroupIDKey];
        sticker_.extraDict[kACCStickerSupportedGestureTypeKey] = userInfo[kACCStickerSupportedGestureTypeKey];
        sticker_.extraDict[kACCStickerMinimumScaleKey] = userInfo[kACCStickerMinimumScaleKey];


        // custom sticker
        if (sticker_.stickerType == ACCCrossPlatformStickerTypeCustom) {
            NLESegmentImageSticker_OC *imageSticker = (NLESegmentImageSticker_OC *)sticker_;
            imageSticker.imageFile = [[NLEResourceNode_OC alloc] init];
            imageSticker.imageFile.resourceType = NLEResourceTypeImageSticker;
            imageSticker.imageFile.resourceFile = context.resourcePath;

            sticker_.extraDict[@"remove_background"] = userInfo[@"useRemoveBg"];
            sticker_.extraDict[@"sticker_id"] = [userInfo acc_stringValueForKey:kACCStickerIDKey];
        } else {
            NLESegmentInfoSticker_OC *infoSticker = (NLESegmentInfoSticker_OC *)sticker_;
            infoSticker.effectSDKFile = [[NLEResourceNode_OC alloc] init];
            infoSticker.effectSDKFile.resourceId = [userInfo acc_stringValueForKey:kACCStickerIDKey];
            infoSticker.effectSDKFile.resourceType = NLEResourceTypeInfoSticker;
            
            // daily sitcker
            if (sticker_.stickerType == ACCCrossPlatformStickerTypeDaily) {
                ACCRepoStickerModel *stickerModel = [sessionModel extensionModelOfClass:[ACCRepoStickerModel class]];
                AWEInteractionStickerModel *interactionStickerModel = [stickerModel.interactionStickers acc_match:^BOOL(AWEInteractionStickerModel * _Nonnull item) {
                    BOOL isDailyType = item.trackInfo && item.type == AWEInteractionStickerTypeDaily;
                    if (!isDailyType) {
                        return NO;
                    }
                    NSDictionary *attrDic = nil;
                    if (!ACC_isEmptyString(item.attr)) {
                        NSData *data = [item.attr dataUsingEncoding:NSUTF8StringEncoding];
                        NSError *error = nil;
                        attrDic = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
                        if (error != nil) {
                            AWELogToolError2(@"InfoSticker", AWELogToolTagDraft, @"Interaction Sticker Model Attr Data Convert To Json Error: %@", error);
                        }
                    }
                    BOOL isSameID = [infoSticker.effectSDKFile.resourceId isEqualToString:[attrDic acc_stringValueForKey:@"daily_sticker_id"]];
                    return isSameID;
                }];
                
                if (interactionStickerModel) {
                    NSError *error = nil;
                    sticker_.extraDict[ACCInteractionStickerTransferKey] = [MTLJSONAdapter JSONDictionaryFromModel:interactionStickerModel error:&error];
                    if (error != nil) {
                        AWELogToolError2(@"InfoSticker", AWELogToolTagDraft, @"Interaction Sticker Model Attr Data Convert To Json Error: %@", error);
                    }
                }
            }
        }
        *sticker = sticker_;

        return YES;
    }
    return NO;
}

+ (void)updateUserInfo:(NSDictionary *__autoreleasing *)userInfo repoModel:(id<ACCPublishRepository>)sessionModel byCrossPlatformSlot:(nonnull NLETrackSlot_OC *)slot
{
    if (slot.sticker.stickerType == ACCCrossPlatformStickerTypeInfo
        || slot.sticker.stickerType == ACCCrossPlatformStickerTypeMagnifier
        || slot.sticker.stickerType == ACCCrossPlatformStickerTypeDaily
        || slot.sticker.stickerType == ACCCrossPlatformStickerTypeCustom) {
        NLESegmentSticker_OC *sticker = slot.sticker;
        NSMutableDictionary *temp_userInfo = [NSMutableDictionary dictionary];
        temp_userInfo[@"tabName"] = sticker.extraDict[@"tab_id"];
        temp_userInfo[kACCStickerUUIDKey] = [NSUUID UUID].UUIDString ?: @"";
        temp_userInfo[ACCStickerDeleteableKey] = [sticker.extraDict acc_objectForKey:ACCStickerDeleteableKey];
        temp_userInfo[ACCStickerEditableKey] = [sticker.extraDict acc_objectForKey:ACCStickerEditableKey];
        temp_userInfo[kACCStickerGroupIDKey] = sticker.extraDict[kACCStickerGroupIDKey];
        temp_userInfo[kACCStickerSupportedGestureTypeKey] = sticker.extraDict[kACCStickerSupportedGestureTypeKey];
        temp_userInfo[kACCStickerMinimumScaleKey] = sticker.extraDict[kACCStickerMinimumScaleKey];

        // custom sticker
        if (sticker.stickerType == ACCCrossPlatformStickerTypeCustom) {
            NLESegmentImageSticker_OC *imageSticker = (NLESegmentImageSticker_OC *)sticker;
            temp_userInfo.acc_stickerType = ACCEditEmbeddedStickerTypeCustom;
            temp_userInfo[@"customStickerFilePath"] = imageSticker.imageFile.resourceFile ?: @"";
            temp_userInfo[@"useRemoveBg"] = sticker.extraDict[@"remove_background"];
            temp_userInfo[kACCStickerIDKey] = sticker.extraDict[@"sticker_id"];
        } else {
            if (![sticker isKindOfClass:NLESegmentInfoSticker_OC.class]) {
                return;
            }
            NLESegmentInfoSticker_OC *infoSticker = (NLESegmentInfoSticker_OC *)sticker;
            temp_userInfo[kACCStickerIDKey] = infoSticker.effectSDKFile.resourceId ?: @"";
            // magnifier sticker
            if (sticker.stickerType == ACCCrossPlatformStickerTypeMagnifier) {
                temp_userInfo.acc_stickerType = ACCEditEmbeddedStickerTypeMagnifier;
            }
            
            // daily sticker
            if (sticker.stickerType == ACCCrossPlatformStickerTypeDaily) {
                temp_userInfo.acc_stickerType = ACCEditEmbeddedStickerTypeDaily;
                temp_userInfo[ACCEffectIdentifierKey] = temp_userInfo[kACCStickerIDKey];
                
                NSError *error = nil;
                AWEInteractionStickerModel *interactionStickerModel = [MTLJSONAdapter modelOfClass:[AWEInteractionStickerModel class] fromJSONDictionary:[sticker.extraDict acc_dictionaryValueForKey:ACCInteractionStickerTransferKey] error:&error];
                if (interactionStickerModel == nil) {
                    if (error != nil) {
                        AWELogToolError2(@"InfoSticker", AWELogToolTagDraft, @"Interaction Sticker Json Convert To Model Error: %@", error);
                    }
                    return;
                }
                
                ACCRepoStickerModel *repoStickerModel = [sessionModel extensionModelOfClass:[ACCRepoStickerModel class]];
                NSMutableArray *interactionStickers = [NSMutableArray array];
                [interactionStickers addObject:interactionStickerModel];
                if (!ACC_isEmptyArray(repoStickerModel.interactionStickers)) {
                    [interactionStickers addObjectsFromArray:repoStickerModel.interactionStickers];
                }
                repoStickerModel.interactionStickers = interactionStickers;
            }
        }
        
        // resource path
        temp_userInfo[ACCCrossPlatformiOSResourcePathKey] = sticker.extraDict[ACCCrossPlatformiOSResourcePathKey];
        *userInfo = temp_userInfo;
    }
}

- (BOOL)canRecoverImageAlbumStickerModel:(ACCImageAlbumStickerRecoverModel *)sticker
{
    if (self.recoveryImageAlbumSticker && sticker.infoSticker) {
        return sticker.infoSticker.userInfo.acc_isBizInfoSticker;
    }
    
    return NO;
}

- (void)recoverStickerForContainer:(ACCStickerContainerView *)containerView imageAlbumStickerModel:(ACCImageAlbumStickerRecoverModel *)sticker
{
    if (self.recoveryImageAlbumSticker && sticker.infoSticker) {
        self.recoveryImageAlbumSticker(containerView, sticker.infoSticker);
    }
}

@end
