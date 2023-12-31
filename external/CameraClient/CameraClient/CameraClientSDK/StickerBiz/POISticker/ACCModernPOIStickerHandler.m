//
//  ACCModernPOIStickerHandler.m
//  CameraClient-Pods-Aweme
//
//  Created by 卜旭阳 on 2020/9/22.
//

#import "ACCModernPOIStickerHandler.h"
#import "ACCModernPOIStickerView.h"
#import "ACCModernPOIStickerSwitchView.h"
#import "ACCPOIStickerModel.h"
#import "ACCModernPOIStickerConfig.h"
#import <CreationKitArch/AWEInteractionStickerLocationModel+ACCSticker.h>
#import "AWEEditStickerHintView.h"
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreationKitArch/ACCEditAndPublishConstants.h>
#import <CreationKitArch/AWEDraftUtils.h>
#import "ACCModernPOIStickerDataHelperProtocol.h"
#import "ACCStickerBizDefines.h"

#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <EffectPlatformSDK/EffectPlatform+Additions.h>
#import "AWERepoVideoInfoModel.h"
#import <CreationKitArch/ACCRepoDraftModel.h>
#import <NLEPlatform/NLESegmentInfoSticker+iOS.h>
#import "NLESegmentSticker_OC+ACCAdditions.h"
#import "NLETrackSlot_OC+ACCAdditions.h"
#import "AWERepoStickerModel.h"

#import <CreationKitInfra/ACCLoadingViewProtocol.h>
#import <CreationKitInfra/ACCLogHelper.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import "AWEInteractionPOIStickerModel.h"
#import <CreativeKit/ACCMonitorProtocol.h>
#import <CameraClient/ACCDraftProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/ACCToastProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CameraClient/ACCConfigKeyDefines.h>
#import "IESInfoSticker+ACCAdditions.h"
#import <CameraClientModel/ACCCrossPlatformStickerType.h>

@interface ACCModernPOIStickerHandler ()<ACCModernPOIStickerSwitchViewDelegate, ACCModernPOIStickerViewHelperProtocol>

@property (nonatomic, strong) AWEEditStickerHintView *poiHintView;

@property (nonatomic, strong) ACCModernPOIStickerSwitchView *editView;

@property (nonatomic, weak) UIView<ACCTextLoadingViewProtcol> *loadingView;

@property (nonatomic, copy) NSString *currentPOIID;

@property (nonatomic, copy) NSString *currentLoadingTag;

@end

@implementation ACCModernPOIStickerHandler

+ (BOOL)useModernPOIStickerStyle:(NSArray<AWEInteractionStickerModel *> *)interactionStickers
{
    AWEInteractionPOIStickerModel *model = (AWEInteractionPOIStickerModel *)[interactionStickers acc_match:^BOOL(AWEInteractionStickerModel * _Nonnull item) {
        return [item isKindOfClass:[AWEInteractionPOIStickerModel class]];
    }];
    if (model) {
        return (model.poiStyleInfo != nil);
    }
    return ACCConfigInt(kConfigInt_multi_poi_sticker_style) > 0;
}

- (BOOL)canHandleSticker:(UIView<ACCStickerProtocol> *)sticker
{
    return [sticker.contentView isKindOfClass:[ACCModernPOIStickerView class]];
}

- (BOOL)canRecoverSticker:(ACCRecoverStickerModel *)sticker
{
    return sticker.infoSticker.acc_stickerType == ACCEditEmbeddedStickerTypeModrenPOI;
}

- (BOOL)enableMultiStyleSwitch
{
    return (ACCConfigInt(kConfigInt_multi_poi_sticker_style) > 1);
}

#pragma mark -

- (BOOL)canExpressSticker:(ACCEditorStickerConfig *)stickerConfig
{
    return [stickerConfig isKindOfClass:[ACCEditorPOIStickerConfig class]];
}

- (void)expressSticker:(ACCEditorStickerConfig *)stickerConfig
{
    [self expressSticker:stickerConfig withCompletion:^{
        
    }];
}

- (void)expressSticker:(ACCEditorStickerConfig *)stickerConfig withCompletion:(void (^)(void))completionHandler
{
    if ([self canExpressSticker:stickerConfig]) {
        ACCEditorPOIStickerConfig *poiStickerConfig = (ACCEditorPOIStickerConfig *)stickerConfig;
        AWEInteractionStickerLocationModel *locationModel = [stickerConfig locationModel];
        locationModel.startTime = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.4f", 0.f]];
        locationModel.endTime = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.4f", self.player.stickerInitialEndTime]];
        ACCPOIStickerModel *POIModel = [poiStickerConfig POIModel];
        // @Buxuyang 这里给我重构掉
        NSDictionary *attr = @{@"poi_sticker_id" : POIModel.effectIdentifier ?: @""};
        NSError *error = nil;
        NSData *data = [NSJSONSerialization dataWithJSONObject:attr options:kNilOptions error:&error];
        if (error) {
            AWELogToolError(AWELogToolTagEdit, @"[addPOIStickerWithPOIModel] -- error:%@", error);
        }
        NSString *attrStr = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
        POIModel.interactionStickerInfo.attr = attrStr;
        POIModel.interactionStickerInfo.poiInfo = @{@"poi_id" : POIModel.poiID ?: @"", @"poi_name" : POIModel.poiName ?: @""};
        POIModel.interactionStickerInfo.type = AWEInteractionStickerTypePOI;
        POIModel.interactionStickerInfo.stickerID = POIModel.effectIdentifier;

        [self addPOIStickerWithPOIModel:POIModel
                          locationModel:locationModel
                         recoverSticker:nil
                    userInfoConstructor:^(NSMutableDictionary *userInfo) {
            userInfo[ACCStickerDeleteableKey] = @(stickerConfig.deleteable);
        }
                       constructorBlock:^(ACCModernPOIStickerConfig *config) {
            config.deleteable = @(stickerConfig.deleteable);
        }];
    }
}

