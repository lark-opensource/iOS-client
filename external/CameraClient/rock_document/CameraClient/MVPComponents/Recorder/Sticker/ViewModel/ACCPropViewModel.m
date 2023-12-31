//
//  ACCPropViewModel.m
//  CameraClient
//
//  Created by chengfei xiao on 2020/4/7.
//

#import "AWERepoPropModel.h"
#import "ACCPropViewModel.h"
#import "ACCTimingManager.h"
#import "ACCStickerGroupedApplyPredicate.h"
#import <CreationKitArch/ACCMusicModelProtocol.h>
#import <CreationKitInfra/ACCGroupedPredicate.h>
#import "IESEffectModel+ACCGuideVideo.h"
#import "AWERepoContextModel.h"
#import "AWERepoTrackModel.h"
#import "AWERepoFlowerTrackModel.h"
#import <CreationKitArch/ACCRecordInformationRepoModel.h>
#import <CreationKitArch/ACCRepoMusicModel.h>
#import <EffectPlatformSDK/IESCategoryModel.h>
#import <CreationKitInfra/IESCategoryModel+AWEAdditions.h>
#import <CreationKitArch/ACCRepoDraftModel.h>
#import <CreationKitArch/ACCRepoVideoInfoModel.h>
#import <CameraClient/ACCRecordViewControllerInputData.h>
#import <CameraClient/AWEVideoFragmentInfo.h>
#import <CameraClient/ACCStudioGlobalConfig.h>
#import <CameraClient/ACCTrackerUtility.h>
#import <CameraClient/ACCStudioLiteRedPacket.h>

@interface ACCPropViewModel()
//ACCEffectApplyProvideProtocol
@property (nonatomic, strong, readwrite) RACSignal *shouldUpdatePickerStickerSignal;
@property (nonatomic, strong, readwrite) RACSignal *applyStickerSignal;
@property (nonatomic, strong, readwrite) RACSignal *willApplyStickerSignal;
@property (nonatomic, strong, readwrite) RACSignal *didApplyLocalStickerSignal;
@property (nonatomic, strong, readwrite) RACSignal *didApplyStickerSignal;
@property (nonatomic, strong, readwrite) RACSignal *didSetCurrentStickerSignal;
@property (nonatomic, strong, readwrite) RACSubject *shouldUpdatePickerStickerSubject;
@property (nonatomic, strong, readwrite) RACSubject *applyStickerSubject;
@property (nonatomic, strong, readwrite) RACSubject *willApplyStickerSubject;
@property (nonatomic, strong, readwrite) RACSubject *didApplyLocalStickerSubject;
@property (nonatomic, strong, readwrite) RACSubject *didApplyStickerSubject;
@property (nonatomic, strong, readwrite) RACSubject *didSetCurrentStickerSubject;

@property (nonatomic, strong, readwrite) IESEffectModel *effectWillApply;
@property (nonatomic, strong, readwrite) IESEffectModel *appliedLocalEffect;
@property (nonatomic, strong, readwrite) IESEffectModel * lastClickedEffectModel;
@property (nonatomic, strong, readwrite) ACCDidApplyEffectPack didApplyEffectPack;
@property (nonatomic, strong, readwrite) ACCRecordSelectEffectPack currentSelectEffectPack;
@property (nonatomic, assign, readwrite) ACCPropPanelDisplayStatus propPanelStatus;

//ACCPropPanelProvideProtocol
@property (nonatomic, strong, readwrite) RACSignal *panelDisplayStatusSignal;
@property (nonatomic, strong, readwrite) RACSignal *selectTabSignal;
@property (nonatomic, strong, readwrite) RACSignal *changeTabSignal;
@property (nonatomic, strong, readwrite) RACSubject *panelDisplayStatusSubject;
@property (nonatomic, strong, readwrite) RACSubject *selectTabSubject;
@property (nonatomic, strong, readwrite) RACSubject *changeTabSubject;
@property (nonatomic, strong, readwrite) RACSubject *didFinishLoadEffectListSubject;

//ACCEffectMusicProvideProtocol
@property (nonatomic, strong, readwrite) RACSignal *pickForceBindMusicSignal;
@property (nonatomic, strong, readwrite) RACSignal *cancelForceBindMusicSignal;
@property (nonatomic, strong, readwrite) RACSubject *pickForceBindMusicSubject;
@property (nonatomic, strong, readwrite) RACSubject *cancelForceBindMusicSubject;

@property (nonatomic, strong, readwrite) ACCPickForceBindMusicPack pickForceBindMusicPack;

//ACCPropViewModel
@property (nonatomic, strong, readwrite) RACSignal *swapCameraForStickerSignal;
@property (nonatomic, strong, readwrite) RACSignal *applyLocalStickerSignal;
@property (nonatomic, strong, readwrite) RACSubject *swapCameraForStickerSubject;
@property (nonatomic, strong, readwrite) RACSubject *applyLocalStickerSubject;
@property (nonatomic, strong, readwrite) RACSubject<ACCPropSelection *> *propSelectionSubject;
@property (nonatomic, strong, readwrite) ACCPropSelection *propSelection;

@property (nonatomic, strong, readwrite) void (^swapCameraBlock)(void);

