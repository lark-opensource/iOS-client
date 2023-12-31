//
//  ACCGrootStickerHandler.m
//  CameraClient-Pods-Aweme
//
//  Created by 饶骏华 on 2021/5/14.
//

#import "ACCGrootStickerHandler.h"
#import <CreativeKit/ACCMacros.h>
#import "ACCStickerDataProvider.h"
#import "ACCConfigKeyDefines.h"
#import <CreationKitArch/AWEInteractionStickerLocationModel+ACCSticker.h>
#import "ACCGrootStickerRecognitionView.h"
#import "ACCGrootStickerModel.h"
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreationKitInfra/NSData+ACCAdditions.h>
#import <CreationKitArch/ACCEditAndPublishConstants.h>
#import "AWERepoStickerModel.h"
#import <CreationKitInfra/ACCLogHelper.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import "AWEInteractionGrootStickerModel.h"
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CreationKitArch/ACCRepoUploadInfomationModel.h>
#import <CreativeKit/ACCCacheProtocol.h>
#import "ACCVideoEditTipsViewModel.h"
#import <CameraClient/AWERepoStickerModel.h>
#import "AWERepoStickerModel.h"
#import <NLEPlatform/NLESegmentInfoSticker+iOS.h>
#import "NLESegmentSticker_OC+ACCAdditions.h"
#import "NLETrackSlot_OC+ACCAdditions.h"
#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import "IESInfoSticker+ACCAdditions.h"
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <CameraClient/ACCGrootStickerRecognitionPlugin.h>
#import "ACCRecognitionTrackModel.h"
#import "ACCRecognitionGrootConfig.h"
#import <CameraClientModel/ACCCrossPlatformStickerType.h>

NSString * const kGrootStickerUserInfoUniqueIdKey = @"kGrootStickerUserInfoUniqueIdKey";
NSString * const kGrootStickerUserInfoDraftJsonDataKey = @"kGrootStickerUserInfoDraftJsonDataKey";

@interface ACCGrootStickerHandler ()

@property (nonatomic, strong) ACCGrootStickerRecognitionView *grootStickerRecognitionView;
@property (nonatomic,   weak) id<ACCGrootStickerDataProvider> dataProvider;
@property (nonatomic, strong) AWEVideoPublishViewModel *publishModel;
@property (nonatomic, strong) ACCGrootStickerViewModel *grootViewModel;

@end

@implementation ACCGrootStickerHandler

#pragma mark - life cycle

- (instancetype)initWithDataProvider:(id<ACCGrootStickerDataProvider>)dataProvider
                        publishModel:(AWEVideoPublishViewModel *)publishModel viewModel:(ACCGrootStickerViewModel *)viewModel  {
    if (self = [super init]) {
        _dataProvider = dataProvider;
        _publishModel = publishModel;
        _grootViewModel = viewModel;
    }
    return self;
}

#pragma mark - public

- (ACCGrootStickerView *)addGrootStickerWithModel:(nullable ACCGrootStickerModel *)model
                                     locationModel:(nullable AWEInteractionStickerLocationModel *)locationModel
                                  constructorBlock:(nullable void (^)(ACCGrootStickerConfig *))constructorBlock {
        return [self addGrootStickerWithModel:model
                                 locationModel:locationModel
                         grootStickerUniqueId:nil
                              constructorBlock:constructorBlock];
    
}

- (void)editTextStickerView:(ACCGrootStickerView *)stickerView {
    [self setupEditViewIfNeed];
    [self.stickerContainerView.overlayView addSubview:self.grootStickerRecognitionView];
    [self.grootStickerRecognitionView startEditStickerView:stickerView];
    
    // track
    NSDictionary *params = [self grootTrackCommonDic:stickerView.stickerModel];
    [ACCTracker() trackEvent:@"groot_prop_species_layer_show" params:params needStagingFlag:NO];
}

#pragma mark - private