- (void)updateSticker:(NSInteger)stickerId withNewId:(NSInteger)newId {
    ACCModernPOIStickerView *poiSticker = (id)[[self.stickerContainerView stickerViewsWithTypeId:ACCStickerTypeIdModernPOI] acc_match:^BOOL(ACCStickerViewType  _Nonnull item) {
        if ([item.contentView isKindOfClass:ACCModernPOIStickerView.class]) {
            ACCModernPOIStickerView *poiSticker = (id)item.contentView;
            return poiSticker.stickerId == stickerId;
        }
        return NO;
    }].contentView;
    poiSticker.stickerId = newId;
}

# pragma mark - Data process
- (void)recoverSticker:(ACCRecoverStickerModel *)sticker
{
    if ([self canRecoverSticker:sticker]) {
        AWEInteractionPOIStickerModel *poiStickerModel = (AWEInteractionPOIStickerModel *)[self.dataProvider.interactionStickers acc_match:^BOOL(AWEInteractionStickerModel * _Nonnull item) {
            return item.trackInfo && (item.type == AWEInteractionStickerTypePOI);
        }];
        if (poiStickerModel) {
            NSNumber *deleteable = [sticker.infoSticker.userinfo acc_objectForKey:ACCStickerDeleteableKey];
            [self addPOIStickerWithPOIModel:[self poiModelWithInteractionModel:poiStickerModel] locationModel:[self adaptedLocationWithInteractionInfo:[self poiModelWithInteractionModel:poiStickerModel].interactionStickerInfo] recoverSticker:sticker.infoSticker userInfoConstructor:nil constructorBlock:^(ACCModernPOIStickerConfig *config) {
                config.deleteable = deleteable;
            }];
        }
    }
}

- (void)addInteractionStickerInfoToArray:(NSMutableArray *)interactionStickers idx:(NSInteger)stickerIndex
{
    for (UIView<ACCStickerProtocol> *sticker in [[self.stickerContainerView stickerViewsWithTypeId:ACCStickerTypeIdModernPOI] acc_filter:^BOOL(ACCStickerViewType  _Nonnull item) {
        return [item.contentView isKindOfClass:[ACCModernPOIStickerView class]];
    }]) {
        [self addPOIInteractionStickerInfo:sticker toArray:interactionStickers idx:stickerIndex];
    }
}

- (void)addPOIInteractionStickerInfo:(UIView<ACCStickerProtocol> *)stickerView toArray:(NSMutableArray *)interactionStickers idx:(NSInteger)stickerIndex
{
    ACCModernPOIStickerView *poiSticker = (ACCModernPOIStickerView *)(stickerView.contentView);
    AWEInteractionStickerModel *interactionStickerInfo = poiSticker.model.interactionStickerInfo;
    CGPoint point = [poiSticker convertPoint:poiSticker.center toView:[stickerView.stickerContainer containerView]];
    AWEInteractionStickerLocationModel *locationInfoModel = [[AWEInteractionStickerLocationModel alloc] initWithGeometryModel:[stickerView interactiveStickerGeometryWithCenterInPlayer:point interactiveBoundsSize:poiSticker.bounds.size] andTimeRangeModel:stickerView.stickerTimeRange];
    
    if (locationInfoModel.width && locationInfoModel.height) {
        AWEInteractionStickerLocationModel *finalLocation = [self.player resetStickerLocation:locationInfoModel isRecover:NO];
        if (finalLocation) {
            NSError *error = nil;
            NSArray *arr = [MTLJSONAdapter JSONArrayFromModels:@[finalLocation] error:&error];
            if (!error) {
                NSData *arrJsonData = [NSJSONSerialization dataWithJSONObject:arr options:kNilOptions error:&error];
                if (arrJsonData) {
                    NSString *arrJsonStr = [[NSString alloc] initWithData:arrJsonData encoding:NSUTF8StringEncoding];
                    interactionStickerInfo.trackInfo = arrJsonStr;
                }
                
                interactionStickerInfo.index = [interactionStickers count] + stickerIndex;
                interactionStickerInfo.adaptorPlayer = [self.player needAdaptPlayer];
                [interactionStickers addObject:interactionStickerInfo];
            }
            NSError *mappingError = nil;
            NSDictionary *poiStyleInfo = [MTLJSONAdapter JSONDictionaryFromModel:poiSticker.model.styleInfos error:&mappingError];
            if ([interactionStickerInfo isKindOfClass:[AWEInteractionPOIStickerModel class]]) {
                AWEInteractionPOIStickerModel *poiStickerModel = (AWEInteractionPOIStickerModel *)interactionStickerInfo;
                poiStickerModel.poiStyleInfo = poiStyleInfo;
            }
            
            if (error) {
                AWELogToolError(AWELogToolTagEdit, @"poi interaction model generate failed : %@", error);
            }
            if (mappingError) {
                AWELogToolError(AWELogToolTagEdit, @"poi style model save failed : %@", mappingError);
            }
        }
    }
}

- (ACCPOIStickerModel *)poiModelWithInteractionModel:(AWEInteractionPOIStickerModel *)model
{
    if (!model) {
        return nil;
    }
    NSString *poiID = [model.poiInfo acc_stringValueForKey:@"poi_id"];
    NSString *poiName = [model.poiInfo acc_stringValueForKey:@"poi_name"];
    ACCPOIStickerModel *stickerModel = [[ACCPOIStickerModel alloc] init];
    stickerModel.poiID = poiID;
    stickerModel.poiName = poiName;
    stickerModel.interactionStickerInfo = [model copy];
    return stickerModel;
}