// track
@property (nonatomic, copy) NSDictionary *trackInfo;

// new prop panel trakcer
@property (nonatomic, strong) IESEffectModel *waitingSticker;
@property (nonatomic, copy) NSDictionary *trackingInfoDictionary;

// tc
@property (nonatomic, strong) NSString *lastGuideEffectIdentifier;

@end


@implementation ACCPropViewModel

@synthesize stickerDataManager = _stickerDataManager;
@synthesize stickerFeatureManager = _stickerFeatureManager;
@synthesize currentSticker = _currentSticker;
@synthesize activityTimerange = _activityTimerange;
@synthesize lastAppliedStickerIdentifier = _lastAppliedStickerIdentifier;
@synthesize musicBubbleStatus = _musicBubbleStatus;
@synthesize currentApplyCompleteSticker = _currentApplyCompleteSticker;
@synthesize groupedPredicate = _groupedPredicate;
@synthesize isSpecialPropForVideoGuide = _isSpecialPropForVideoGuide;
@synthesize shouldFilterProp = _shouldFilterProp;

#pragma mark - Life Cycle

- (void)dealloc
{
    ACCLog(@"%@ dealloc",NSStringFromSelector(_cmd));
    [_shouldUpdatePickerStickerSubject sendCompleted];
    [_applyStickerSubject sendCompleted];
    [_willApplyStickerSubject sendCompleted];
    [_didApplyStickerSubject sendCompleted];
    [_didApplyLocalStickerSubject sendCompleted];
    [_didSetCurrentStickerSubject sendCompleted];
    
    [_panelDisplayStatusSubject sendCompleted];
    [_selectTabSubject sendCompleted];
    [_changeTabSubject sendCompleted];
    [_didFinishLoadEffectListSubject sendCompleted];
    
    [_pickForceBindMusicSubject sendCompleted];
    [_cancelForceBindMusicSubject sendCompleted];
    
    [_swapCameraForStickerSubject sendCompleted];
    [_applyLocalStickerSubject sendCompleted];
    [_propSelectionSubject sendCompleted];
}

#pragma mark - ACCEffectApplyProvideProtocol
- (RACSignal *)applyStickerSignal
{
    return self.applyStickerSubject;
}

- (RACSubject *)applyStickerSubject
{
    if (!_applyStickerSubject) {
        _applyStickerSubject = [RACSubject subject];
    }
    return _applyStickerSubject;
}

- (RACSignal *)shouldUpdatePickerStickerSignal
{
    return self.shouldUpdatePickerStickerSubject;
}

- (RACSubject *)shouldUpdatePickerStickerSubject
{
    if (!_shouldUpdatePickerStickerSubject) {
        _shouldUpdatePickerStickerSubject = [RACSubject subject];
    }
    return _shouldUpdatePickerStickerSubject;
}

- (RACSignal *)willApplyStickerSignal
{
    return self.willApplyStickerSubject;
}

- (RACSubject *)willApplyStickerSubject
{
    if (!_willApplyStickerSubject) {
        _willApplyStickerSubject = [RACSubject subject];
    }
    return _willApplyStickerSubject;
}
- (RACSignal *)didApplyLocalStickerSignal
{
    return self.didApplyLocalStickerSubject;
}

- (RACSubject *)didApplyLocalStickerSubject
{
    if (!_didApplyLocalStickerSubject) {
        _didApplyLocalStickerSubject = [RACSubject subject];
    }
    return _didApplyLocalStickerSubject;
}
- (RACSignal<ACCDidApplyEffectPack> *)didApplyStickerSignal
{
    return self.didApplyStickerSubject;
}

- (RACSubject *)didApplyStickerSubject
{
    if (!_didApplyStickerSubject) {
        _didApplyStickerSubject = [RACSubject subject];
    }
    return _didApplyStickerSubject;
}

- (RACSignal<ACCRecordSelectEffectPack> *)didSetCurrentStickerSignal
{
    return self.didSetCurrentStickerSubject;
}

- (RACSubject *)didSetCurrentStickerSubject
{
    if (!_didSetCurrentStickerSubject) {
        _didSetCurrentStickerSubject = [RACSubject subject];
    }
    return _didSetCurrentStickerSubject;
}

- (void)sendSignal_applySticker:(IESEffectModel *)sticker
{
    [self.applyStickerSubject sendNext:sticker];
}

- (void)sendSignal_shouldUpdatePickerSticker:(IESEffectModel * _Nullable)sticker
{
    [self.shouldUpdatePickerStickerSubject sendNext:sticker];
}

- (void)sendSignal_willApplySticker:(IESEffectModel * _Nullable)sticker
{
    self.effectWillApply = sticker;
    [self.willApplyStickerSubject sendNext:sticker];
}
- (void)sendSignal_didApplyLocalSticker:(IESEffectModel * _Nullable)sticker
{
    self.appliedLocalEffect = sticker;
    [self.didApplyLocalStickerSubject sendNext:sticker];
}
- (void)sendSignal_didApplySticker:(IESEffectModel * _Nullable)sticker success:(BOOL)success
{
    self.didApplyEffectPack = RACTuplePack(sticker,@(success));
    [self.didApplyStickerSubject sendNext:RACTuplePack(sticker,@(success))];
}