- (NSDictionary *)grootTrackCommonDic:(ACCGrootStickerModel *)grootModel {
    NSMutableDictionary *dict = [self.publishModel.repoTrack.referExtra mutableCopy] ?: [@{} mutableCopy];
    if (grootModel.grootDetailStickerModels.count > 0) {
        __block NSMutableArray *baikeIdList = [[NSMutableArray alloc] init];
        __block NSMutableArray *speciesNameList = [[NSMutableArray alloc] init];
        [grootModel.grootDetailStickerModels enumerateObjectsUsingBlock:^(ACCGrootDetailsStickerModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.baikeId) {
                [baikeIdList acc_addObject:obj.baikeId];
            }
            if (obj.speciesName) {
                [speciesNameList acc_addObject:obj.speciesName];
            }
        }];
        dict[@"baike_id_list"] = [baikeIdList componentsJoinedByString:@","] ?: @"";
        dict[@"species_name_list"] = [speciesNameList componentsJoinedByString:@","] ?: @"";
    } else {
        dict[@"baike_id_list"] = @"";
        dict[@"species_name_list"] = @"";
    }
    dict[@"from_parent_id"] = self.publishModel.repoUploadInfo.extraDict[@"from_parent_id"];
    dict[@"is_groot_new"] = self.publishModel.repoUploadInfo.extraDict[@"is_groot_new"];
    BOOL grootShow = [ACCCache() boolForKey:kAWENormalVideoEditGrootStickerBubbleShowKey];
    dict[@"is_groot_toast_show"]  = grootShow ? @1 : @0;
    return [dict copy];
}

- (ACCGrootStickerView *)addGrootStickerWithModel:(ACCGrootStickerModel *)model
                                      locationModel:(AWEInteractionStickerLocationModel *)locationModel
                              grootStickerUniqueId:(NSString *)grootStickerUniqueId
                                   constructorBlock:(void (^)(ACCGrootStickerConfig *))constructorBlock {
    if (!model) {
        return nil;
    }
    
    ACCGrootStickerView *grootStickerView = nil;
    if ([self.dataProvider respondsToSelector:@selector(customGrootStickerView:)]){
        grootStickerView = [self.dataProvider customGrootStickerView:model];
    }

    if (!grootStickerView){
        grootStickerView  = [[ACCGrootStickerView alloc] initWithStickerModel:model grootStickerUniqueId:grootStickerUniqueId];
    }

    @weakify(self);
    grootStickerView.triggerDragDeleteCallback = ^{
        @strongify(self);
        [self.logger logStickerViewWillDeleteWithEnterMethod:@"drag"];
    };
    ACCGrootStickerConfig *config = [self stickerConfig:grootStickerView locationModel:locationModel];
    ACCBLOCK_INVOKE(constructorBlock, config);
    
    // added grootSticker
    [self.stickerContainerView addStickerView:grootStickerView config:config];

    return grootStickerView;
}

- (ACCGrootStickerConfig *)stickerConfig:(ACCGrootStickerView *)grootStickerView
                            locationModel:(AWEInteractionStickerLocationModel *)locationModel
{
    ACCGrootStickerConfig *config = [[ACCGrootStickerConfig alloc] init];

    if (ACCConfigBool(kConfigBool_sticker_support_groot)) {
        @weakify(self);
        if (ACCConfigBool(ACCConfigBOOL_allow_sticker_delete)) {
            @weakify(grootStickerView);
            config.deleteAction = ^{
                @strongify(self);
                @strongify(grootStickerView);
                [self.logger logStickerViewWillDeleteWithEnterMethod:@"click"];
                [self.stickerContainerView removeStickerView:grootStickerView];
            };
        }

        // handle bubble action
        config.editText = ^{
            @strongify(self);
            [self editTextStickerView:grootStickerView];
        };

        config.secondTapCallback = ^(__kindof ACCBaseStickerView<ACCGestureResponsibleStickerProtocol> * _Nonnull contentView, UITapGestureRecognizer * _Nonnull gesture) {
            @strongify(self);
            [self editTextStickerView:grootStickerView];
        };
        
        config.willDeleteCallback = ^(){
            @strongify(self);
            ACCBLOCK_INVOKE(self.willDeleteCallback);
        };
    }
    
    config.typeId = ACCStickerTypeIdGroot;
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
        CGFloat percent = (ACC_SCREEN_HEIGHT - 180)/ACC_SCREEN_HEIGHT;
        CGFloat offsetX = 0.50f;
        CGFloat offsetY = percent;
        NSString *offsetXStr = [NSString stringWithFormat:@"%.4f", offsetX];
        NSString *offsetYStr = [NSString stringWithFormat:@"%.4f", offsetY];
        locationModel.y = [NSDecimalNumber decimalNumberWithString:offsetYStr];
        locationModel.x = [NSDecimalNumber decimalNumberWithString:offsetXStr];
    }

    config.geometryModel = [locationModel ratioGeometryModel];

    return config;
}