- (AWEInteractionStickerLocationModel *)adaptedLocationWithInteractionInfo:(AWEInteractionStickerModel *)info
{
    AWEInteractionStickerLocationModel *location = [self locationModelFromInteractionInfo:info];
    
    BOOL isDraftBefore710 = NO;
    if (![self.dataProvider hasInfoStickerAddEdgeData]) {
        isDraftBefore710 = YES;
    }
    
    if (info.adaptorPlayer || isDraftBefore710) {
        location = [self.player resetStickerLocation:location isRecover:YES];
    }
    
    return location;
}

- (void)trackEvent:(NSString *)event stickerPOIView:(ACCModernPOIStickerView *)stickerView
{
    NSMutableDictionary *trackParams = self.dataProvider.baseTrackData.mutableCopy;
    if (stickerView.model.effectIdentifier) {
        [trackParams setObject:stickerView.model.effectIdentifier forKey:@"sticker_id"];
    }
    AWEInteractionModernPOIStickerInfoModel *styleInfos = stickerView.model.styleInfos;
    IESEffectModel *currentEffect = [styleInfos.effects acc_objectAtIndex:styleInfos.currentEffectIndex];
    if (currentEffect.effectName) {
        [trackParams setObject:currentEffect.effectName forKey:@"style_type"];
    }
    [ACCTracker() trackEvent:event params:trackParams.copy needStagingFlag:NO];
}

# pragma mark - Sticker process
- (void)addPOIStickerWithPOIModel:(ACCPOIStickerModel *)model
{
    [self addPOIStickerWithPOIModel:model locationModel:[self locationModelFromInteractionInfo:model.interactionStickerInfo] recoverSticker:nil userInfoConstructor:^(NSMutableDictionary *userInfo) {
        userInfo[ACCStickerDeleteableKey] = @(YES);
    } constructorBlock:nil];
}

- (void)addPOIStickerWithPOIModel:(ACCPOIStickerModel *)model locationModel:(AWEInteractionStickerLocationModel *)locationModel recoverSticker:(IESInfoSticker *)infoSticker userInfoConstructor:(nullable void (^)(NSMutableDictionary *))userInfoConstructor constructorBlock:(void (^)(ACCModernPOIStickerConfig *))constructorBlock
{
    if (!model || [self.currentPOIID isEqualToString:model.poiID]) {
        return;
    }
    
    if (infoSticker || ![self enableMultiStyleSwitch]) {
        // From draft or default style
        self.currentPOIID = model.poiID;
        
        AWEInteractionModernPOIStickerInfoModel *styleInfos = nil;
        AWEInteractionPOIStickerModel *poiStickerModel = nil;
        if ([model.interactionStickerInfo isKindOfClass:[AWEInteractionPOIStickerModel class]]) {
            poiStickerModel = (AWEInteractionPOIStickerModel *)model.interactionStickerInfo;
        }
        if (poiStickerModel.poiStyleInfo) {
            NSError *error = nil;
            styleInfos = [MTLJSONAdapter modelOfClass:AWEInteractionModernPOIStickerInfoModel.class fromJSONDictionary:poiStickerModel.poiStyleInfo error:&error];
            if (error) {
                AWELogToolError(AWELogToolTagEdit, @"poi style model generate failed : %@", error);
            }
        }
        if (!styleInfos) {
            styleInfos = [[AWEInteractionModernPOIStickerInfoModel alloc] init];
            styleInfos.currentEffectIndex = NSNotFound;
        }
        model.styleInfos = styleInfos;
        
        [self generatePOIStickerWithPOIModel:model locationModel:locationModel recoverSticker:infoSticker userInfoConstructor:userInfoConstructor constructorBlock:constructorBlock];
    } else {
        // From selected multi POI
        NSString *requestTag = [NSUUID UUID].UUIDString;
        self.currentLoadingTag = requestTag;
        
        [self startLoading];
        @weakify(self);
        let stickerDataHelper = [IESAutoInline(ACCBaseServiceProvider(), ACCModernPOIStickerDataHelperProtocol) class];
        [stickerDataHelper fetchEffectWithEffectIds:model.styleEffectIds defaultIndex:0 completionBlock:^(NSArray<IESEffectModel *> *effects, IESEffectModel *currentEffect, NSError *error) {
            @strongify(self);
            if (![self.currentLoadingTag isEqualToString:requestTag]) {
                return;
            }
            
            [self stopLoading];
            AWELogToolError(AWELogToolTagEdit, @"first poi effect with error : %@", error);
            [ACCMonitor() trackService:@"poi_multi_style_firstload_rate" status:(nil == error) ? 0 : 1 extra:@{@"code":@(error.code)}];
            [ACCDraft() saveInfoStickerPath:currentEffect.filePath draftID:self.dataProvider.currentTaskId completion:^(NSError * _Nonnull draftError, NSString * _Nonnull draftStickerPath) {
                @strongify(self);
                AWELogToolError(AWELogToolTagEdit, @"first poi effect with draftError : %@", draftError);
                self.currentPOIID = model.poiID;
                
                BOOL fetchSuccess = !error && [[NSFileManager defaultManager] fileExistsAtPath:draftStickerPath] && [[NSFileManager defaultManager] fileExistsAtPath:currentEffect.filePath];
                AWEInteractionModernPOIStickerInfoModel *styleInfo = [[AWEInteractionModernPOIStickerInfoModel alloc] init];
                styleInfo.effects = effects;
                styleInfo.currentEffectIndex = fetchSuccess ? 0 : NSNotFound;
                styleInfo.currentPath = fetchSuccess ? draftStickerPath.lastPathComponent : nil;
                model.styleInfos = styleInfo;
                
                [self generatePOIStickerWithPOIModel:model locationModel:locationModel recoverSticker:nil userInfoConstructor:userInfoConstructor constructorBlock:constructorBlock];
            }];
        }];
    }
}