- (void)sendSignal_didSetCurrentSticker:(IESEffectModel * _Nullable)sticker oldSticker:(IESEffectModel * _Nullable)oldSticker
{
    self.currentSelectEffectPack = RACTuplePack(sticker,oldSticker);
    BOOL isPanelDismiss = self.propPanelStatus != ACCPropPanelDisplayStatusShow;
    [self.didSetCurrentStickerSubject sendNext:RACTuplePack(sticker,oldSticker,@(isPanelDismiss))];
}

#pragma mark - ACCPropPanelProvideProtocol

- (RACSignal *)panelDisplayStatusSignal
{
    return self.panelDisplayStatusSubject;
}
- (RACSubject *)panelDisplayStatusSubject
{
    if (!_panelDisplayStatusSubject) {
        _panelDisplayStatusSubject = [RACSubject subject];
    }
    return _panelDisplayStatusSubject;
}

- (RACSignal *)selectTabSignal
{
    return self.selectTabSubject;
}
- (RACSubject *)selectTabSubject
{
    if (!_selectTabSubject) {
        _selectTabSubject = [RACSubject subject];
    }
    return _selectTabSubject;
}

- (RACSignal *)changeTabSignal
{
    return self.changeTabSubject;
}
- (RACSubject *)changeTabSubject
{
    if (!_changeTabSubject) {
        _changeTabSubject = [RACSubject subject];
    }
    return _changeTabSubject;
}

- (RACSignal *)didFinishLoadEffectListSignal {
    return self.didFinishLoadEffectListSubject;
}

- (RACSubject *)didFinishLoadEffectListSubject {
    if (!_didFinishLoadEffectListSubject) {
        _didFinishLoadEffectListSubject = [RACSubject subject];
    }
    return _didFinishLoadEffectListSubject;
}

- (void)sendSignal_propPanelDisplayStatus:(ACCPropPanelDisplayStatus)status
{
    [self.panelDisplayStatusSubject sendNext:@(status)];
    self.propPanelStatus = status;
}

- (void)sendSignal_propPanelDidSelectTabAtIndex:(NSInteger)index
{
    [self.selectTabSubject sendNext:@(index)];
}
- (void)sendSignal_propPanelDidTapToChangeTabAtIndex:(NSInteger)index
{
    [self.changeTabSubject sendNext:@(index)];
}

- (void)sendSignal_didFinishLoadEffectListWithFirstHotSticker:(IESEffectModel *)sticker
{
    [self.didFinishLoadEffectListSubject sendNext:sticker];
}

#pragma mark - ACCEffectMusicProvideProtocol

- (RACSignal<ACCPickForceBindMusicPack> *)pickForceBindMusicSignal
{
    return self.pickForceBindMusicSubject;
}
- (RACSubject *)pickForceBindMusicSubject
{
    if (!_pickForceBindMusicSubject) {
        _pickForceBindMusicSubject = [RACSubject subject];
    }
    return _pickForceBindMusicSubject;
}

- (RACSignal *)cancelForceBindMusicSignal
{
    return self.cancelForceBindMusicSubject;
}
- (RACSubject *)cancelForceBindMusicSubject
{
    if (!_cancelForceBindMusicSubject) {
        _cancelForceBindMusicSubject = [RACSubject subject];
    }
    return _cancelForceBindMusicSubject;
}

- (void)sendSignal_didPickForceBindMusic:(id<ACCMusicModelProtocol> _Nullable)musicModel isForceBind:(BOOL)isForceBind error:(NSError * _Nullable)musicError
{
    self.pickForceBindMusicPack = RACTuplePack((NSObject *)musicModel, @(isForceBind), musicError);
    [self.pickForceBindMusicSubject sendNext:RACTuplePack((NSObject *)musicModel, @(isForceBind), musicError)];
}
- (void)sendSignal_didCancelForceBindMusic:(id<ACCMusicModelProtocol> _Nullable)musicModel
{
    [self.cancelForceBindMusicSubject sendNext:musicModel];
}

#pragma mark - ACCEffectProvideProtocol

- (AWEStickerDataManager *)stickerDataManager
{
    return self.stickerFeatureManager.stickerDataManager;
}

- (AWEStickerFeatureManager *)stickerFeatureManager
{
    if (!_stickerFeatureManager) {
        _stickerFeatureManager = [[AWEStickerFeatureManager alloc] initWithPanelType:AWEStickerPanelTypeRecord];
    }
    return _stickerFeatureManager;
}

- (void)setCurrentSticker:(IESEffectModel * _Nullable)currentSticker
{
    _currentSticker = currentSticker;
}

#pragma mark - ACCPropPredicate

- (ACCStickerGroupedApplyPredicate *)groupedPredicate
{
    if (!_groupedPredicate) {
        _groupedPredicate = [[ACCStickerGroupedApplyPredicate alloc] init];
    }
    return _groupedPredicate;
}

#pragma mark - ACCPropViewModel

- (NSMutableArray *)activityTimerange
{
    if (!_activityTimerange) {
        _activityTimerange = [NSMutableArray array];
    }
    return _activityTimerange;
}

