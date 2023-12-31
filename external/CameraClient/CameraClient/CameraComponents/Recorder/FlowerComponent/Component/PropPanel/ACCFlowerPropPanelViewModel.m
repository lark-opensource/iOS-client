//
//  ACCFlowerPropPanelViewModel.m
//  CameraClient-Pods-AwemeCore
//
//  Created by bytedance on 2021/11/14.
//

#import "ACCFlowerPropPanelViewModel.h"

#import <CreativeKit/ACCNetServiceProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import "ACCFlowerCampaignManagerProtocol.h"
#import "AWEStickerDownloadManager.h"
#import <EffectPlatformSDK/EffectPlatform.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import "IESEffectModel+DStickerAddditions.h"
#import "ACCRecordPropService.h"
#import "ACCFlowerService.h"
#import "AWERepoTrackModel.h"
#import "AWERepoContextModel.h"
#import "ACCTrackerUtility.h"
#import <CreationKitInfra/ACCToastProtocol.h>
#import <CreativeKit/ACCCacheProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreationKitRTProtocol/ACCCameraService.h>
#import <CreativeKit/ACCMonitorProtocol.h>
#import "AWERepoFlowerTrackModel.h"

NSInteger const kACCFlowerPanelIndexInvalid = -1;

ACCFlowerItemType ACCFlowerItemTypeRecognition = @"recognition";
ACCFlowerItemType ACCFlowerItemTypeScan = @"scan";
ACCFlowerItemType ACCFlowerItemTypePhoto = @"photo";
ACCFlowerItemType ACCFlowerItemTypeProp = @"prop";

@interface ACCFlowerPropPanelViewModel () <AWEStickerDownloadObserverProtocol, ACCFlowerServiceSubscriber>

@property (nonatomic, copy) NSArray<ACCFlowerPanelEffectModel *> *prefetchedItems;
@property (nonatomic, copy, readwrite) NSArray<ACCFlowerPanelEffectModel *> *items;
@property (nonatomic, copy, readwrite) NSArray<ACCFlowerPanelEffectModel *> *reloadedItems;
@property (nonatomic, strong) NSDateFormatter *awardHintDateFormatter;

// flower shoot prop
@property (nonatomic, copy, readwrite) NSArray<IESEffectModel *> *shootProps;
@property (nonatomic, assign) BOOL shootPropLoaded;

@property (nonatomic, copy) NSString *enterFlowerTabMethod;
@property (nonatomic, assign) CFTimeInterval loadStartTime;

/**
 * [index, progress] or [index, error];
 */
@property (nonatomic, copy, readwrite) NSArray<NSNumber *> *downloadProgressPack; // [0] = index, [1] = download progress

@end

@implementation ACCFlowerPropPanelViewModel

@synthesize selectedItem = _selectedItem;

+ (BOOL)automaticallyNotifiesObserversOfSelectedIndex
{
    return NO;
}

+ (BOOL)automaticallyNotifiesObserversOfSelectedItem
{
    return NO;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _selectedIndex = -1;
        _targetIndexUnderLuckyCardStage = 0;
    }
    return self;
}

- (NSDateFormatter *)awardHintDateFormatter
{
    if(!_awardHintDateFormatter){
        _awardHintDateFormatter = [[NSDateFormatter alloc] init];
        [_awardHintDateFormatter setDateFormat:@"yyyy-MM-dd"];
    }
    return _awardHintDateFormatter;
}

- (BOOL)hasRequestDailyRewardToday
{
    NSString *requestToken = [NSString stringWithFormat:@"%@-%@", [ACCFlowerCampaignManager() activityHashString], [self.awardHintDateFormatter stringFromDate:[NSDate date]]];

    if(ACC_isEmptyString(requestToken)) {
        return YES;
    }
    
    return [ACCCache() boolForKey:requestToken];
}

- (void)insertItem:(ACCFlowerPanelEffectModel *)item atIndex:(NSInteger)index
{
    NSMutableArray *items = [self.items mutableCopy];
    [items acc_insertObject:item atIndex:index];
    self.items = items;
}

#pragma mark - Fetch 各种 Data