// Add or change POI
- (void)generatePOIStickerWithPOIModel:(ACCPOIStickerModel *)model locationModel:(AWEInteractionStickerLocationModel *)locationModel recoverSticker:(IESInfoSticker *)infoSticker userInfoConstructor:(nullable void (^)(NSMutableDictionary *))userInfoConstructor constructorBlock:(void (^)(ACCModernPOIStickerConfig *))constructorBlock
{
    // Contruct all stickers
    NSInteger stickerId = -1;
    NSString *poiIdentifier = nil;
    ACCModernPOIStickerConfig *config = nil;
    ACCModernPOIStickerView *poiStickerView = nil;
    
    NSArray<UIView <ACCStickerContentProtocol> *> *poiStickerViewList = [[self.stickerContainerView stickerViewsWithTypeId:ACCStickerTypeIdModernPOI] acc_mapObjectsUsingBlock:^id _Nonnull(__kindof ACCBaseStickerView * _Nonnull obj, NSUInteger idex) {
        return [obj contentView];
    }];
    poiStickerView = (ACCModernPOIStickerView *)[poiStickerViewList acc_match:^BOOL(UIView<ACCStickerContentProtocol> * _Nonnull item) {
        return [item isKindOfClass:[ACCModernPOIStickerView class]];
    }];

    // Get StickerID;
    if (infoSticker && infoSticker.stickerId >= 0) {
        // from draft recover
        stickerId = infoSticker.stickerId;
    } else if (poiStickerView && poiStickerView.stickerId >= 0) {
        // update current sticker
        stickerId = poiStickerView.stickerId;
    } else {
        // new sticker
        poiIdentifier = [[NSUUID UUID] UUIDString];
        NSDictionary *userInfo = ({
            NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
            dictionary.acc_stickerType = ACCEditEmbeddedStickerTypeModrenPOI;
            dictionary[kACCStickerUUIDKey] = poiIdentifier;
            if (userInfoConstructor) {
                userInfoConstructor(dictionary);
            }
            [dictionary copy];
        });
        stickerId = [self.player addTextStickerWithUserInfo:userInfo];
        [self.player setStickerAbove:stickerId];
    }
    
    @weakify(self);
    if (!poiStickerView) {
        poiStickerView = [[ACCModernPOIStickerView alloc] init];
        poiStickerView.triggerDragDeleteCallback = ^{
            @strongify(self);
            [self.logger logStickerViewWillDeleteWithEnterMethod:@"drag"];
        };
        poiStickerView.stickerId = stickerId;
        
        // Add Config and Gesture_block
        config = [[ACCModernPOIStickerConfig alloc] init];
        if ([self enableMultiStyleSwitch]) {
            config.onceTapCallback = ^(__kindof ACCBaseStickerView<ACCGestureResponsibleStickerProtocol> * _Nonnull contentView, UITapGestureRecognizer * _Nonnull gesture) {
                @strongify(self);
                [self markAndRemovePOIHint];
                [self editPOISticker:poiStickerView];
            };
        } else {
            config.editPOI = ^{
                @strongify(self);
                [self markAndRemovePOIHint];
                !self.onEditPoiInfo ?: self.onEditPoiInfo();
            };
        }
        config.secondTapCallback = ^(__kindof ACCBaseStickerView<ACCGestureResponsibleStickerProtocol> * _Nonnull contentView, UITapGestureRecognizer * _Nonnull gesture) {
            @strongify(self);
            [self markAndRemovePOIHint];
            [self editPOISticker:poiStickerView];
        };
        config.gestureCanStartCallback = ^BOOL(__kindof ACCBaseStickerView<ACCGestureResponsibleStickerProtocol> * _Nonnull contentView, UIGestureRecognizer * _Nonnull gesture) {
            @strongify(self);
            [self markAndRemovePOIHint];
            return YES;
        };
        config.willDeleteCallback = ^{
            @strongify(self);
            self.currentPOIID = nil;
            [self dismissEditStickerViewStyle:YES];
            [self.player removeInfoSticker:poiStickerView.stickerId];
            [self.player setFixTopInfoSticker:-1];
        };
        config.locationDidChangedCallback = ^(ACCStickerGeometryModel * _Nonnull geometryModel) {
            @strongify(self);
            [self.player setSticker:poiStickerView.stickerId offsetX:geometryModel.x.floatValue offsetY:-geometryModel.y.floatValue];
            [self.player setSticker:poiStickerView.stickerId angle:geometryModel.rotation.floatValue];
            if (ACCConfigBool(kConfigBool_sticker_support_poi_mention_hashtag_UI_uniform)) {
                [self.player setStickerScale:poiStickerView.stickerId scale:0.75 * geometryModel.scale.floatValue];
            } else{
                [self.player setStickerScale:poiStickerView.stickerId scale:geometryModel.scale.floatValue];
            }
        };
        config.typeId = ACCStickerTypeIdModernPOI;
        config.hierarchyId = @(ACCStickerHierarchyTypeLow);
        config.showSelectedHint = ![self enableMultiStyleSwitch];
        config.timeRangeModel.pts = [NSDecimalNumber decimalNumberWithString:@"-1"];
        config.gestureInvalidFrameValue = self.dataProvider.gestureInvalidFrameValue;
        NSString *startTime = [NSString stringWithFormat:@"%.4f", 0.f];
        NSString *endTime = [NSString stringWithFormat:@"%.4f", self.player.stickerInitialEndTime];
        config.timeRangeModel.startTime = [NSDecimalNumber decimalNumberWithString:startTime];
        config.timeRangeModel.endTime = [NSDecimalNumber decimalNumberWithString:endTime];
        if (locationModel) {
            config.geometryModel = [locationModel ratioGeometryModel];
        }
    }
    
    if (!ACC_isEmptyString(poiIdentifier)) {
        poiStickerView.poiIdentifier = poiIdentifier;
    }
    
    if (constructorBlock) {
        constructorBlock(config);
    }

    poiStickerView.stickerId = stickerId;
    poiStickerView.model = model;
    poiStickerView.helper = self;
    [self updatePOISticker:poiStickerView];
    
    UIView<ACCSelectTimeRangeStickerProtocol> *stickerWrapper = [self.stickerContainerView stickerViewWithContentView:poiStickerView];
    if (!stickerWrapper) {
        stickerWrapper = [self.stickerContainerView addStickerView:poiStickerView config:config];
        BOOL useMulti = ([self enableMultiStyleSwitch] && model.styleInfos.effects.count > 0);
        [self showPOIHintOnStickerView:stickerWrapper useMulti:useMulti];
    }
}