- (RACSignal *)swapCameraForStickerSignal
{
    return self.swapCameraForStickerSubject;
}

- (RACSignal *)applyLocalStickerSignal
{
    return self.applyLocalStickerSubject;
}

- (RACSubject *)swapCameraForStickerSubject
{
    if (!_swapCameraForStickerSubject) {
        _swapCameraForStickerSubject = [RACSubject subject];
    }
    return _swapCameraForStickerSubject;
}

- (RACSubject *)applyLocalStickerSubject
{
    if (!_applyLocalStickerSubject) {
        _applyLocalStickerSubject = [RACSubject subject];
    }
    return _applyLocalStickerSubject;
}

- (void)sendSignal_swapCameraForSticker:(void (^)(void))disableBlock
{
    self.swapCameraBlock = disableBlock;
    [self.swapCameraForStickerSubject sendNext:disableBlock];
}

- (RACSignal *)propSelectionSignal
{
    return self.propSelectionSubject;
}

- (RACSubject *)propSelectionSubject
{
    if (!_propSelectionSubject) {
        _propSelectionSubject = [RACSubject subject];
    }
    return _propSelectionSubject;
}

- (void)updatePropSelection:(ACCPropSelection *)selection
{
    _propSelection = selection;
    [self.propSelectionSubject sendNext:selection];
}

- (void)updateLastClickedEffectModel:(nullable IESEffectModel *)effectModel
{
    self.lastClickedEffectModel = effectModel;
}

- (NSInteger)currentDateInteger
{
    NSDate *date = [NSDate date];
    NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
    [outputFormatter setLocale:[NSLocale currentLocale]];
    [outputFormatter setDateFormat:@"YYYYMMDD"];
    return [[outputFormatter stringFromDate:date] integerValue];
}

- (void)resetStickerWithStickerID:(NSString * _Nullable)stickerID forCategory:(IESCategoryModel * _Nullable)category
{
    NSMutableArray<IESEffectModel *> *stickers = [NSMutableArray array];
    NSMutableArray<IESEffectModel *> *otherStickers = [NSMutableArray array];
    for (IESEffectModel *item in category.effects) {
        if ([item.effectIdentifier isEqualToString:stickerID]) {
            [stickers addObject:item];
        } else {
            [otherStickers addObject:item];
        }
    }
    [stickers addObjectsFromArray:otherStickers];
    category.aweStickers = [stickers copy];
}

- (void)insertStickers:(NSArray<IESEffectModel *> * _Nullable)insertStickers forCategory:(IESCategoryModel * _Nullable)category
{
    NSMutableArray<IESEffectModel *> *stickers = [NSMutableArray array];
    NSMutableSet *idSet = [NSMutableSet set];
    
    for (IESEffectModel *item in insertStickers) {
        if (ACC_isEmptyString(item.effectIdentifier)) {
            continue;
        }
        [idSet addObject:item.effectIdentifier];
        [stickers addObject:item];
    }
    
    for (IESEffectModel *item in category.effects) {
        if (![idSet containsObject:item.effectIdentifier]) {
            [idSet addObject:item.effectIdentifier];
            [stickers addObject:item];
        }
    }
    category.aweStickers = [stickers copy];
}

#pragma mark - Tracker

- (void)updateTrackInfo:(NSDictionary *)dict
{
    self.trackInfo = dict;
}

- (void)trackCommerceStickerExperienceDuration:(NSTimeInterval)duration
{
    if (!(duration > 0)) {
        return;
    }
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:@"video_shoot_page" forKey:@"enter_from"];
    [params setObject:(self.inputData.publishModel.repoContext.createId ? : @"") forKey:@"creation_id"];
    [params setObject:(self.inputData.publishModel.repoTrack.referString ? : @"") forKey:@"shoot_way"];
    [params setObject:@((NSInteger)duration) forKey:@"duration"];
    [params setObject:(self.currentApplyCompleteSticker.effectIdentifier ? : @"") forKey:@"prop_id"];
    [ACCTracker() trackEvent:@"prop_click_time" params:[params copy] needStagingFlag:NO];
}

- (void)trackCommerceStickerInfo
{
    // 记录商业化贴纸的试用时长
    NSTimeInterval duration = ACC_TOCK(self.currentApplyCompleteSticker.effectIdentifier);
    [self trackCommerceStickerExperienceDuration:duration];
}

- (void)trackClickRemovePropTab
{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:self.trackInfo];
    [params setValue:@"none" forKey:@"tab_name"];
    params[@"enter_from"] = @"video_shoot_page";
    [ACCTracker() trackEvent:@"click_prop_tab" params:params needStagingFlag:NO];
}

- (void)trackPropSaveWithEffectIdentifier:(NSString *)effectIdentifier
{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:self.trackInfo];
    [params setValue:@"click_main_panel" forKey:@"enter_method"];
    [params setValue:effectIdentifier ?: @"" forKey:@"prop_id"];
    params[@"enter_from"] = @"video_shoot_page";
    [ACCTracker() trackEvent:@"prop_save" params:[params copy] needStagingFlag:NO];
}