// 进入春节tab时拉取道具 & 更新 viewModel
- (void)fetchFlowerPropDataWithCompletion:(dispatch_block_t)completion
{
    if (!ACC_isEmptyArray(self.items)) {
        ACCBLOCK_INVOKE(completion);
        return;
    }
    @weakify(self);
    void(^fetchEffectModelCompletion)(NSArray<ACCFlowerPanelEffectModel *> *) = ^(NSArray<ACCFlowerPanelEffectModel *> * models) {
        @strongify(self);
        self.items = models;
        ACCBLOCK_INVOKE(completion);
    };
    if (!ACC_isEmptyArray(self.prefetchedItems)) {
        ACCBLOCK_INVOKE(fetchEffectModelCompletion, self.prefetchedItems);
        return;
    }
    [self fetchFlowerPanelEffectModelWithCompletion:fetchEffectModelCompletion];
}

// 拉取春节道具面板 Model
- (void)fetchFlowerPanelEffectModelWithCompletion:(void(^)(NSArray<ACCFlowerPanelEffectModel *> *))completion
{
    @weakify(self);
    if ([ACCFlowerCampaignManager() getCurrentActivityStage] == ACCFLOActivityStageTypeAppointment) {
        [IESAutoInline(ACCBaseServiceProvider(), ACCNetServiceProtocol) requestWithModel:^(ACCRequestModel * _Nullable requestModel) {
            requestModel.objectClass = [ACCFlowerPanelPreCampainEffectListModel class];
            requestModel.urlString = [NSString stringWithFormat:@"%@/aweme/ug/flower/effect/reserve/", [ACCFlowerCampaignManager() activityServiceDomain]];
        }  completion:^(ACCFlowerPanelPreCampainEffectListModel * _Nullable model, NSError * _Nullable error) {
            @strongify(self);
            [self fetchEffectListWithFlowerEffectModel:model.effectList completion:completion];
        }];
    } else if ([ACCFlowerCampaignManager() getCurrentActivityStage] > ACCFLOActivityStageTypeAppointment) {
        CFTimeInterval startTime = CFAbsoluteTimeGetCurrent();
        [IESAutoInline(ACCBaseServiceProvider(), ACCNetServiceProtocol) requestWithModel:^(ACCRequestModel * _Nullable requestModel) {
            requestModel.objectClass = [ACCFlowerPanelEffectListModel class];
            requestModel.urlString = [NSString stringWithFormat:@"%@/aweme/ug/flower/effect/shoot/", [ACCFlowerCampaignManager() activityServiceDomain]];
        } completion:^(ACCFlowerPanelEffectListModel * _Nullable model, NSError * _Nullable error) {
            @strongify(self);
            //集卡期默认Landing到主推道具
            self.targetIndexUnderLuckyCardStage = model.leftList.count;
            [self fetchEffectListWithFlowerEffectModel:[model.leftList arrayByAddingObjectsFromArray:model.rightList] completion:completion];
            // flower monitor
            [self trackForFlowerPropListRequest:startTime error:error];
        }];
    }
}

// 根据春节道具Model 拉取对应的 IESEffectModel
- (void)fetchEffectListWithFlowerEffectModel:(NSArray<ACCFlowerPanelEffectModel *> *)flowerModels completion:(void(^)(NSArray<ACCFlowerPanelEffectModel *> *))completion
{
    // 拉取flower拍照道具面板数据
    [self loadFlowerShootPropDataIfNeed:flowerModels];
    NSArray<NSString *> *effectIDs = [flowerModels acc_map:^id _Nonnull(ACCFlowerPanelEffectModel * _Nonnull obj) {
        return obj.effectID ?: @"";
    }];
    if (ACC_isEmptyArray(effectIDs)) {
        ACCBLOCK_INVOKE(completion, @[]);
        return;
    }
    CFTimeInterval startTime = CFAbsoluteTimeGetCurrent();
    [EffectPlatform fetchEffectListWithEffectIDS:effectIDs completion:^(NSError * _Nullable error, NSArray<IESEffectModel *> * _Nullable effects, NSArray<IESEffectModel *> * _Nullable bindEffects) {
        // flower monitor
        [self trackForFlowerSlidePropListLoad:startTime error:error];
        
        NSMutableArray<ACCFlowerPanelEffectModel *> *filterdModels = [NSMutableArray array];
        NSInteger i = 0, j = 0;
        for (; i < effectIDs.count && j < effects.count; ) {
            NSString *effectID = [effectIDs acc_objectAtIndex:i];
            IESEffectModel *effectModel = [effects acc_objectAtIndex:j];
            if ([effectID isEqualToString:effectModel.originalEffectID]) {
                ACCFlowerPanelEffectModel *panelModel = [flowerModels acc_objectAtIndex:i];
                panelModel.effectID = effectModel.effectIdentifier;
                panelModel.effect = effectModel;
                effectModel.panelName = @"flower";
                effectModel.propSelectedFrom = @"flower";
                [filterdModels addObject:panelModel];
                i++;
                j++;
            } else {
                i++;
            }
        }
        ACCBLOCK_INVOKE(completion, [filterdModels copy]);
    }];
}