- (void)setupEditViewIfNeed {
    if (self.grootStickerRecognitionView) { return; }
    
    // config editView action block
    self.grootStickerRecognitionView = [ACCGrootStickerRecognitionView editViewWithPublishModel:self.publishModel];

    @weakify(self);
    self.grootStickerRecognitionView.onEditFinishedBlock = ^(ACCGrootStickerView * _Nonnull grootStickerView) {
        @strongify(self);
        if (!grootStickerView.stickerModel.selectedGrootStickerModel) {
            [self.stickerContainerView removeStickerView:grootStickerView];
        }
        [self.grootStickerRecognitionView removeFromSuperview];
    };
    
    self.grootStickerRecognitionView.finishEditAnimationBlock = ^(ACCGrootStickerView * _Nonnull grootStickerView, BOOL autoAddGrootHashTag, NSDictionary *trackInfo) {
        @strongify(self);
        // track
        BOOL isCancel = [trackInfo acc_boolValueForKey:@"isCancel"];

        ACCBLOCK_INVOKE(self.editViewOnFinishEdit, autoAddGrootHashTag, grootStickerView.stickerModel, isCancel);

        if (autoAddGrootHashTag) {
            // groot贴纸关联自动hashtag贴纸，还原坐标
            UIView<ACCStickerProtocol> *grootStickerTyper = [self.stickerContainerView stickerViewWithContentView:self.grootStickerRecognitionView.grootStickerView];
            if (grootStickerTyper) {
                AWEInteractionStickerLocationModel *locationModel = [AWEInteractionStickerLocationModel new];
                CGFloat offsetX = 0.50f;
                CGFloat offsetY = 0.50f;
                NSString *offsetXStr = [NSString stringWithFormat:@"%.4f", offsetX];
                NSString *offsetYStr = [NSString stringWithFormat:@"%.4f", offsetY];
                locationModel.y = [NSDecimalNumber decimalNumberWithString:offsetYStr];
                locationModel.x = [NSDecimalNumber decimalNumberWithString:offsetXStr];
                [grootStickerTyper recoverWithGeometryModel:[locationModel ratioGeometryModel]];
            }
        }

        if (isCancel) {
            NSDictionary *params = [self grootTrackCommonDic:grootStickerView.stickerModel];
            [ACCTracker() trackEvent:@"groot_prop_species_layer_cancel" params:params needStagingFlag:NO];
        } else {
            NSMutableDictionary *params = [[self grootTrackCommonDic:grootStickerView.stickerModel] mutableCopy];
            params[@"baike_id_list"] = nil;
            params[@"species_name_list"] = nil;
            if (autoAddGrootHashTag) {
                params[@"baike_id"] = @"need_identification";
                params[@"species_name"] = @"need_identification";
            } else {
                params[@"baike_id"] = grootStickerView.stickerModel.selectedGrootStickerModel.baikeId ?: @0;
                params[@"species_name"] =grootStickerView.stickerModel.selectedGrootStickerModel.speciesName ?: @"";
            }
            params[@"is_authorized"] = grootStickerView.stickerModel.allowGrootResearch ? @1 : @0;
            self.publishModel.repoUploadInfo.extraDict[@"baike_id"] = params[@"baike_id"];
            self.publishModel.repoUploadInfo.extraDict[@"species_name"] = params[@"species_name"];
            self.publishModel.repoUploadInfo.extraDict[@"is_authorized"] = params[@"is_authorized"];
            params[@"rank"] = trackInfo[@"selectedIndex"] ?: @(0);
            BOOL clickMask = [trackInfo acc_boolValueForKey:@"clickMask"];
            params[@"confirm_type"] = clickMask ? @"click_blank" : @"cilck_confirm";
            [ACCTracker() trackEvent:@"groot_prop_species_layer_confirm" params:params needStagingFlag:NO];
        }
    };
    
    self.grootStickerRecognitionView.startEditBlock = ^(ACCGrootStickerView * _Nonnull grootStickerView){
        @strongify(self);
        ACCBLOCK_INVOKE(self.editViewOnStartEdit);
        NSMutableDictionary *params = [NSMutableDictionary dictionary];
        params[@"enter_from"] = @"video_edit_page";
        params[@"prop_id"] = [ACCRecognitionGrootConfig grootStickerId];
        params[@"is_sticker"] = @1;
        [ACCTracker() trackEvent:@"click_change_species" params:params needStagingFlag:NO];
    };

    self.grootStickerRecognitionView.selectModelCallback = ^(ACCGrootDetailsStickerModel * _Nonnull model){
        @strongify(self);
        ACCBLOCK_INVOKE(self.selectModelCallback, model);
    };

    self.grootStickerRecognitionView.confirmCallback = ^{
        @strongify(self);
        ACCBLOCK_INVOKE(self.grootStickerConfirmCallback);
    };
}