- (void)applyLocalSticker:(IESEffectModel *)sticker
{
    if (sticker) {
        NSError *error = nil;
        if ([self.groupedPredicate shouldApplySticker:sticker error:&error]) {
            self.inputData.localSticker = sticker;
        } else {
            [self.applyLocalStickerSubject sendNext:error];
            return;
        }
    }
    [self.applyLocalStickerSubject sendNext:nil];
}

#pragma mark - TC

- (BOOL)shouldShowGuide:(IESEffectModel *)effect
{
    if (effect == nil || effect.acc_guideVideoPath.length == 0) {
        return NO;
    }
    BOOL different = ![effect.effectIdentifier isEqualToString:self.lastGuideEffectIdentifier];
    if (!different) {
        return NO;
    }
    if (effect.effectIdentifier.length > 0) {
        self.lastGuideEffectIdentifier = effect.effectIdentifier;
    }
    
    // seg prop only show once guide
    if (effect.isMultiSegProp) {
        BOOL hasShownMultiSegProp = [ACCCache() boolForKey:@"acc_has_shown_multi_seg_prop_guide"];
        if (!hasShownMultiSegProp) {
            [ACCCache() setBool:YES forKey:@"acc_has_shown_multi_seg_prop_guide"];
            return YES;
        }
        return NO;
    }
    NSNumber *shouldShowGuide = NULL;
    if ([self.isSpecialPropForVideoGuide evaluateWithObject:effect output:&shouldShowGuide] &&
        shouldShowGuide != NULL) {
        return [shouldShowGuide boolValue];
    }
    
    BOOL sameEffectInFragment = NO;
    for (AWEVideoFragmentInfo *info in self.inputData.publishModel.repoVideoInfo.fragmentInfo.copy) {
        if (!sameEffectInFragment && [info.stickerId isEqualToString:effect.effectIdentifier]) {
            sameEffectInFragment = YES;
        }
    }
    
    // 前面拍摄过相同道具的视频片段，不需要再显示引导视频
    if (sameEffectInFragment) {
        return NO;
    }
    
    BOOL show = NO;
    NSInteger guideVideoThresholdCount = [effect guideVideoThresholdCount];
    NSString *key = [self guideVideoCacheKey:effect];
    NSInteger cacheCount = [ACCCache() integerForKey:key];
    if (guideVideoThresholdCount > cacheCount) {
        show = YES;
    }
    
    return show;
}

- (void)updateShowGuideCount:(IESEffectModel *)effect
{
    NSString *key = [self guideVideoCacheKey:effect];
    NSInteger cacheCount = [ACCCache() integerForKey:key];
    [ACCCache() setInteger:cacheCount+1 forKey:key];
}

- (NSString *)guideVideoCacheKey:(IESEffectModel *)effect
{
    return [NSString stringWithFormat:@"prop_%@", effect.acc_guideVideoPath];
}

- (void)trackGuideShowWithEffectId:(NSString *)effectId
{
    NSDictionary *params = @{
        @"creation_id" : self.inputData.publishModel.repoContext.createId ?: @"",
        @"prop_id" : effectId ?: @"",
        @"enter_from" : @"video_shoot_page",
        @"shoot_way" :  self.inputData.publishModel.repoTrack.referString ?: @"",
    };
    [ACCTracker() trackEvent:@"prop_tutorial_show"
                      params:params
             needStagingFlag:NO];
}

- (void)trackGuideSkipWithEffectId:(NSString *)effectId
{
    NSDictionary *params = @{
        @"creation_id" : self.inputData.publishModel.repoContext.createId ?: @"",
        @"prop_id" : effectId ?: @"",
        @"enter_from" : @"video_shoot_page",
        @"shoot_way" :  self.inputData.publishModel.repoTrack.referString ?: @"",
    };
    [ACCTracker() trackEvent:@"prop_tutorial_video_skip"
                      params:params
             needStagingFlag:NO];
}

#pragma mark - new prop panel tracker