// Update POI Style
- (void)updatePOISticker:(ACCModernPOIStickerView *)stickerView
{
    AWEInteractionModernPOIStickerInfoModel *poiStyleInfo = stickerView.model.styleInfos;
    NSString *effectPath = [AWEDraftUtils generatePathFromTaskId:self.dataProvider.currentTaskId name:poiStyleInfo.currentPath];
    IESEffectModel *effect = [poiStyleInfo.effects acc_objectAtIndex:poiStyleInfo.currentEffectIndex];
    let stickerDataHelper = [IESAutoInline(ACCBaseServiceProvider(), ACCModernPOIStickerDataHelperProtocol) class];
    NSString *textParams = [stickerDataHelper generateTextParamsWithPOIName:stickerView.model.poiName effectPath:effectPath effectModel:effect];
    [self.player setSticker:stickerView.stickerId startTime:0 duration:[self.player.videoData totalVideoDuration]];
    if (textParams.length) {
        [self.player setTextSticker:stickerView.stickerId textParams:textParams];
    }
    [self.player setFixTopInfoSticker:stickerView.stickerId];

    // Update content&wrapper frame
    CGSize stickerSize = [self.player getInfoStickerSize:stickerView.stickerId];
    IESInfoStickerProps *infos = [[IESInfoStickerProps alloc] init];
    [self.player getStickerId:stickerView.stickerId props:infos];// Size is current size, not original size
    CGFloat scale = infos.scale > 0 ? infos.scale : 1.f;
    stickerView.acc_size = CGSizeMake(stickerSize.width/scale, stickerSize.height/scale);
    CGPoint basicCenterInScreen = CGPointMake(ACC_SCREEN_WIDTH * 0.5, ACC_SCREEN_HEIGHT * 0.5);
    if (@available(iOS 9.0, *)) {
        basicCenterInScreen = [[[UIApplication sharedApplication].delegate window] convertPoint:basicCenterInScreen toView:stickerView];
    }
    stickerView.center = basicCenterInScreen;
    ACCBLOCK_INVOKE(stickerView.coordinateDidChange);
}

- (void)editPOISticker:(ACCModernPOIStickerView *)stickerView
{
    if (stickerView.model.styleInfos.effects.count > 0 && [self enableMultiStyleSwitch]) {
        if (!self.editView) {
            ACCModernPOIStickerSwitchView *editView = [[ACCModernPOIStickerSwitchView alloc] initWithFrame:self.stickerContainerView.overlayView.bounds];
            editView.delegate = self;
            self.editView = editView;
            [self.stickerContainerView.overlayView addSubview:editView];
        }
        [self trackEvent:@"edit_locationsticker" stickerPOIView:stickerView];
        [self.editView showSelectViewForSticker:stickerView];
        self.editView.hidden = NO;
        ACCBLOCK_INVOKE(self.editViewOnStartEdit);
    } else {
        ACCBLOCK_INVOKE(self.onEditPoiInfo);
    }
}

#pragma mark - Edit Actions
- (void)startLoading
{
    @weakify(self);
    self.loadingView = [ACCLoading() showWindowLoadingWithTitle:ACCLocalizedString(@"creation_edit_text_reading_load", @"Loading...") animated:YES];
    [self.loadingView showCloseBtn:YES closeBlock:^{
        @strongify(self);
        [self stopLoading];
    }];
    [self dismissEditStickerViewStyle:YES];
}

- (void)stopLoading
{
    self.currentLoadingTag = nil;
    [self.loadingView dismiss];
}

- (void)showPOIHintOnStickerView:(UIView *)stickerView useMulti:(BOOL)useMulti
{
    if (!self.poiHintView) {
        self.poiHintView = [[AWEEditStickerHintView alloc] init];
        [self.uiContainerView addSubview:self.poiHintView];
    }
    
    NSString *hint = useMulti ? ACCLocalizedString(@"locationsticker_changestyle",@"Tap to change style") : ACCLocalizedString(@"creation_edit_sticker_poi_double_click",@"Double tap to select location");
    AWEEditStickerHintType type = useMulti ? AWEEditStickerHintTypeInteractiveMultiPOI : AWEEditStickerHintTypeInteractive;
    [self.poiHintView showHint:hint type:type];
    self.poiHintView.bounds = (CGRect){CGPointZero, self.poiHintView.intrinsicContentSize};
    self.poiHintView.center = [stickerView.superview convertPoint:CGPointMake(stickerView.acc_centerX, stickerView.acc_top - self.poiHintView.acc_height) toView:self.uiContainerView];
}