- (void)loadFlowerShootPropDataIfNeed:(NSArray<ACCFlowerPanelEffectModel *> *)flowerModels
{
    self.shootPropLoaded = NO;
    __block NSString *panelName = @"";
    __block NSString *categoryName = @"";
    [flowerModels enumerateObjectsUsingBlock:^(ACCFlowerPanelEffectModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.dType == ACCFlowerEffectTypePhoto) {
            NSDictionary *propExtraDic = [obj flowerPhotoPropEffectPanelInfo];
            panelName = [propExtraDic acc_stringValueForKey:@"flower_photo_panel_name"];
            categoryName = [propExtraDic acc_stringValueForKey:@"flower_photo_category_name"];
            *stop = YES;
        }
    }];
    
    @weakify(self);
    [EffectPlatform checkEffectUpdateWithPanel:panelName category:categoryName completion:^(BOOL needUpdate) {
        @strongify(self);
        IESEffectPlatformNewResponseModel *cachedResponse = [EffectPlatform cachedEffectsOfPanel:panelName category:categoryName];
        if (needUpdate || cachedResponse.effectsMap.allValues.count <= 0) {
            CFTimeInterval startTime = CFAbsoluteTimeGetCurrent();
            [EffectPlatform downloadEffectListWithPanel:panelName category:categoryName pageCount:0 cursor:0 sortingPosition:0 completion:^(NSError * _Nullable error, IESEffectPlatformNewResponseModel * _Nullable response) {
                @strongify(self);
                if (error || !response || response.effectsMap.allValues.count == 0) {
                    ACCLog(@"flower shoot prop fetch error:%@, effects count: %ld", error, response.effectsMap.allValues.count);
                } else {
                    self.shootProps = response.categoryEffects.effects;
                }
                [self trackForFlowerPhotoPropListLoad:startTime error:error];
            }];
        } else {
            self.shootProps = cachedResponse.categoryEffects.effects;
        }
    }];
}

// 拉取每日三张卡奖励
- (void)fetchDailyRewardIfNeededWithCompletion:(void (^)(NSError *_Nullable error,
                                                         ACCFlowerRewardResponse *_Nonnull result,
                                                         NSString *_Nullable showSchema))completion
{
    if ([ACCFlowerCampaignManager() getCurrentActivityStage] != ACCFLOActivityStageTypeLuckyCard) {
        return;
    }
    
    if(![self hasRequestDailyRewardToday]){
        @weakify(self);
        ACCFlowerRewardRequest *rewardRequest = [ACCFlowerRewardRequest requestWithEnterFrom:@"daily_first"
                                                                                 schemaScene:ACCFLOSceneNpcDispatchCard stickerId:nil];
        [ACCFlowerCampaignManager() requestFlowerActivityAwardWithInput:rewardRequest
                                                           completion:^(NSError * _Nullable error,
                                                                        ACCFlowerRewardResponse * _Nonnull result,
                                                                        NSString * _Nullable showSchema) {
            @strongify(self);
            
            NSString *requestToken =
            [NSString stringWithFormat:@"%@-%@",[ACCFlowerCampaignManager() activityHashString],
                                                [self.awardHintDateFormatter stringFromDate:[NSDate date]]];
            [ACCCache() setBool:YES forKey:requestToken];
            if(!error && result!=nil){
                ACCBLOCK_INVOKE(completion, error, result, [ACCFlowerCampaignManager() flowerSchemaWithSceneName:ACCFLOSceneNpcDispatchCard]);
            }
        }];
    }
}

#pragma mark - AWEStickerDownloadObserverProtocol

- (void)stickerDownloadManager:(AWEStickerDownloadManager *)manager sticker:(IESEffectModel *)effect downloadProgressChange:(CGFloat)progress
{
    if ([effect.effectIdentifier isEqualToString:self.selectedItem.effect.effectIdentifier]) {
        self.downloadProgressPack = @[@(self.selectedIndex), @(progress)];
    }
}