- (void)trackPropClickEventWithCameraService:(id<ACCCameraService>)cameraService
                                     sticker:(IESEffectModel *)sticker
                                categoryName:(NSString *)categoryName
                                 atIndexPath:(NSIndexPath *)indexPath
                                 isPhotoMode:(BOOL)isPhotoMode
                                 isThemeMode:(BOOL)isThemeMode
                            additionalParams:(NSMutableDictionary *)additionalParams;
{
    [ACCTracker() trackEvent:@"prop"
                       label:@"click"
                       value:sticker.effectIdentifier ? : @""
                       extra:nil
                  attributes:@{@"position" : @"shoot_page",
                               @"is_photo" : isPhotoMode ? @1 : @0,
                  }];

    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:self.trackingInfoDictionary];
    params[@"enter_method"] = [self.inputData.publishModel.repoContext isLitePropEnterMethod] ? @"redpacket_auto" :@"click_main_panel";
    params[@"prop_id"] = sticker.effectIdentifier ?: @"";
    params[@"prop_index"] = sticker.gradeKey ?: @"";
    params[@"enter_from"] = @"video_shoot_page";
    params[@"tab_name"] = categoryName;
    params[@"impr_position"] = @(indexPath.row + 1).stringValue;
    params[@"prop_tab_order"] = @(indexPath.section).stringValue;
    params[@"prop_rec_id"] = ACC_isEmptyString(sticker.recId) ? @"0": sticker.recId;
    params[@"prop_selected_from"] = ACC_isEmptyString(categoryName) ? @"" : [NSString stringWithFormat:@"prop_panel_%@", categoryName];
    NSString *fromPropID = self.inputData.publishModel.repoProp.localPropId;
    if (!ACC_isEmptyString(fromPropID)) {
        params[@"from_prop_id"] = fromPropID;
        BOOL isDefaultProp = [sticker.effectIdentifier isEqualToString:fromPropID];
        params[@"is_default_prop"] = isDefaultProp ? @"1" : @"0";
    }

    AVCaptureDevicePosition cameraPostion = cameraService.cameraControl.currentCameraPosition;
    params[@"camera_direction"] = ACCDevicePositionStringify(cameraPostion);
    params[@"staus"] = self.repository.repoTrack.enterStatus?:@"";
    [params addEntriesFromDictionary:additionalParams];
    
    if (isThemeMode) {
        params[@"enter_from"] = @"concept_shoot_page";
        params[@"concept_name"] = categoryName;
    }
    
    [ACCTracker() trackEvent:@"prop_click" params:params needStagingFlag:NO];
}

- (void)trackPropShowEventWithSticker:(IESEffectModel *)sticker
                         categoryName:(NSString *)categoryName
                          atIndexPath:(NSIndexPath *)indexPath
                          isPhotoMode:(BOOL)isPhotoMode
                     additionalParams:(NSMutableDictionary *)additionalParams
{
    NSDictionary *attributes = @{
        @"is_photo" : isPhotoMode ? @1 : @0,
        @"position" : @"shoot_page",
    };
    [ACCTracker() trackEvent:@"prop"
                       label:@"show"
                       value:sticker.effectIdentifier ?: @""
                       extra:nil
                  attributes:attributes];

    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:self.trackingInfoDictionary];
    params[@"enter_method"] = [self.inputData.publishModel.repoContext isLitePropEnterMethod] ? @"redpacket_auto" : @"click_main_panel";
    params[@"prop_id"] = sticker.effectIdentifier ?: @"";
    params[@"prop_index"] = sticker.gradeKey ?: @"";
    params[@"tab_name"] = categoryName;
    params[@"impr_position"] = @(indexPath.item + 1).stringValue;
    params[@"prop_rec_id"] = ACC_isEmptyString(sticker.recId) ? @"0": sticker.recId;
    NSString *fromPropID = self.inputData.publishModel.repoProp.localPropId;
    if (!ACC_isEmptyString(fromPropID)) {
        params[@"from_prop_id"] = fromPropID;
    }
    NSString *musicID = self.inputData.publishModel.repoMusic.music.musicID;
    if (!ACC_isEmptyString(musicID)) {
        params[@"music_id"] = musicID;
    }

    [params addEntriesFromDictionary:additionalParams];
    [ACCTracker() trackEvent:@"prop_show" params:params needStagingFlag:NO];
}

- (void)trackClickPropTabEventWithCategoryName:(NSString *)categoryName
                                         value:(NSString *)value
                                   isPhotoMode:(BOOL)isPhotoMode
                                   isThemeMode:(BOOL)isThemeMode
{
    if (self.inputData.publishModel.repoFlowerTrack.fromFlowerCamera) {
        // 春节tab不上报click_prop_tab
        return;
    }
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:self.trackingInfoDictionary];
    params[@"tab_name"] = categoryName;
    params[@"enter_from"] = @"video_shoot_page";
    if (![categoryName isEqualToString:@"none"]) {
        [ACCTracker() trackEvent:@"click_prop_tab"
                           label:@"prop"
                           value:value
                           extra:nil
                      attributes:@{@"position": @"shoot_page",
                                   @"is_photo": isPhotoMode ? @1 : @0,
                                }];
    }
    if (self.inputData.publishModel.repoTrack.schemaTrackParams) {
        [params addEntriesFromDictionary:self.inputData.publishModel.repoTrack.schemaTrackParams];
    }
    
    if (isThemeMode) {
        params[@"enter_from"] = @"concept_shoot_page";
        NSDictionary *liteParams = [ACCStudioLiteRedPacket() enterVideoEditPageParams:self.inputData.publishModel];
        if (liteParams) {
            [params addEntriesFromDictionary:liteParams];
        }
    }
    
    [ACCTracker() trackEvent:@"click_prop_tab" params:params needStagingFlag:NO];
}

- (void)p_trackDownloadUserViewPerformanceWithSticker:(IESEffectModel *)sticker
                                             duration:(NSInteger)duration
                                               status:(NSNumber *)status
                                             hitCache:(BOOL)hitCache
                                                error:(NSError *)error
{
    NSMutableDictionary *params = [@{@"resource_type" : @"effect",
                                     @"resource_id" : sticker.effectIdentifier ?: @"",
                                     @"duration" : @(duration),
                                     @"status" : status,
                                     @"hit_cache" : hitCache ? @(1) : @(0)} mutableCopy];
    if (error != nil) {
        params[@"error_domain"] = error.domain ?: @"";
        params[@"error_code"] = @(error.code);
        AWELogToolError(AWELogToolTagRecord, @"p_trackDownloadUserViewPerformanceWithSticker %@", error);
    }
    [params addEntriesFromDictionary:self.inputData.publishModel.repoTrack.commonTrackInfoDic ?: @{}];
    [ACCTracker() trackEvent:@"tool_performance_resource_download_user_view"
                      params:params.copy
             needStagingFlag:NO];
}