#pragma mark - ACCStickerHandler apply

- (void)apply:(UIView<ACCStickerProtocol> *)sticker index:(NSUInteger)idx {

    ACCGrootStickerView *grootStickerView = (ACCGrootStickerView *)sticker.contentView;

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
    NSString *imagePath = [self.dataProvider grootStickerImagePathForDraftWithIndex:idx];
    BOOL ret = [imageData acc_writeToFile:imagePath atomically:YES];

    if ([[NSFileManager defaultManager] fileExistsAtPath:imagePath]) {

        NSMutableDictionary *userInfo = [@{} mutableCopy];
        userInfo.acc_stickerType = ACCEditEmbeddedStickerTypeGroot;

        userInfo[kGrootStickerUserInfoUniqueIdKey] = grootStickerView.grootStickerUniqueId ?: @"";
        if ([sticker.config isKindOfClass:[ACCCommonStickerConfig class]]) {
            ACCCommonStickerConfig *config = (ACCCommonStickerConfig *)sticker.config;
            userInfo[ACCStickerEditableKey] = config.editable;
            userInfo[ACCStickerDeleteableKey] = config.deleteable;
        }

        NSString *draftDataJsonString = [grootStickerView.stickerModel draftDataJsonString];
        userInfo[kGrootStickerUserInfoDraftJsonDataKey] = draftDataJsonString;

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
                       @"grootStickersForPublishInfo:create Failed:%@, write Failed:%@",
                       @(!image), @(ret));
    }
}

- (void)addInteractionStickerInfoToArray:(NSMutableArray *)interactionStickers idx:(NSInteger)stickerIndex {

    for (UIView<ACCStickerProtocol> *sticker in [[self.stickerContainerView stickerViewsWithTypeId:ACCStickerTypeIdGroot] acc_filter:^BOOL(ACCStickerViewType  _Nonnull item) {
        return [item.contentView isKindOfClass:[ACCGrootStickerView class]];
    }]) {
        [self addGrootInteractionStickerInfo:sticker toArray:interactionStickers idx:stickerIndex];
    }
}