- (void)markAndRemovePOIHint
{
    AWEEditStickerHintType type = [self enableMultiStyleSwitch] ? AWEEditStickerHintTypeInteractiveMultiPOI : AWEEditStickerHintTypeInteractive;
    [AWEEditStickerHintView setNoNeedShowForType:type];
    [self.poiHintView dismissWithAnimation:YES];
}

#pragma mark - ACCModernPOIStickerSwitchViewDelegate
// Change poi style
- (void)editStickerViewStyle:(ACCModernPOIStickerView *)stickerView didSelectIndex:(NSInteger)index completionBlock:(void (^)(BOOL))downloadedBlock
{
    AWEInteractionModernPOIStickerInfoModel *styleInfos = stickerView.model.styleInfos;
    styleInfos.loadingEffectIndex = index;
    
    @weakify(self);
    IESEffectModel *model = [styleInfos.effects acc_objectAtIndex:index];
    let stickerDataHelper = [IESAutoInline(ACCBaseServiceProvider(), ACCModernPOIStickerDataHelperProtocol) class];
    [stickerDataHelper fetchEffectWithModel:model completionBlock:^(BOOL success, NSError *error) {
        @strongify(self);
        if (success && !error) {
            [ACCDraft() saveInfoStickerPath:model.filePath draftID:self.dataProvider.currentTaskId completion:^(NSError * _Nonnull draftError, NSString * _Nonnull draftStickerPath) {
                @strongify(self);
                AWELogToolError(AWELogToolTagEdit, @"select poi effect with draftError : %@", draftError);
                // Check if poi is changed or index changed when download
                if (self.editView && styleInfos == stickerView.model.styleInfos && styleInfos.loadingEffectIndex == index) {
                    styleInfos.currentEffectIndex = index;
                    styleInfos.currentPath = draftStickerPath.lastPathComponent;
                    [self updatePOISticker:stickerView];
                    [self trackEvent:@"select_locationsticker_style" stickerPOIView:stickerView];
                }
            }];
        } else {
            [ACCToast() showError:ACCLocalizedString(@"load_failed",@"Couldn't load")];
        }
        AWELogToolError(AWELogToolTagEdit, @"select poi effect with error : %@", error);
        [ACCMonitor() trackService:@"poi_multi_style_changestyle_rate" status:(success && nil == error) ? 0 : 1 extra:@{@"code":@(error.code),@"style":model.effectIdentifier ? : @""}];
        ACCBLOCK_INVOKE(downloadedBlock,success);
    }];
}

// Change poi
- (void)selectPOIForEditStickerViewStyle
{
    ACCBLOCK_INVOKE(self.onEditPoiInfo);
}

// Dismiss edit view
- (void)dismissEditStickerViewStyle:(BOOL)poiChanged
{
    if (poiChanged) {
        [self.editView removeFromSuperview];
        self.editView = nil;
    } else {
        @weakify(self);
        [self.editView dismissSelectView:^{
            @strongify(self);
            self.editView.hidden = YES;
        }];
    }
    ACCBLOCK_INVOKE(self.editViewOnFinishEdit);
}

#pragma mark - ACCModernPOIStickerViewHelperProtocol

- (id<ACCStickerPlayerApplying>)currentPlayer
{
    return self.player;
}

#pragma mark - ACCDraftResourceRecoverProtocol

+ (NSArray<NSString *> *)draftResourceIDsToDownloadForPublishViewModel:(AWEVideoPublishViewModel *)publishModel
{
    NSMutableArray<NSString *> *draftResourceIDS = [[NSMutableArray alloc] init];
    if ([ACCModernPOIStickerHandler useModernPOIStickerStyle:publishModel.repoSticker.interactionStickers]) {
        id<ACCModernPOIStickerDataHelperProtocol> stickerDataHelper = IESAutoInline(ACCBaseServiceProvider(), ACCModernPOIStickerDataHelperProtocol);
        NSArray<NSString *> *effectIds = [[stickerDataHelper class] basicEffectIds];
        NSArray<NSString *> *tempEffectIds = [[[[stickerDataHelper class] commonEffectIds] firstObject]isEqual:effectIds.firstObject] ? [[stickerDataHelper class] standardEffectIds] : [[stickerDataHelper class] commonEffectIds];
        __block BOOL needReload = NO;
        [effectIds enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            IESEffectModel *defEffect = [[EffectPlatform sharedInstance] cachedEffectOfEffectId:obj];
            if (!defEffect.downloaded) {
                needReload = YES;
                *stop = YES;
            }
        }];
        if (needReload) {
            [draftResourceIDS addObjectsFromArray:effectIds];
            [draftResourceIDS addObjectsFromArray:tempEffectIds];
        }
        
        AWEInteractionStickerModel *poiInteractionSticker = [publishModel.repoSticker.interactionStickers acc_match:^BOOL(AWEInteractionStickerModel * _Nonnull item) {
            return item.type == AWEInteractionStickerTypePOI;
        }];
        IESInfoSticker *poiSticker = [publishModel.repoVideoInfo.video.infoStickers acc_match:^BOOL(IESInfoSticker * _Nonnull item) {
            return item.acc_stickerType == ACCEditEmbeddedStickerTypeModrenPOI;
        }];
        if ([poiInteractionSticker isKindOfClass:[AWEInteractionPOIStickerModel class]]) {
            AWEInteractionPOIStickerModel *poiStickerModel = (AWEInteractionPOIStickerModel *)poiInteractionSticker;
            
            if (poiStickerModel.poiStyleInfo != nil && poiSticker != nil) {
                NSError *error = nil;
                AWEInteractionModernPOIStickerInfoModel *styleInfos = [MTLJSONAdapter modelOfClass:[AWEInteractionModernPOIStickerInfoModel class] fromJSONDictionary:poiStickerModel.poiStyleInfo error:&error];
                NSArray<NSString *> *poiEffects = [poiSticker.userinfo acc_arrayValueForKey:@"effects"];
                if (styleInfos.effects == nil && poiEffects.count > 0) {
                    [draftResourceIDS addObjectsFromArray:poiEffects];
                }
            }
        }
    }
    
    return draftResourceIDS;
}