- (void)stickerDownloadManager:(AWEStickerDownloadManager *)manager didFinishDownloadSticker:(IESEffectModel *)effect
{
    if ([effect.effectIdentifier isEqualToString:self.selectedItem.effect.effectIdentifier]) {
        self.downloadProgressPack = @[@(self.selectedIndex), @(1)];
        [self trackForFlowerPropDownload:self.loadStartTime flowerPropType:2 error:nil];
        if (![self.flowerService isShowingLynxWindow]) {
            [self.propService applyProp:effect propSource:ACCPropSourceFlower];
        }
    }
}

- (void)stickerDownloadManager:(AWEStickerDownloadManager *)manager didFailDownloadSticker:(IESEffectModel *)effect withError:(NSError *)error
{
    if ([effect.effectIdentifier isEqualToString:self.selectedItem.effect.effectIdentifier]) {
        self.downloadProgressPack = @[@(self.selectedIndex), error ?: [NSError errorWithDomain:NSNetServicesErrorDomain code:-1 userInfo:nil]];
        [ACCToast() show:@"道具下载失败"];
        [self trackForFlowerPropDownload:self.loadStartTime flowerPropType:2 error:error];
        if (error) {
            ACCLog(@"sticker download error:%@", error);
        }
    }
}

#pragma mark - ACCFlowerServiceSubscriber

- (void)flowerServiceDidEnterFlowerMode:(id<ACCFlowerService>)servicee
{
    [self.propService applyProp:nil propSource:ACCPropSourceFlower];
    [[AWEStickerDownloadManager manager] addObserver:self];
}

- (void)flowerServiceDidLeaveFlowerMode:(id<ACCFlowerService>)service
{
    [[AWEStickerDownloadManager manager] removeObserver:self];
    [self.propService applyProp:nil propSource:ACCPropSourceFlower];
}

// 进入拍摄页时预加载资源
- (void)flowerServiceDidReceivePrefetchRequest:(id<ACCFlowerService>)flowerService
{
    @weakify(self);
    [self fetchFlowerPanelEffectModelWithCompletion:^(NSArray<ACCFlowerPanelEffectModel *> *items) {
        @strongify(self);
        self.prefetchedItems = items;
    }];
}

- (void)flowerServiceDidOpenTaskPanel:(id<ACCFlowerService>)service
{
    if (self.selectedItem.dType == ACCFlowerEffectTypeProp) {
        [self.propService applyProp:nil propSource:ACCPropSourceFlower];
    }
}

- (void)flowerServiceDidCloseTaskPanel:(id<ACCFlowerService>)service
{
    if (self.selectedItem.dType == ACCFlowerEffectTypeProp && self.selectedItem.effect.downloaded) {
        [self.propService applyProp:self.selectedItem.effect propSource:ACCPropSourceFlower];
    }
}

#pragma mark - Utils

- (NSInteger)itemIndexForFlowerItem:(NSString *)flowerItem
{
    if (ACC_isEmptyString(flowerItem)) {
        return kACCFlowerPanelIndexInvalid;
    }
    
    ACCFlowerEffectType targetType = [self effectTypeFromItemType:flowerItem];
    __block NSInteger targetIndex = kACCFlowerPanelIndexInvalid;
    [self.items enumerateObjectsUsingBlock:^(ACCFlowerPanelEffectModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.dType == targetType) {
            targetIndex = idx;
            *stop = YES;
        }
    }];
    return targetIndex;
}

- (ACCFlowerEffectType)effectTypeFromItemType:(ACCFlowerItemType)itemType
{
    ACCFlowerEffectType targetType = ACCFlowerEffectTypeInvalid;
    if ([itemType isEqualToString:ACCFlowerItemTypeScan]) {
        targetType = ACCFlowerEffectTypeScan;
    } else if ([itemType isEqualToString:ACCFlowerItemTypeRecognition]) {
        targetType = ACCFlowerEffectTypeRecognition;
    } else if ([itemType isEqualToString:ACCFlowerItemTypePhoto]) {
        targetType = ACCFlowerEffectTypePhoto;
    } else if ([itemType isEqualToString:ACCFlowerItemTypeProp]) {
        targetType = ACCFlowerEffectTypeProp;
    }
    return targetType;
}