- (void)addGrootInteractionStickerInfo:(UIView<ACCStickerProtocol> *)stickerView
                                toArray:(NSMutableArray *)interactionStickers
                                    idx:(NSInteger)stickerIndex {

    ACCGrootStickerView *grootView = (ACCGrootStickerView *)(stickerView.contentView);

    ACCGrootStickerModel *stickerModel = grootView.stickerModel;
    
    AWEInteractionStickerModel *interactionStickerInfo = nil;
    
    { /* ························· server data binding unit ··························· */
        
        // added keyvalue  to server  by manual , auto serialization may case property name changed
        interactionStickerInfo = [[AWEInteractionGrootStickerModel alloc] init];
        interactionStickerInfo.type = AWEInteractionStickerTypeGroot;
        NSMutableDictionary *grootInteraction = [NSMutableDictionary dictionaryWithCapacity:3];
        ACCGrootDetailsStickerModel *grootDetailModel = stickerModel.selectedGrootStickerModel;
        if (grootDetailModel) {
            NSDictionary *userGrootInfo = @{
                @"species_name"  : grootDetailModel.speciesName ?: @"",
                @"prob" : grootDetailModel.prob ?: @0,
                @"baike_id" : grootDetailModel.baikeId ?: @0
            };
            [grootInteraction addEntriesFromDictionary:@{
                @"type": @(AWEInteractionStickerTypeGroot) ?: @0,
                @"index": @([interactionStickers count] + stickerIndex) ?: @0}];
            [grootInteraction addEntriesFromDictionary:@{@"user_groot_info" : userGrootInfo}];
            ((AWEInteractionGrootStickerModel *)interactionStickerInfo).grootInteraction = grootInteraction;
        } else {
            AWELogToolError2(@"Groot", AWELogToolTagEdit, @"add GrootInteractionSticker failed, groot selected model is null.");
        }
    }
    
    /* ·························  model create unit ··························· */
    if (interactionStickerInfo == nil) {
        interactionStickerInfo = [AWEInteractionStickerModel new];
    }
    
    interactionStickerInfo.stickerID = stickerModel.effectIdentifier;
    interactionStickerInfo.type = AWEInteractionStickerTypeGroot;
    interactionStickerInfo.localStickerUniqueId = grootView.grootStickerUniqueId;
    interactionStickerInfo.index = [interactionStickers count] + stickerIndex;
    interactionStickerInfo.adaptorPlayer = [self.player needAdaptPlayer];
   
    { /* ························· unique check unit ··························· */

        if (ACC_isEmptyString(grootView.grootStickerUniqueId) ||
           [self isGrootStickerAlreayAdded:grootView toInteractionArray:[interactionStickers copy]]) {
            /// @Discussion @Guochen Yang, the func 'addInteractionStickerInfoToArray: idx' should only called once, but not expected  now.
            return;
        }
    }

    { /* ························· valid check unit ··························· */

        if (ACC_isEmptyString(stickerModel.selectedGrootStickerModel.speciesName)) {
            AWELogToolError2(@"Groot", AWELogToolTagEdit, @"apply interactionSticker failed.");
            return;
        }
    }

    { /* ························· location process unit ··························· */
        CGPoint point = [stickerView convertPoint:grootView.center toView:[stickerView.stickerContainer containerView]];
        AWEInteractionStickerLocationModel *locationInfoModel = [[AWEInteractionStickerLocationModel alloc] initWithGeometryModel:[stickerView interactiveStickerGeometryWithCenterInPlayer:point interactiveBoundsSize:grootView.bounds.size] andTimeRangeModel:stickerView.stickerTimeRange];
        if (locationInfoModel.width && locationInfoModel.height) {
            AWEInteractionStickerLocationModel *finalLocation = [self.player resetStickerLocation:locationInfoModel isRecover:NO];
            if (!finalLocation) {
                return;
            }
            [interactionStickerInfo storeLocationModelToTrackInfo:finalLocation];
        }
    }

    /* ························· congratulation, effective case! ··························· */
    [interactionStickers acc_addObject:interactionStickerInfo];
}

- (BOOL)isGrootStickerAlreayAdded:(ACCGrootStickerView *)sticker
                toInteractionArray:(NSArray <AWEInteractionStickerModel *> *)array {
    for (AWEInteractionStickerModel * model in array) {
        if (!ACC_isEmptyString(model.localStickerUniqueId) &&
            [model.localStickerUniqueId isEqualToString:sticker.grootStickerUniqueId]) {
            return YES;
        }
    }
    return NO;
}

#pragma mark - Express Sticker

- (BOOL)canExpressSticker:(ACCEditorStickerConfig *)stickerConfig
{
    return [stickerConfig isKindOfClass:[ACCGrootStickerConfig class]];
}

- (void)expressSticker:(ACCEditorStickerConfig *)stickerConfig
{
    [self expressSticker:stickerConfig withCompletion:^{
        
    }];
}

- (void)expressSticker:(ACCEditorStickerConfig *)stickerConfig withCompletion:(void (^)(void))completionHandler
{
    if ([self canExpressSticker:stickerConfig]) {
    }
}

#pragma mark - ACCStickerHandler recover