+ (void)updateWithDownloadedEffects:(NSArray<IESEffectModel *> *)effects
                   publishViewModel:(AWEVideoPublishViewModel *)publishModel
                         completion:(nonnull ACCDraftRecoverCompletion)completion
{
    id<ACCModernPOIStickerDataHelperProtocol> stickerDataHelper = IESAutoInline(ACCBaseServiceProvider(), ACCModernPOIStickerDataHelperProtocol);
    [[stickerDataHelper class] saveBasicEffects:effects];
    
    if ([ACCModernPOIStickerHandler useModernPOIStickerStyle:publishModel.repoSticker.interactionStickers]) {
        AWEInteractionPOIStickerModel *poiInteractionSticker = (AWEInteractionPOIStickerModel *)[publishModel.repoSticker.interactionStickers acc_match:^BOOL(AWEInteractionStickerModel * _Nonnull item) {
            return item.type == AWEInteractionStickerTypePOI;
        }];
        IESInfoSticker *poiSticker = [publishModel.repoVideoInfo.video.infoStickers acc_match:^BOOL(IESInfoSticker * _Nonnull item) {
            return item.acc_stickerType == ACCEditEmbeddedStickerTypeModrenPOI;
        }];
        
        if (poiSticker != nil
            && poiInteractionSticker.poiStyleInfo != nil
            && poiInteractionSticker.poiStyleInfo[@"effects"] == nil) {
            NSError *error = nil;
            AWEInteractionModernPOIStickerInfoModel *styleInfos = [MTLJSONAdapter modelOfClass:[AWEInteractionModernPOIStickerInfoModel class] fromJSONDictionary:poiInteractionSticker.poiStyleInfo error:&error];
            NSArray<NSString *> *poiEffects = [poiSticker.userinfo acc_arrayValueForKey:@"effects"];
            
            NSMutableSet<NSString *> *existedEffectIDS = [NSMutableSet set];
            NSArray<IESEffectModel *> *temp_effects = [[effects acc_filter:^BOOL(IESEffectModel * _Nonnull item) {
                BOOL isContains = [poiEffects containsObject:item.effectIdentifier] ||
                    [poiEffects containsObject:item.originalEffectID];
                BOOL isAdded = [existedEffectIDS containsObject:item.effectIdentifier] ||
                    [existedEffectIDS containsObject:item.originalEffectID];
                [existedEffectIDS addObject:item.effectIdentifier];
                return isContains && !isAdded;
            }] sortedArrayUsingComparator:^NSComparisonResult(IESEffectModel  * _Nonnull obj1, IESEffectModel  * _Nonnull obj2) {
                NSUInteger obj1Index = [poiEffects indexOfObject:obj1.effectIdentifier];
                NSUInteger obj2Index = [poiEffects indexOfObject:obj2.effectIdentifier];
                if (obj1Index > obj2Index) {
                    return NSOrderedDescending;
                } else if (obj1Index == obj2Index) {
                    return NSOrderedSame;
                } else {
                    return NSOrderedAscending;
                }
            }];
            
            styleInfos.effects = temp_effects;
            IESEffectModel *current_effect = [styleInfos.effects acc_objectAtIndex:styleInfos.currentEffectIndex];
            if (current_effect != nil) {
                [ACCDraft() saveInfoStickerPath:current_effect.filePath draftID:publishModel.repoDraft.taskID completion:^(NSError * _Nonnull draftError, NSString * _Nonnull draftStickerPath) {
                    if (draftError == nil && !ACC_isEmptyString(draftStickerPath)) {
                        styleInfos.currentPath = [NSURL URLWithString:draftStickerPath].lastPathComponent;
                        NSError *error = nil;
                        poiInteractionSticker.poiStyleInfo = [MTLJSONAdapter JSONDictionaryFromModel:styleInfos error:&error];
                    }
                }];
            }
        }
    }
    
    ACCBLOCK_INVOKE(completion, nil, NO);
}

#pragma mark - ACCStickerMigrationProtocol