- (NSInteger)itemIndexForFlowerPropID:(NSString *)propID
{
    if (ACC_isEmptyString(propID)) {
        return kACCFlowerPanelIndexInvalid;
    }
    __block NSInteger targetIndex = kACCFlowerPanelIndexInvalid;
    [self.items enumerateObjectsUsingBlock:^(ACCFlowerPanelEffectModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.effectID isEqualToString:propID]) {
            targetIndex = idx;
            *stop = YES;
        }
    }];
    return targetIndex;
}

#pragma mark - track

// flower camera tab

- (void)flowerTrackForEnterFlowerCameraTab:(NSString *)enterMethod propID:(NSString *)propID
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    // enter_method取值：click_sf_2022_icon（点击icon）/ schema 透传enter_method（主会场 个人页 超级+） / referstring （道具、音乐拍同款），逻辑比较复杂，DA坚持这样打
    NSString *enterFrom = self.propService.repository.repoFlowerTrack.schemaEnterMethod ?: self.propService.repository.repoTrack.referString;
    self.enterFlowerTabMethod = ACC_isEmptyString(enterMethod) ? (enterFrom ?: @"sf_2022_activity") : enterMethod;
    params[@"enter_method"] = self.enterFlowerTabMethod;
    params[@"prop_id"] = propID;
    params[@"enter_from"] = self.propService.repository.repoTrack.referString ?: @"direct_shoot";
    ACCFLOActivityStageType currentStage = [ACCFlowerCampaignManager() getCurrentActivityStage];
    NSString *activityName = @"";
    if (currentStage == ACCFLOActivityStageTypeAppointment) {
        activityName = @"warmup";
    } else if (currentStage == ACCFLOActivityStageTypeLuckyCard) {
        activityName = @"card";
    }
    params[@"activity_name"] = activityName;
    params[@"activity_id"] = ACCConfigString(kConfigString_tools_flower_activity_id);
    params[@"act_id"] = [ACCFlowerCampaignManager() activityHashString];
    // flower通用参数
    params[@"params_for_special"] = @"flower";
    [ACCTracker() trackEvent:@"sf_2022_activity_camera_enter" params:params];
}

- (void)flowerTrackForQuitFlowerCameraTab:(BOOL)isLoadFailed
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"enter_method"] = self.enterFlowerTabMethod ?: @"sf_2022_activity";
    self.enterFlowerTabMethod = nil;
    ACCFLOActivityStageType currentStage = [ACCFlowerCampaignManager() getCurrentActivityStage];
    NSString *activityName = @"";
    if (currentStage == ACCFLOActivityStageTypeAppointment) {
        activityName = @"warmup";
    } else if (currentStage == ACCFLOActivityStageTypeLuckyCard) {
        activityName = @"card";
    }
    params[@"activity_name"] = activityName;
    params[@"exit_method"] = isLoadFailed ? @"others" : @"click_bottom_exit";
    params[@"prop_id"] = self.selectedItem.effectID ?: @"";
    // flower通用参数
    params[@"params_for_special"] = @"flower";
    [ACCTracker() trackEvent:@"sf_2022_activity_camera_exit" params:params];
}

// flower横滑panel

- (void)flowerTrackForPropShow:(NSInteger)index
{
    ACCFlowerPanelEffectModel *currentItem = [self.items acc_objectAtIndex:index];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"enter_method"] = @"sf_2022_activity_camera";
    params[@"prop_rec_id"] = ACC_isEmptyString(currentItem.effect.recId) ? @"0": currentItem.effect.recId;
    if (index >= self.targetIndexUnderLuckyCardStage) {
        params[@"impr_position"] = @(index - self.targetIndexUnderLuckyCardStage + 1).stringValue; // 不包含left effect，从1计数
    }
    params[@"prop_id"] = currentItem.effect.effectIdentifier ?: @"";
    [params addEntriesFromDictionary:[self p_flowerCommonTrackParams]];
    [ACCTracker() trackEvent:@"prop_show" params:params];
}

- (void)flowerTrackForPropClick:(NSInteger)index enterMethod:(NSString *)enterMethod
{
    ACCFlowerPanelEffectModel *currentItem = [self.items acc_objectAtIndex:index];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"enter_method"] = enterMethod ?: @"";
    params[@"prop_rec_id"] = ACC_isEmptyString(currentItem.effect.recId) ? @"0": currentItem.effect.recId;
    if (index >= self.targetIndexUnderLuckyCardStage) {
        params[@"impr_position"] = @(index - self.targetIndexUnderLuckyCardStage + 1).stringValue; // 不包含left effect，从1计数
    }
    params[@"prop_id"] = currentItem.effect.effectIdentifier ?: @"";
    params[@"activity_id"] = ACCConfigString(kConfigString_tools_flower_activity_id);
    params[@"act_id"] = [ACCFlowerCampaignManager() activityHashString];
    [params addEntriesFromDictionary:[self p_flowerCommonTrackParams]];
    [ACCTracker() trackEvent:@"prop_click" params:params];
}