- (void)trackWillApplySticker:(IESEffectModel *)sticker
{
    if (!self.waitingSticker) {
        return;
    }
    self.waitingSticker = nil;

    NSInteger duration = [ACCMonitor() timeIntervalForKey:@"sticker_loading_duration_user_view"];

    if (duration > 0) {
        [ACCMonitor() cancelTimingForKey:@"sticker_loading_duration_user_view"];

        [self p_trackDownloadUserViewPerformanceWithSticker:sticker
                                                   duration:duration
                                                     status:@(0)
                                                   hitCache:NO
                                                      error:nil];
    }
}

- (void)trackUserCancelUseSticker
{
    if (self.waitingSticker != nil) {
        NSInteger duration = [ACCMonitor() timeIntervalForKey:@"sticker_loading_duration_user_view"];

        if (duration > 0) {
            [ACCMonitor() cancelTimingForKey:@"sticker_loading_duration_user_view"];

            [self p_trackDownloadUserViewPerformanceWithSticker:self.waitingSticker
                                                       duration:duration
                                                         status:@(2)
                                                       hitCache:NO
                                                          error:nil];
        }
        self.waitingSticker = nil;
    }
}

- (void)trackUserDidTapSticker:(IESEffectModel *)sticker
{
    if ([sticker.effectIdentifier isEqual:self.waitingSticker.effectIdentifier]) {
        return ;
    }

    [self trackUserCancelUseSticker]; //前一个道具还未成功处理，记为取消

    if (sticker.downloaded) {
        [self p_trackDownloadUserViewPerformanceWithSticker:sticker
                                                   duration:0
                                                     status:@(0)
                                                   hitCache:YES
                                                      error:nil];
    } else {
        self.waitingSticker = sticker;
        [ACCMonitor() startTimingForKey:@"sticker_loading_duration_user_view"];
    }
}

- (void)trackDidFailedDownloadSticker:(IESEffectModel *)sticker withError:(NSError *)error
{
    if (!self.waitingSticker) {
        return;
    }
    self.waitingSticker = nil;

    NSInteger duration = [ACCMonitor() timeIntervalForKey:@"sticker_loading_duration_user_view"];

    if (duration > 0) {
        [ACCMonitor() cancelTimingForKey:@"sticker_loading_duration_user_view"];

        [self p_trackDownloadUserViewPerformanceWithSticker:sticker
                                                   duration:duration
                                                     status:@(1)
                                                   hitCache:NO
                                                      error:error];
    }
}

- (void)trackDownloadPerformanceWithSticker:(IESEffectModel *)sticker startTime:(CFTimeInterval)startTime success:(BOOL)success error:(NSError *)error
{
    AWEVideoPublishViewModel *publishModel = self.inputData.publishModel;

    NSInteger duration = (CACurrentMediaTime() - startTime) * 1000;
    NSMutableDictionary *params = [@{@"resource_type": @"effect",
                                     @"resource_id": sticker.effectIdentifier?:@"",
                                     @"duration": @(duration),
                                     @"status": @(success ? 0 : 1),
                                     @"error_domain": error.domain ?: @"",
                                     @"error_code": @(error.code),
                                     @"shoot_way": publishModel.repoTrack.referString ?: @""} mutableCopy];
    if (publishModel) {
        [params addEntriesFromDictionary:publishModel.repoTrack.commonTrackInfoDic ?: @{}];
    }
    [ACCTracker() trackEvent:@"tool_performance_resource_download"
                      params:params
             needStagingFlag:NO];
}

- (void)trackStickerPanelLoadPerformanceWithStatus:(NSInteger)status
                                         isLoading:(BOOL)isLoading
                                   dismissTrackStr:(NSString *)dismissTrackStr
{
    //性能打点，道具面板加载耗时
    NSInteger panel_loading_duration = [ACCMonitor() timeIntervalForKey:@"sticker_panel_loading_duration"];

    if (panel_loading_duration <= 0) {
        return;
    }

    if (status == 0 && isLoading) {
        return;
    }

    [self monitorCancelStickerPanelLoadingDuration];

    NSMutableDictionary *params = [@{@"duration": @(panel_loading_duration),
                                     @"status": @(status)} mutableCopy];
    [params addEntriesFromDictionary:self.inputData.publishModel.repoTrack.commonTrackInfoDic ?: @{}];

    if (status == 2) {
        [params addEntriesFromDictionary:@{@"dismiss" : dismissTrackStr ?: @""}];
    }
    
    // saf test add metric
    if ([IESAutoInline(ACCBaseServiceProvider(), ACCENVProtocol) currentEnv] == ACCENVSaf) {
        NSMutableDictionary *metricExtra = @{}.mutableCopy;
        UInt64 end_time = (UInt64)([[NSDate date] timeIntervalSince1970] * 1000);
        UInt64 start_time = end_time - (UInt64)(panel_loading_duration);
        [metricExtra addEntriesFromDictionary:@{@"metric_name": @"duration", @"start_time": @(start_time), @"end_time": @(end_time)}];
        params[@"metric_extra"] = @[metricExtra];
    }
    [ACCTracker() trackEvent:@"tool_performance_enter_prop_tab" params:params.copy needStagingFlag:NO];
}