+ (BOOL)fillCrossPlatformStickerByUserInfo:(NSDictionary *)userInfo repository:(id<ACCPublishRepository>)sessionModel context:(id<ACCCrossPlatformMigrateContext>)context sticker:(NLESegmentSticker_OC *__autoreleasing *)sticker
{
    if (userInfo.acc_stickerType == ACCEditEmbeddedStickerTypeModrenPOI) {
        let stickerDataHelper = [IESAutoInline(ACCBaseServiceProvider(), ACCModernPOIStickerDataHelperProtocol) class];
        NSString *textParams = [stickerDataHelper optimizeTextParams:context.textParams];
        
        ACCRepoStickerModel *stickerModel = [sessionModel extensionModelOfClass:[ACCRepoStickerModel class]];
        AWEInteractionPOIStickerModel *poiInteractionSticker = (AWEInteractionPOIStickerModel *)[stickerModel.interactionStickers acc_match:^BOOL(AWEInteractionStickerModel * _Nonnull item) {
            return item.type == AWEInteractionStickerTypePOI;
        }];
        if (poiInteractionSticker == nil) {
            return YES;
        }
        
        NLESegmentTextSticker_OC *sticker_ = [NLESegmentTextSticker_OC textStickerWithEffectSDKJSONString:textParams];
        sticker_.stickerType = ACCCrossPlatformStickerTypeEffectPOI;
        sticker_.content = [poiInteractionSticker.poiInfo acc_stringValueForKey:@"poi_name"];
        
        sticker_.extraDict = [NSMutableDictionary dictionary];
        AWEInteractionModernPOIStickerInfoModel *styleInfos = nil;
        if (poiInteractionSticker.poiStyleInfo != nil) {
            NSError *error = nil;
            styleInfos = [MTLJSONAdapter modelOfClass:[AWEInteractionModernPOIStickerInfoModel class] fromJSONDictionary:poiInteractionSticker.poiStyleInfo error:&error];
            if (error != nil) {
                AWELogToolError2(@"EffectSticker", AWELogToolTagDraft, @"POI Style Info Model Convert To Json Error: %@", error);
            }
        }
        IESEffectModel *effectModel = [styleInfos.effects acc_objectAtIndex:styleInfos.currentEffectIndex];
        sticker_.extraDict[@"sticker_id"] = effectModel.effectIdentifier;
        NSError *error = nil;
        NSMutableDictionary *styleInfoDic = [MTLJSONAdapter JSONDictionaryFromModel:poiInteractionSticker error:&error].mutableCopy ?: @{}.mutableCopy;
        if (error != nil) {
            AWELogToolError2(@"EffectSticker", AWELogToolTagDraft, @"Interaction Sticker Model Convert To Json Error: %@", error);
        }
        [styleInfoDic removeObjectForKey:@"poiStyleInfo"];
        sticker_.extraDict[ACCInteractionStickerTransferKey] = styleInfoDic;
        sticker_.extraDict[@"effects"] = [styleInfos.effects acc_mapObjectsUsingBlock:^NSString  * _Nonnull (IESEffectModel  * _Nonnull  effect, NSUInteger idex) {
            return effect.effectIdentifier;
        }];
        sticker_.extraDict[ACCStickerDeleteableKey] = userInfo[ACCStickerDeleteableKey];
        sticker_.extraDict[ACCStickerEditableKey] = userInfo[ACCStickerEditableKey];

        *sticker = sticker_;

        return YES;
    }
    return NO;
}

+ (void)updateUserInfo:(NSDictionary *__autoreleasing *)userInfo repoModel:(id<ACCPublishRepository>)sessionModel byCrossPlatformSlot:(nonnull NLETrackSlot_OC *)slot
{
    if (slot.sticker.stickerType == ACCCrossPlatformStickerTypeEffectPOI) {
        NLESegmentSticker_OC *sticker = slot.sticker;
        NSMutableDictionary *temp_userInfo = [NSMutableDictionary dictionary];
        temp_userInfo.acc_stickerType = ACCEditEmbeddedStickerTypeModrenPOI;
        temp_userInfo[kACCStickerUUIDKey] = [NSUUID UUID].UUIDString ?: @"";
        temp_userInfo[@"effects"] = sticker.extraDict[@"effects"];
        temp_userInfo[ACCStickerDeleteableKey] = [sticker.extraDict acc_objectForKey:ACCStickerDeleteableKey];
        temp_userInfo[ACCStickerEditableKey] = [sticker.extraDict acc_objectForKey:ACCStickerEditableKey];
        
        ACCRepoStickerModel *repoStickerModel = [sessionModel extensionModelOfClass:[ACCRepoStickerModel class]];
        BOOL containPOI = [repoStickerModel.interactionStickers acc_match:^BOOL(AWEInteractionStickerModel * _Nonnull item) {
            return [item isKindOfClass:[AWEInteractionPOIStickerModel class]];
        }] != nil;
        
        if (!containPOI) {
            NSError *error = nil;
            AWEInteractionPOIStickerModel *poiInteractionSticker = [MTLJSONAdapter modelOfClass:[AWEInteractionPOIStickerModel class] fromJSONDictionary:[sticker.extraDict acc_dictionaryValueForKey:ACCInteractionStickerTransferKey] error:&error];
            if (poiInteractionSticker == nil) {
                if (error != nil) {
                    AWELogToolError2(@"EffetSticker", AWELogToolTagDraft, @"Interaction Sticker Json Convert To Model Error: %@", error);
                    error = nil;
                }
                return;
            }
            AWEInteractionModernPOIStickerInfoModel *styleInfos = [[AWEInteractionModernPOIStickerInfoModel alloc] init];
            styleInfos.currentEffectIndex = [[sticker.extraDict acc_arrayValueForKey:@"effects"] indexOfObject:[sticker.extraDict acc_stringValueForKey:@"sticker_id"]];
            poiInteractionSticker.poiStyleInfo = [MTLJSONAdapter JSONDictionaryFromModel:styleInfos error:&error];
            if (error != nil) {
                AWELogToolError2(@"EffectSticker", AWELogToolTagDraft, @"POI Style Info Json Convert To Model Error: %@", error);
            }
            
            NSMutableArray *interactionStickers = [NSMutableArray array];
            [interactionStickers addObject:poiInteractionSticker];
            if (!ACC_isEmptyArray(repoStickerModel.interactionStickers)) {
                [interactionStickers addObjectsFromArray:repoStickerModel.interactionStickers];
            }
            repoStickerModel.interactionStickers = interactionStickers;
        }
        *userInfo = temp_userInfo;
        
        // Trap
        [sticker setInfoStringList:@[@"lv_new_text"].mutableCopy];
    }
}

@end