- (void)recoverSticker:(ACCRecoverStickerModel *)sticker {

    if ([self canRecoverSticker:sticker]) {

        NSString *grootStickerUniqueId = [sticker.infoSticker.userinfo acc_stringValueForKey:kGrootStickerUserInfoUniqueIdKey];
        if (ACC_isEmptyString(grootStickerUniqueId)) {
            return;
        }

        AWEInteractionStickerModel *interactionStickerModel = [self.dataProvider.interactionStickers acc_match:^BOOL(AWEInteractionStickerModel * _Nonnull item) {
            return item.trackInfo && item.type == AWEInteractionStickerTypeGroot && [item.localStickerUniqueId isEqualToString:grootStickerUniqueId];
        }];

        ACCGrootStickerModel *grootStickerModel = [self grootStickerModelWithInfoSticker:sticker.infoSticker
                                                                    interactionStickerModel:interactionStickerModel];
        if (grootStickerModel) {
            AWEInteractionStickerLocationModel *locationModel = [interactionStickerModel fetchLocationModelFromTrackInfo];
            if (interactionStickerModel.adaptorPlayer) {
                locationModel = [self.player resetStickerLocation:locationModel isRecover:YES];
            }
            
            NSNumber *deleteable = [sticker.infoSticker.userinfo acc_objectForKey:ACCStickerDeleteableKey];
            NSNumber *editable = [sticker.infoSticker.userinfo acc_objectForKey:ACCStickerEditableKey];
            
            [self addGrootStickerWithModel:grootStickerModel
                              locationModel:locationModel
                      grootStickerUniqueId:grootStickerUniqueId
                           constructorBlock:^(ACCGrootStickerConfig *config) {
                config.deleteable = deleteable;
                config.editable = editable;
            }];
        }
    }
}

- (BOOL)canRecoverSticker:(ACCRecoverStickerModel *)sticker {
    return sticker.infoSticker.acc_stickerType == ACCEditEmbeddedStickerTypeGroot;
}

#pragma mark - utilitys

- (ACCGrootStickerModel *)grootStickerModelWithInfoSticker:(IESInfoSticker *)infoSticker
                                     interactionStickerModel:(AWEInteractionStickerModel *)interactionStickerModel {

    if (!infoSticker || !interactionStickerModel) {
        return nil;
    }

    if (interactionStickerModel.type != AWEInteractionStickerTypeGroot) {
        return nil;
    }
  
    NSString *draftJsonString = [infoSticker.userinfo acc_stringValueForKey:kGrootStickerUserInfoDraftJsonDataKey];
    if (ACC_isEmptyString(draftJsonString)) {
        AWELogToolError2(@"Grrot", AWELogToolTagEdit, @"recoverSticker failed, draftJsonString is nil.");
        return nil;
    }

    ACCGrootStickerModel *grootStickerModel = [[ACCGrootStickerModel alloc] initWithEffectIdentifier:interactionStickerModel.stickerID];
    [grootStickerModel recoverDataFromDraftJsonString:draftJsonString];

    return grootStickerModel;
}

- (BOOL)machingEditingGrootSticker {
    @weakify(self);
    __block BOOL maching = NO;
    [[self.stickerContainerView stickerViewsWithTypeId:ACCStickerTypeIdGroot] enumerateObjectsUsingBlock:^(ACCStickerViewType  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        @strongify(self);
        if ([[obj contentView] isKindOfClass:[ACCGrootStickerView class]]) {
            ACCGrootStickerView *currentStickerView = (ACCGrootStickerView  *)obj.contentView;
            if (![currentStickerView isFromRecord]) {
                [self editTextStickerView:currentStickerView];
                maching = YES;
            }
            *stop = YES;
        }
    }];
    
    return maching;
}

- (BOOL)hasEditedGrootSticker {
    __block BOOL maching = NO;
    [[self.stickerContainerView stickerViewsWithTypeId:ACCStickerTypeIdGroot] enumerateObjectsUsingBlock:^(ACCStickerViewType  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([[obj contentView] isKindOfClass:[ACCGrootStickerView class]]) {
            *stop = YES;
            maching = YES;
        }
    }];
    return maching;
}

#pragma mark - ACCStickerHandler

- (BOOL)canHandleSticker:(UIView<ACCStickerProtocol> *)sticker {
    return [sticker.contentView isKindOfClass:[ACCGrootStickerView class]];
}

#pragma mark - ACCStickerHandler life cycle
- (void)reset {
    [[self.stickerContainerView stickerViewsWithTypeId:ACCStickerTypeIdGroot] enumerateObjectsUsingBlock:^(ACCStickerViewType  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([[obj contentView] isKindOfClass:[ACCGrootStickerView class]]) {
            if (ACC_FLOAT_GREATER_THAN(0.1, obj.realStartTime)) {
                obj.hidden = NO;
            } else {
                obj.hidden = YES;
            }
        }
    }];

    [self.player removeStickerWithType:ACCEditEmbeddedStickerTypeGroot];
}

- (void)finish {
    // do nothing
}

#pragma mark - ACCStickerMigrationProtocol