// flower拍照道具

- (void)flowerTrackForEnterShootPropPanel
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"enter_from"] = @"video_shoot_page";
    params[@"enter_method"] = [self.propService.repository.repoFlowerTrack lastChooseMethod] ?: @"sf_2022_activity_camera";
    params[@"tab_name"] = @"sf_2022_activity_camera_photo";
    params[@"prop_id"] = self.selectedItem.effect.effectIdentifier ?: @"";
    // flower通用参数
    params[@"params_for_special"] = @"flower";
    [ACCTracker() trackEvent:@"sf_photo_shoot_prop_enter" params:params];
}

- (void)flowerTrackForShootPropShow:(IESEffectModel *)prop index:(NSInteger)index
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"enter_method"] = @"";
    params[@"prop_rec_id"] = ACC_isEmptyString(prop.recId) ? @"0": prop.recId;
    params[@"prop_id"] = prop.effectIdentifier ?: @"";
    params[@"impr_position"] = @(index + 1).stringValue;
    params[@"tab_name"] = @"sf_2022_photo_shoot";
    [params addEntriesFromDictionary:[self p_flowerCommonTrackParams]];
    [ACCTracker() trackEvent:@"prop_show" params:params];
    
}

- (void)flowerTrackForShootPropClick:(IESEffectModel *)prop enterMethod:(NSString *)enterMethod
{
    __block NSInteger index = 0;
    [self.shootProps enumerateObjectsUsingBlock:^(IESEffectModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.effectIdentifier isEqualToString:prop.effectIdentifier]) {
            index = idx;
            *stop = YES;
        }
    }];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"enter_method"] = enterMethod ?: @"";
    params[@"prop_rec_id"] = ACC_isEmptyString(prop.recId) ? @"0": prop.recId;
    params[@"prop_id"] = prop.effectIdentifier ?: @"";
    params[@"impr_position"] = @(index + 1).stringValue;
    params[@"tab_name"] = @"sf_2022_photo_shoot";
    params[@"activity_id"] = ACCConfigString(kConfigString_tools_flower_activity_id);
    params[@"act_id"] = [ACCFlowerCampaignManager() activityHashString];
    [params addEntriesFromDictionary:[self p_flowerCommonTrackParams]];
    [ACCTracker() trackEvent:@"prop_click" params:params];
    
}

// flower task entry view

- (void)flowerTrackForEnterTaskEntryView
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"enter_from"] = @"sf_2022_activity_camera";
    // flower通用参数
    params[@"params_for_special"] = @"flower";
    [ACCTracker() trackEvent:@"sf_2022_activity_camera_task_entrance_click" params:params];
    
}

// flower common params

- (NSDictionary *)p_flowerCommonTrackParams
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    
    params[@"enter_from"] = @"video_shoot_page";
    params[@"shoot_way"] = self.propService.repository.repoTrack.referString ?: @"direct_shoot";
    params[@"creation_id"] = self.propService.repository.repoContext.createId ?: @"";
    AVCaptureDevicePosition cameraPostion = self.cameraService.cameraControl.currentCameraPosition;
    params[@"camera_direction"] = ACCDevicePositionStringify(cameraPostion);
    // flower通用参数
    params[@"params_for_special"] = @"flower";
    
    return params.copy;
}

#pragma mark - flower monitor

- (void)trackForFlowerPropListRequest:(CFTimeInterval)startTime error:(NSError * __nullable)error
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    if (error) {
        params[@"error_code"] = @(error.code);
        params[@"error_desc"] = error.description ?: @"";
    } else {
        params[@"duration"] = @((CFAbsoluteTimeGetCurrent() - startTime) * 1000);
    }
    NSInteger timeLine = 2;
    ACCFLOActivityStageType activityStage = [ACCFlowerCampaignManager() getCurrentActivityStage];
    if (activityStage == ACCFLOActivityStageTypeAppointment) {
        timeLine = 0;
    } else if (activityStage == ACCFLOActivityStageTypeLuckyCard) {
        timeLine = 1;
    }
    params[@"timeline"] = @(timeLine);
    [ACCMonitor() trackService:@"slide_list_request"
                        status:error ? 1 : 0
                         extra:params];
}