- (void)trackToolPerformanceAPIWithType:(NSString *)type
                               duration:(CFTimeInterval)duration
                                  error:(NSError *)error
{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{@"api_type": type,
                                                                                  @"duration": @(duration)}];
    if (error != nil) {
        params[@"status"] = @(1);
        params[@"error_domain"] = error.domain ?: @"";
        params[@"error_code"] = @(error.code);
        AWELogToolError(AWELogToolTagRecord, @"trackToolPerformanceAPIWithType: %@", error);
    } else {
        params[@"status"] = @(0);
    }
    [params addEntriesFromDictionary:self.trackingInfoDictionary ?: @{}];
    [ACCTracker() trackEvent:@"tool_performance_api"
                      params:params.copy
             needStagingFlag:NO];
}

- (void)trackComfirmPropSettingEvent
{
    [ACCTracker() trackEvent:@"comfirm_prop_setting"
                       label:@"shoot_page"
                       value:nil
                       extra:nil
                  attributes:self.inputData.publishModel.repoTrack.referExtra];
}

- (void)trackSearchWithEventName:(NSString *)eventName params:(NSMutableDictionary *)params
{
    AWEVideoPublishViewModel *publishModel = self.inputData.publishModel;
    NSMutableDictionary *additionals = @{
        @"creation_id" : publishModel.repoContext.createId ?: @"",
        @"shoot_way" : publishModel.repoTrack.referString ?: @"",
        @"enter_from" : @"video_shoot_page"
    }.mutableCopy;

    if ([eventName isEqualToString:@"click_prop_search_icon"]) {
        additionals[@"music_id"] = publishModel.repoMusic.music.musicID ?: @"";
    }
    [params addEntriesFromDictionary:additionals];
    [ACCTracker() trackEvent:eventName params:params];
}

- (NSDictionary *)trackingInfoDictionary
{
    if (_trackingInfoDictionary == nil) {
        AWEVideoPublishViewModel *publishModel = self.inputData.publishModel;
        _trackingInfoDictionary = @{
            @"creation_id" : publishModel.repoContext.createId ?: @"",
            @"shoot_way" : publishModel.repoTrack.referString ?: @"",
            @"draft_id" : @(publishModel.repoDraft.editFrequency).stringValue ?: @"",
            @"enter_from" : @"video_shoot_page",
            @"group_id" : self.inputData.groupID ?: @"",
        };
    }

    return _trackingInfoDictionary;
}

#pragma mark - new prop panel monitor

- (void)monitorStartStickerPanelLoadingDuration
{
    [ACCMonitor() startTimingForKey:@"sticker_panel_loading_duration"]; //性能打点，道具面板加载耗时开始计时
}

- (void)monitorCancelStickerPanelLoadingDuration
{
    [ACCMonitor() cancelTimingForKey:@"sticker_panel_loading_duration"];
}

- (void)monitorTrackServiceEffectListError:(NSError *)error
                                 panelName:(NSString *)panelName
                                  duration:(NSNumber *)duration
                                needUpdate:(BOOL)needUpdate
{
    NSMutableDictionary *extra = [NSMutableDictionary dictionaryWithDictionary:@{@"panel": panelName,
                                                                                 @"panelType": @(AWEStickerPanelTypeRecord),
                                                                                 @"abParam": @(ACCConfigInt(kConfigInt_platform_optimize_strategy)),
                                                                                 @"needUpdate": @(needUpdate)}];
    if (error != nil) {
        extra[@"errorDesc"] = error.description ?: @"";
        extra[@"errorCode"] = @(error.code);
    } else {
        extra[@"duration"] = duration;
    }
    [ACCMonitor() trackService:@"aweme_effect_list_error"
                        status:(error != nil) ? 1 : 0
                         extra:extra];
}

- (ACCGroupedPredicate<IESEffectModel *,NSNumber *> *)isSpecialPropForVideoGuide
{
    if (_isSpecialPropForVideoGuide == nil) {
        _isSpecialPropForVideoGuide = [[ACCGroupedPredicate alloc] initWithOperand:(ACCGroupedPredicateOperandOr)];
    }
    return _isSpecialPropForVideoGuide;
}

- (ACCGroupedPredicate<IESEffectModel *,id> *)shouldFilterProp
{
    if (_shouldFilterProp == nil) {
        _shouldFilterProp = [[ACCGroupedPredicate alloc] initWithOperand:(ACCGroupedPredicateOperandOr)];
    }
    return _shouldFilterProp;
}

- (BOOL)shouldFilterStickePickerCallback
{
    return NO;
}

@end