+ (BOOL)fillCrossPlatformStickerByUserInfo:(NSDictionary *)userInfo repository:(id<ACCPublishRepository>)sessionModel context:(id<ACCCrossPlatformMigrateContext>)context sticker:(NLESegmentSticker_OC *__autoreleasing *)sticker
{
    if (userInfo.acc_stickerType == ACCEditEmbeddedStickerTypeGroot) {
        NSString *socialStickerUniqueId = [userInfo acc_stringValueForKey:kGrootStickerUserInfoUniqueIdKey];
        if (ACC_isEmptyString(socialStickerUniqueId)) {
            return YES;
        }
        
        AWERepoStickerModel *repoStickerModel = [sessionModel extensionModelOfClass:[AWERepoStickerModel class]];
        AWEInteractionStickerModel *interactionStickerModel = [repoStickerModel.interactionStickers acc_match:^BOOL(AWEInteractionStickerModel * _Nonnull item) {
            return item.trackInfo
            && item.type == AWEInteractionStickerTypeGroot
            && [item.localStickerUniqueId isEqualToString:socialStickerUniqueId];
        }];
        
        if (interactionStickerModel == nil) {
            return YES;
        }
        
        ACCCrossPlatformStickerType stickerType = ACCCrossPlatformStickerTypeGroot;
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
        ACCGrootStickerModel *recoverModel = [[ACCGrootStickerModel alloc] init];
        [recoverModel recoverDataFromDraftJsonString:repoStickerModel.grootModelResult];
        if (!recoverModel.hasGroot) {
            recoverModel.hasGroot = @(NO);
            NSString *grootModelResult = [recoverModel draftDataJsonString];
            sticker_.extraDict[kACCGrootModelResultKey] = grootModelResult;
        } else {
            sticker_.extraDict[kACCGrootModelResultKey] = repoStickerModel.grootModelResult;
        }
        *sticker = sticker_;
        
        return YES;
    }
    return NO;
}

+ (void)updateUserInfo:(NSDictionary *__autoreleasing *)userInfo repoModel:(id<ACCPublishRepository>)sessionModel byCrossPlatformSlot:(nonnull NLETrackSlot_OC *)slot
{
    if (slot.sticker.stickerType == ACCCrossPlatformStickerTypeGroot) {
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
        
        if (interactionStickerModel.type != AWEInteractionStickerTypeGroot) {
            return;
        }
        
        AWERepoStickerModel *repoStickerModel = [sessionModel extensionModelOfClass:[AWERepoStickerModel class]];
        NSMutableArray *interactionStickers = [NSMutableArray array];
        [interactionStickers acc_addObject:interactionStickerModel];
        if (!ACC_isEmptyArray(repoStickerModel.interactionStickers)) {
            [interactionStickers addObjectsFromArray:repoStickerModel.interactionStickers];
        }
        repoStickerModel.interactionStickers = interactionStickers;
        
        NSMutableDictionary *temp_userInfo = [NSMutableDictionary dictionary];
        temp_userInfo.acc_stickerType = ACCEditEmbeddedStickerTypeGroot;
        temp_userInfo[kGrootStickerUserInfoUniqueIdKey] = interactionStickerModel.localStickerUniqueId ?: @"";
        temp_userInfo[ACCStickerDeleteableKey] = [sticker.extraDict acc_objectForKey:ACCStickerDeleteableKey];
        temp_userInfo[ACCStickerEditableKey] = [sticker.extraDict acc_objectForKey:ACCStickerEditableKey];

        // 还原上传至发布的groot识别数据
        ACCGrootStickerModel *grootStickerModel = [[ACCGrootStickerModel alloc] initWithEffectIdentifier:interactionStickerModel.stickerID];
        NSString *jsonString = [sticker.extraDict acc_stringValueForKey:kACCGrootModelResultKey];
        repoStickerModel.grootModelResult = jsonString;
                
        if (sticker.stickerType == ACCCrossPlatformStickerTypeGroot) {
            if (ACC_isEmptyString(jsonString)) {
                AWELogToolError2(@"groot", AWELogToolTagDraft, @"groot sticker Json Convert To Model failed, grootModelResult is null.");
            }
            [grootStickerModel recoverDataFromDraftJsonString:jsonString];
        }
        // sitcker info draft
        temp_userInfo[kGrootStickerUserInfoDraftJsonDataKey] = [grootStickerModel draftDataJsonString];
        
        *userInfo = temp_userInfo;
    }
}

@end