- (void)trackForFlowerPropDownload:(CFTimeInterval)startTime flowerPropType:(NSInteger)flowerPropType error:(NSError * __nullable)error
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    if (error) {
        params[@"error_code"] = @(error.code);
        params[@"error_msg"] = error.description ?: @"";
    } else {
        params[@"duration"] = @((CFAbsoluteTimeGetCurrent() - startTime) * 1000);
    }
    // 1npc道具，2春节横滑道具，3扫一扫道具，4物种识别道具，5拍照道具
    params[@"flower_sticker_type"] = @(flowerPropType);
    params[@"sticker_id"] = self.selectedItem.effect.effectIdentifier ?: @"";
    [ACCMonitor() trackService:@"flower_sticker_download_error_rate"
                        status:error ? 1 : 0
                         extra:params];
}

- (void)trackForFlowerPhotoPropListLoad:(CFTimeInterval)startTime error:(NSError * __nullable)error
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    if (error) {
        params[@"error_code"] = @(error.code);
        params[@"error_msg"] = error.description ?: @"";
    } else {
        params[@"duration"] = @((CFAbsoluteTimeGetCurrent() - startTime) * 1000);
    }
    params[@"panel"] = @"flower_photo";
    [ACCMonitor() trackService:@"flower_photo_sticker_list_error_rate"
                        status:error ? 1 : 0
                         extra:params];
}

- (void)trackForFlowerSlidePropListLoad:(CFTimeInterval)startTime error:(NSError * __nullable)error
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    if (error) {
        params[@"error_code"] = @(error.code);
        params[@"error_msg"] = error.description ?: @"";
    } else {
        params[@"duration"] = @((CFAbsoluteTimeGetCurrent() - startTime) * 1000);
    }
    params[@"panel"] = @"flower_photo";
    [ACCMonitor() trackService:@"flower_slide_sticker_list_error_rate"
                        status:error ? 1 : 0
                         extra:params];
}

#pragma mark - getters and setters

- (void)setSelectedIndex:(NSInteger)selectedIndex
{
    if (selectedIndex == _selectedIndex) {
        return;
    }
    [self willChangeValueForKey:@"selectedIndex"];
    [self willChangeValueForKey:@"selectedItem"];
    _selectedIndex = selectedIndex;
    _selectedItem = [self.items acc_objectAtIndex:selectedIndex];
    [self didChangeValueForKey:@"selectedIndex"];
    [self didChangeValueForKey:@"selectedItem"];
    
    IESEffectModel *effect = _selectedItem.effect;
    if (effect) {
        if (_selectedItem.dType != ACCFlowerEffectTypeProp) {
            [self.propService applyProp:nil propSource:ACCPropSourceFlower];
            self.downloadProgressPack = @[@(selectedIndex), @(1.0)];
        } else {
            if (effect.downloaded || [effect isFlowerPropAduit]) {
                // apply immediately if it is downloaded
                self.downloadProgressPack = @[@(selectedIndex), @(1.0)];
                [self.propService applyProp:effect propSource:ACCPropSourceFlower];
            } else {
                [self.propService applyProp:nil propSource:ACCPropSourceFlower];
                // apply after downloading
                NSNumber *progress = [[AWEStickerDownloadManager manager] stickerDownloadProgress:effect] ?: @(0);
                self.downloadProgressPack = @[@(selectedIndex), progress];
                self.loadStartTime = CFAbsoluteTimeGetCurrent();
                [[AWEStickerDownloadManager manager] downloadStickerIfNeed:effect];
            }
        }
    } else {
        [self.propService applyProp:nil propSource:ACCPropSourceFlower];
    }
    
    [self.flowerService updateCurrentItem:_selectedItem];
}

- (void)setFlowerService:(id<ACCFlowerService>)flowerService
{
    _flowerService = flowerService;
    [flowerService addSubscriber:self];
}

- (void)setShootProps:(NSArray<IESEffectModel *> *)shootProps
{
    if (!ACC_isEmptyArray(shootProps)) {
        self.shootPropLoaded = YES;
    }
    _shootProps = shootProps;
}

@end
