//
//  ACCExposePropPanelViewModel.m
//  CameraClient-Pods-Aweme
//
//  Created by yangguocheng on 2021/1/6.
//

#import "AWERepoPropModel.h"

#import <CreationKitInfra/ACCTapticEngineManager.h>
#import <CameraClient/ACCConfigKeyDefines.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import <CameraClient/ACCRecordPropService.h>
#import <CameraClient/AWEStickerDownloadManager.h>
#import <CameraClient/IESEffectModel+DStickerAddditions.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreationKitInfra/ACCToastProtocol.h>
#import <CreativeKit/NSArray+ACCAdditions.h>

#import <CameraClient/ACCPropPickerViewModel.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CameraClient/ACCRecognitionTrackModel.h>
#import <CameraClient/ACCGrootStickerModel.h>
#import <CreationKitRTProtocol/ACCCameraService.h>
#import <CameraClient/ACCTrackerUtility.h>

#import "ACCRecognitionPropPanelViewModel.h"
#import "ACCPropDataFilter.h"
#import "ACCRecognitionService.h"
#import "ACCRecognitionGrootConfig.h"

@interface ACCRecognitionPropPanelViewModel() <AWEStickerDownloadObserverProtocol>

@property (nonatomic, strong) RACSubject *propSelectionSubject;
@property (nonatomic, strong) RACSubject *enableCaptureSubject;
@property (nonatomic, strong) RACSubject *downloadProgressSubject;
@property (nonatomic, strong) RACSubject *captureFocusSubject;
@property (nonatomic, strong) RACSubject <RACTwoTuple<ACCPropPickerItem *, NSNumber *> *> *selectItemSubject;

@property (nonatomic, assign) BOOL favorStatus; // current item favor status

@property (nonatomic, copy) NSArray<ACCPropPickerItem *> *propPickerDataList;

@property (nonatomic, copy) NSArray<IESEffectModel *> *hotPropEffectList;

@property (nonatomic, strong) ACCPropPickerItem *selectedItem;

@property (nonatomic, strong) ACCPropDataFilter *hotPropFilter;

@property (nonatomic, strong) id<ACCRecordPropService> propService;
@property (nonatomic, strong) id<ACCRecognitionService> recognitionService;


@property (nonatomic, strong) NSDictionary *trackingInfoDictionary;
@property (nonatomic, strong) NSMutableArray<NSString*> *exposedIds;

@end

@implementation ACCRecognitionPropPanelViewModel
@synthesize favoriteResultCallback = _favoriteResultCallback;
@synthesize inputData = _inputData;
IESAutoInject(self.serviceProvider, propService, ACCRecordPropService)
IESAutoInject(self.serviceProvider, recognitionService, ACCRecognitionService)

- (instancetype)init
{
    self = [super init];
    if (self) {
        _exposedIds = [NSMutableArray new];
        _hotPropFilter = [[ACCPropDataFilter alloc] initWithInputData:self.inputData];
        _hotPropFilter.effectFilterType = AWEStickerFilterTypeGame;
        _hotPropFilter.filterCommerce = YES;

        _propSelectionSubject = [RACSubject subject];
        _enableCaptureSubject = [RACSubject subject];
        _downloadProgressSubject = [RACSubject subject];
        _captureFocusSubject = [RACSubject subject];
        _selectItemSubject = [RACSubject subject];
        
        [[AWEStickerDownloadManager manager] addObserver:self];

        @weakify(self)
        self.favoriteResultCallback = ^(BOOL result, IESEffectModel * _Nonnull willFavoriteProp, BOOL isFavorite) {
            @strongify(self);
            if (result) {
                if (isFavorite && willFavoriteProp) {
                    [self.recognitionService.dataManager insertPropToFavorite:willFavoriteProp];
                } else {
                    [self.recognitionService.dataManager deletePropFromFavorite:willFavoriteProp];
                }
                [self updatePropPickerItems];
                [self onPropPickerPanelFavoriteStatusChangeTo:isFavorite withProp:willFavoriteProp];
                [self checkFavorStatus];
            }
        };
        self.propPickerDataList = @[];
    }
    return self;
}

- (void)setInputData:(ACCRecordViewControllerInputData *)inputData
{
    _inputData = inputData;
    self.hotPropFilter.inputData = inputData;
}

- (void)onPropPickerPanelFavoriteStatusChangeTo:(BOOL)willFavorite withProp:(IESEffectModel *)willFavoriteProp
{
    // prop picker panel cancel favorite won't clear prop application, so we should add it on top
    if (!willFavorite) {
        if (self.selectedItem == nil) {
            if (willFavoriteProp != nil) {
                ACCPropPickerItem *toSelectItem = [self.propPickerDataList acc_match:^BOOL(ACCPropPickerItem * _Nonnull item) {
                    return [item.effect.effectIdentifier isEqual:willFavoriteProp.effectIdentifier];
                }];
                if (toSelectItem != nil) {
                    [self updateSelectedItem:toSelectItem];
                }
            }
        } else {
            [self.selectItemSubject sendNext:RACTuplePack(self.selectedItem, @(NO))];
        }
    } else {
        [self.selectItemSubject sendNext:RACTuplePack(self.selectedItem, @(NO))];
    }
}

- (RACSignal<NSNumber *> *)enableCaptureSignal
{
    return self.enableCaptureSubject;
}

- (RACSignal<RACTwoTuple<NSNumber *,NSNumber *> *> *)downloadProgressSignal
{
    return self.downloadProgressSubject;
}

- (RACSignal<IESEffectModel *> *)propSelectionSignal
{
    return self.propSelectionSubject;
}

- (RACSignal<RACTwoTuple<ACCPropPickerItem *, NSNumber *> *> *)selectItemSignal
{
    return self.selectItemSubject;
}

- (void)fetchHotDataIfNeeded
{
    let dataManager = self.recognitionService.dataManager;
    if (dataManager.isHotRequesting) {
        return;
    }

    @weakify(self)
    /// update new hot prop list
    [dataManager loadDataCompletion:^(NSError * _Nullable error, NSArray<IESEffectModel *> * _Nullable effects) {
        @strongify(self)
        if (effects.count == 0 && error != nil) {
            if (self.isShowingPanel && self.hotPropEffectList.count == 0) {
                [ACCToast() showToast:@"道具下载失败"];
            }
            ACCLog(@"sticker download error:%@", error);
        } else {
            [self processPropList];
            if (self.recognitionService.dataManager.recognitionEffects.count == 0) {
                [self updatePropPickerItems];
            }
        }
    }];
}

- (void)fetchFavoriteEffectsIfNeed
{
    /// fetch favorite list
    if (!self.recognitionService.dataManager.isFavorRequestSuccess &&
        !self.recognitionService.dataManager.isFavorRequesting){
        [self.recognitionService.dataManager fetchFavorWithCompletion:^(NSError * _Nullable error, NSArray<IESEffectModel *> * _Nullable effects) {
            if (error) {
                ACCLog(@"fetch favor  list error:%@", error);
            }
        }];
    }
}

- (BOOL)isValidHomeItem
{
    return _homeItem && [self.recognitionService.trackModel isWikiType];
}

- (ACCPropPickerItem *)homeItem
{
    if (!self.isValidHomeItem){
        return nil;
    }
    return _homeItem;
}

- (NSInteger)propCount
{
    NSInteger count = ACCConfigInt(ACCConfigKeyDefaultPair(@"recognition_prop_count", @8));

    if (self.homeItem){
        count ++;
    }
    return count;
}

- (void)showData
{
    [self updatePropPickerItems];
}

- (void)keepCurrentSelectionIndexRelatedWithHome:(NSUInteger)index
{
    if (index == 0) {
        return;
    }
    NSUInteger targetIndex = index - 1;
    if (targetIndex < self.propPickerDataList.count) {
        [self selectIndex:targetIndex];
    }
}

- (void)processPropList
{
    NSArray<IESEffectModel *> *filtered = [self filteredEffect:self.recognitionService.dataManager.effects];
    NSArray<IESEffectModel *> *fetched = [self truncateEffects:filtered
                                                    limitCount:(NSInteger)ACCConfigInt(kConfigInt_recognition_prop_count)];
    self.hotPropEffectList = fetched;
}

- (void)selectRecognitionWithEffectModel:(IESEffectModel *)effectModel
{
    [self seletEffectModel:effectModel categoryType:ACCPropPickerItemCategoryTypeRecognition];
}

- (void)selectHotWithEffectModel:(IESEffectModel *)effectModel
{
    [self seletEffectModel:effectModel categoryType:ACCPropPickerItemCategoryTypeHot];
}

- (void)seletEffectModel:(IESEffectModel *)effectModel categoryType:(ACCPropPickerItemCategoryType)categoryType
{
    if (effectModel == nil) {
        return;
    }
    ACCPropPickerItem *toSelectItem = [self.propPickerDataList acc_match:^BOOL(ACCPropPickerItem * _Nonnull item) {
        return [item.effect.effectIdentifier isEqual:effectModel.effectIdentifier] && item.categoryType == categoryType;
    }];
    if (toSelectItem != nil) {
        [self updateSelectedItem:toSelectItem];
    }
}

- (void)updatePropPickerItems
{
    NSArray<IESEffectModel *> *hotPropList = self.hotPropEffectList;
    NSArray<IESEffectModel *> *recognitionPropList = self.recognitionService.dataManager.recognitionEffects;

    if (recognitionPropList.count > 0){
        /// Make up to propCount
        if (recognitionPropList.count < self.propCount && self.recognitionService.dataManager.needFallbackEffects) {
            recognitionPropList = [recognitionPropList arrayByAddingObjectsFromArray:[hotPropList.rac_sequence take:self.propCount-recognitionPropList.count].array];
        }

        [self updateItemsWithEffects:recognitionPropList type:ACCPropPickerItemCategoryTypeRecognition];
    }else{
        [self updateItemsWithEffects:hotPropList type:ACCPropPickerItemCategoryTypeHot];
    }

    /// clear exposed item
    [self.exposedIds removeAllObjects];

}

- (void)updateFavoriteEffects:(NSArray<IESEffectModel *> *)favoriteEffects
{
    [self.recognitionService.dataManager updateFavoriteEffects:favoriteEffects];
}

- (void)applyFirstHot
{
    if (self.recognitionService.dataManager.isHotRequestSuccess) {
        if (self.propPickerDataList.count) {
            [self updateSelectedItem:self.propPickerDataList.firstObject animated:YES];
            if (self.selectedItem.effect != nil) {
                [self trackPropClickEventFromIndex:0 andProp:self.selectedItem.effect];
            }
        }
    }
}

- (void)applyFirstRecognition
{
    if (self.recognitionService.dataManager.recognitionEffects.count > 0){

        if (self.propPickerDataList.count) {
            [self updateSelectedItem:self.propPickerDataList.firstObject animated:YES];
        }
    }else{
        [self applyFirstHot];
    }
}

- (NSArray<IESEffectModel *> *)filteredEffect:(NSArray<IESEffectModel *> *)effects
{
    return [self.hotPropFilter filteredEffects:effects];
}

- (NSArray<IESEffectModel *> *)truncateEffects:(NSArray<IESEffectModel *> *)effects limitCount:(NSInteger)limitCount
{
    NSInteger count = MIN(effects.count, limitCount);
    return [effects subarrayWithRange:NSMakeRange(0, count)];
}

- (void)updateItemsWithEffects:(NSArray<IESEffectModel *> *)allEffects type:(ACCPropPickerItemCategoryType)type
{
    NSArray<IESEffectModel *> *effects = [self filteredEffect:allEffects];
    NSMutableArray<ACCPropPickerItem *> *items = [NSMutableArray arrayWithCapacity:effects.count];

    if (self.homeItem){
        [items btd_addObject:self.homeItem];
    }

    if (effects.count > 0) {
        [items addObjectsFromArray:[effects btd_map:^id _Nullable(IESEffectModel * _Nonnull obj) {
            ACCPropPickerItem *item = [[ACCPropPickerItem alloc] initWithType:ACCPropPickerItemTypeEffect effect:obj];
            item.categoryType = type;
            return item;
        }]];
    }

    self.propPickerDataList = [items.rac_sequence take:self.propCount].array;
}

- (NSArray<IESEffectModel *> *)insertEffect:(IESEffectModel *)topEffect toEffects:(NSArray<IESEffectModel *> *)effects
{
    if (topEffect == nil) {
        return effects.copy;
    }
    NSMutableArray<IESEffectModel *> *combined = [NSMutableArray arrayWithArray:effects];
    NSMutableIndexSet *indexesToRemove = [NSMutableIndexSet indexSet];
    [combined enumerateObjectsUsingBlock:^(IESEffectModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.effectIdentifier isEqual:topEffect.effectIdentifier]) {
            [indexesToRemove addIndex:idx];
        }
    }];
    if (indexesToRemove.count > 0) {
        [combined removeObjectsAtIndexes:indexesToRemove];
    }
    [combined btd_insertObject:topEffect atIndex:0];
    return combined;
}

- (NSArray<IESEffectModel *> *)insertEffects:(NSArray<IESEffectModel *> *)effectsToInsert toEffects:(NSArray<IESEffectModel *> *)effects
{
    NSMutableArray *distinct = [NSMutableArray arrayWithArray:effects];
    for (IESEffectModel *effect in effectsToInsert) {
        NSInteger index = [distinct indexOfObject:effect];
        if (index != NSNotFound) {
            [distinct btd_removeObjectAtIndex:index];
        }
    }
    NSMutableArray *combined = [NSMutableArray arrayWithArray:effectsToInsert];
    [combined addObjectsFromArray:distinct];
    return combined;
}

- (void)selectIndex:(NSUInteger)index
{
    ACCPropPickerItem *willSelectPickerItem = [self.propPickerDataList btd_objectAtIndex:index];

    if (willSelectPickerItem == self.selectedItem && self.selectedItem.type == ACCPropPickerItemTypeEffect) {
        if (!(self.selectedItem.effect.childrenEffects.count > 0 || self.selectedItem.effect.downloaded)) {
            [self.downloadProgressSubject sendNext:RACTuplePack(@([self selectedIndex]), [[AWEStickerDownloadManager manager] stickerDownloadProgress:self.selectedItem.effect]?:@(0))];
            [[AWEStickerDownloadManager manager] downloadStickerIfNeed:self.selectedItem.effect];
        }
        return;
    }
    
    [self updateSelectedItem:willSelectPickerItem];
}

- (NSInteger)selectedIndex
{
    if (self.selectedItem == nil) {
        return 0;
    }
    // Need to pay attention to performance issues in the future, The current maximum number of lists is 103
    NSInteger index = [self.propPickerDataList indexOfObject:self.selectedItem];
    if (index == NSNotFound) {
        index = 0;
    }
    return index;
}

- (void)onFavoriteStatusChangeTo:(BOOL)willFavorite
{
    [self.selectItemSubject sendNext:RACTuplePack(self.selectedItem, @(NO))];
}

- (void)updateSelectedItem:(ACCPropPickerItem *)selectedItem
{
    [self updateSelectedItem:selectedItem animated:NO];
}

- (void)updateSelectedItem:(ACCPropPickerItem *)selectedItem animated:(BOOL)animated
{
    BOOL changed = _selectedItem != selectedItem;
    self.selectedItem = selectedItem;
    [self.selectItemSubject sendNext:RACTuplePack(self.selectedItem, @(animated))];
    if (selectedItem.type == ACCPropPickerItemTypeEffect) {
        IESEffectModel *effect = selectedItem.effect;
        if (effect.childrenEffects.count > 0 || effect.downloaded) {
            [self.downloadProgressSubject sendNext:RACTuplePack(@([self selectedIndex]), nil)];
            [self applyEffect:effect propSource:ACCPropSourceRecognition];
        } else {
            [self.downloadProgressSubject sendNext:RACTuplePack(@([self selectedIndex]), [[AWEStickerDownloadManager manager] stickerDownloadProgress:effect]?:@(0))];
            if (self.isShowingPanel) {
                [self.recognitionService applyProp:nil propSource:ACCPropSourceRecognition];
            }
            [[AWEStickerDownloadManager manager] downloadStickerIfNeed:effect];
        }
    } else {
        if (self.selectedItem.type == ACCPropPickerItemTypePlaceholder) {
            [self.downloadProgressSubject sendNext:RACTuplePack(@([self selectedIndex]), @0)];
        } else {
            [self.downloadProgressSubject sendNext:RACTuplePack(@([self selectedIndex]), nil)];
        }
        if (changed) {
            [self applyEffect:nil propSource:ACCPropSourceReset];
        }
    }
    [self updateCaptureEnability];
    [self checkFavorStatus];
}

- (void)cancelPropSelection
{
    /// move picker view cursor to first position
    /// dont apply
    if (self.selectedItem != self.propPickerDataList.firstObject){
        var selectedItem = self.propPickerDataList.firstObject;
        self.selectedItem = selectedItem;
        [self.selectItemSubject sendNext:RACTuplePack(self.selectedItem, @(NO))];
    }
    [self updateSelectedItem:nil];
}

#pragma mark - Favor

- (void)changeFavorStatus
{
    if (self.selectedItem.effect == nil) {
        return;
    }
    IESEffectModel *effect = self.selectedItem.effect;
    BOOL toFavorStatus = !self.favorStatus;
    @weakify(self);
    [self.recognitionService.dataManager changeFavoriteWithEffect:effect favorite:toFavorStatus completionHandler:^(NSError * _Nullable error) {
        @strongify(self);
        if (error == nil) {
            if (toFavorStatus) {
                NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:self.trackingInfoDictionary];
                params[@"enter_method"] = @"click_outer_list";
                params[@"prop_id"] = effect.effectIdentifier ?: @"";
                params[@"enter_from"] = @"video_shoot_page";
                [self insertRecognitionParams:params index:-1];
                [ACCTracker() trackEvent:@"prop_save" params:params needStagingFlag:NO];
            }

            // 发送收藏或取消收藏的通知
            [[NSNotificationCenter defaultCenter] postNotificationName:@"AWEFavoriteActionNotification"
                                                                object:nil
                                                              userInfo:@{@"type":@(5),
                                                                         @"itemID": self.selectedItem.effect.effectIdentifier ? : @"",
                                                                         @"action": @(!self.favorStatus)}];
            [self updatePropPickerItems];
            [self onFavoriteStatusChangeTo:toFavorStatus];
            [self checkFavorStatus];
        } else {
            AWELogToolError(AWELogToolTagRecord, @"FavoritePlugin error: %@", error);
            // 失败后恢复收藏按钮
            if ([self.selectedItem.effect.effectIdentifier isEqualToString:effect.effectIdentifier]) {
                self.favorStatus = !toFavorStatus;
            }
        }

    }];
}

- (void)checkFavorStatus
{
    if (self.selectedItem.effect == nil) {
        self.favorStatus = NO;
        return;
    }
    IESEffectModel *favorProp = [self.recognitionService.dataManager.favorEffects acc_match:^BOOL(IESEffectModel * _Nonnull item) {
        return [item.effectIdentifier isEqual:self.selectedItem.effect.effectIdentifier];
    }];
    self.favorStatus = favorProp != nil;
}

- (void)applyEffect:(IESEffectModel *)effect propSource:(ACCPropSource)propSource
{
    if (![effect.propSelectedFrom isEqual:@"task"]) {
        effect.propSelectedFrom = self.recognitionService.trackModel.realityType;
    }

    [self.propSelectionSubject sendNext:effect];

    // all prop be processed internal except props(those prop will have no fileDownloadURLs or fileDownloadURI) who has child props or binded props
    BOOL isDownloadableSticker = effect.fileDownloadURLs.count > 0 && effect.fileDownloadURI.length > 0;
    if (effect == nil || isDownloadableSticker) {

        [self.recognitionService applyProp:effect propSource:propSource];

    }
}

- (BOOL)shouldEnableCapture
{
    if (self.selectedItem.type == ACCPropPickerItemTypeEffect) {
        return self.selectedItem.effect.childrenEffects.count > 0 || self.selectedItem.effect.downloaded;
    } else {
        return self.selectedItem.type == ACCPropPickerItemTypeHome;
    }
}

- (void)updateCaptureEnability
{
    BOOL shouldEnable = [self shouldEnableCapture];
    [self.enableCaptureSubject sendNext:@(shouldEnable)];
}

#pragma mark - ACCPropPickerViewDelegate

- (void)pickerView:(ACCPropPickerView *)pickerView didChangeCenteredIndex:(NSInteger)index scrollReason:(ACCPropPickerViewScrollReason)reason
{
    if (reason == ACCPropPickerViewScrollReasonDrag) {
        [ACCTapticEngineManager tap]; // light haptic feedback when scrolling across items by dragging
    }
}

- (void)pickerView:(ACCPropPickerView *)pickerView didPickIndexByTap:(NSInteger)index
{
    [self selectIndex:index];
}

- (void)pickerView:(ACCPropPickerView *)pickerView didPickIndexByDragging:(NSInteger)index
{
    [self selectIndex:index];
    if (index < self.propPickerDataList.count && [self.propPickerDataList btd_objectAtIndex:index].effect != nil) {
        [self trackPropClickEventFromIndex:index andProp:self.propPickerDataList[index].effect];
    }
}

- (void)pickerViewWillBeginDragging:(ACCPropPickerView *)pickerView
{
}

- (void)pickerView:(ACCPropPickerView *)pickerView didEndAnimationAtIndex:(NSInteger)index
{
    [self selectIndex:index];
    if (index < self.propPickerDataList.count && [self.propPickerDataList btd_objectAtIndex:index].effect != nil) {
        [self trackPropClickEventFromIndex:index andProp:self.propPickerDataList[index].effect];
    }
}

- (void)pickerView:(ACCPropPickerView *)pickerView willDisplayIndex:(NSInteger)index
{
    /// expose event, dont repeat report
    __auto_type effect = [self.propPickerDataList btd_objectAtIndex:index].effect;
    if ([self.exposedIds containsObject:effect.effectIdentifier]){
        return;
    }
    [self.exposedIds btd_addObject:effect.effectIdentifier];
    if (index < self.propPickerDataList.count && effect != nil) {
        [self trackPropShowEventFromIndex:index andProp:self.propPickerDataList[index].effect];
    }
    else if (index == 0 && self.homeItem){
        [self trackPropShowHomeItemEvent];
    }
}

#pragma mark - AWEStickerDownloadObserverProtocol

- (void)stickerDownloadManager:(AWEStickerDownloadManager *)manager sticker:(IESEffectModel *)effect downloadProgressChange:(CGFloat)progress
{
    if ([effect.effectIdentifier isEqualToString:self.selectedItem.effect.effectIdentifier]) {
        [self.downloadProgressSubject sendNext:RACTuplePack(@(self.selectedIndex), @(progress))];
    }
}

- (void)stickerDownloadManager:(AWEStickerDownloadManager *)manager didFinishDownloadSticker:(IESEffectModel *)effect
{
    if ([effect.effectIdentifier isEqualToString:self.selectedItem.effect.effectIdentifier]) {
        [self.downloadProgressSubject sendNext:RACTuplePack(@(self.selectedIndex), nil)];

        [self applyEffect:effect propSource:ACCPropSourceRecognition];

        [self updateCaptureEnability];
    }
}

- (void)stickerDownloadManager:(AWEStickerDownloadManager *)manager didFailDownloadSticker:(IESEffectModel *)effect withError:(NSError *)error
{
    if ([effect.effectIdentifier isEqualToString:self.selectedItem.effect.effectIdentifier]) {
        [self.downloadProgressSubject sendNext:RACTuplePack(@(self.selectedIndex), nil)];
        if (self.isShowingPanel) {
            [ACCToast() showToast:@"道具下载失败"];
        }
        if (error) {
            ACCLog(@"sticker download error:%@", error);
        }
    }
}

#pragma mark - Event Track

- (void)trackPropClickEventFromIndex:(NSInteger)index andProp:(IESEffectModel *)prop
{
    [self trackPropClickEventWithSticker:prop entrance:@"reality" atIndex:index];
}

- (void)trackPropShowEventFromIndex:(NSInteger)index andProp:(IESEffectModel *)prop
{
    [self trackPropShowEventWithSticker:prop entrance:@"reality" atIndex:index];
}

- (void)trackPropShowHomeItemEvent
{
    ACCGrootDetailsStickerModel *detail = self.recognitionService.trackModel.grootModel.stickerModel.selectedGrootStickerModel;
    NSMutableDictionary *params = [@{
        @"prop_id":[ACCRecognitionGrootConfig grootStickerId],
        @"is_sticker":@"1",
        @"baikeId": detail.baikeId ?:@"",
        @"species_name": detail.speciesName ?:@""

    } mutableCopy];
    [self insertRecognitionParams:params index:0];

    [ACCTracker() trackEvent:@"prop_show" params:params needStagingFlag:NO];
}

- (void)trackPropShowEventWithSticker:(IESEffectModel *)sticker
                             entrance:(NSString *)entrance
                              atIndex:(NSUInteger)index
{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:self.trackingInfoDictionary];
    params[@"prop_id"] = sticker.effectIdentifier ?: @"";
    params[@"prop_index"] = sticker.gradeKey ?: @"";
    params[@"is_sticker"] = @0;
    params[@"impr_position"] = @(index).stringValue;
    params[@"prop_rec_id"] = ACC_isEmptyString(sticker.recId) ? @"0": sticker.recId;
    NSString *fromPropID = self.inputData.publishModel.repoProp.localPropId;
    if (!ACC_isEmptyString(fromPropID)) {
        params[@"from_prop_id"] = fromPropID;
    }

    [self insertRecognitionParams:params index:index];

    [ACCTracker() trackEvent:@"prop_show" params:params needStagingFlag:NO];
}

- (void)insertRecognitionParams:(NSMutableDictionary *)params index:(NSInteger)index
{
    params[@"enter_from"] = @"video_shoot_page";
    params[@"content_type"] = @"reality";
    params[@"prop_selected_from"] = self.recognitionService.trackModel.realityType;
    params[@"reality_id"] = self.recognitionService.trackModel.realityId;
    if (index >= 0){
        params[@"rec_location"] = @(index);
    }
}

- (void)trackPropClickEventWithSticker:(IESEffectModel *)sticker
                              entrance:(NSString *)entrance
                               atIndex:(NSUInteger)index
{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:self.trackingInfoDictionary];
    params[@"enter_method"] = @"click_outer_list";
    params[@"prop_id"] = sticker.effectIdentifier ?: @"";
    params[@"prop_index"] = sticker.gradeKey ?: @"";
    params[@"enter_from"] = @"video_shoot_page";
    params[@"impr_position"] = @(index).stringValue;
    params[@"prop_rec_id"] = ACC_isEmptyString(sticker.recId) ? @"0": sticker.recId;
    NSString *fromPropID = self.inputData.publishModel.repoProp.localPropId;
    if (!ACC_isEmptyString(fromPropID)) {
        params[@"from_prop_id"] = fromPropID;
        BOOL isDefaultProp = [sticker.effectIdentifier isEqualToString:fromPropID];
        params[@"is_default_prop"] = isDefaultProp ? @"1" : @"0";
    }
    //========================================================================
    id<ACCCameraService> cameraService = self.cameraServiceBlock != NULL ? self.cameraServiceBlock() : nil;
    AVCaptureDevicePosition cameraPostion = cameraService.cameraControl.currentCameraPosition;
    params[@"camera_direction"] = ACCDevicePositionStringify(cameraPostion);
    //========================================================================

    /// recognition params
    [self insertRecognitionParams:params index:index];

    [ACCTracker() trackEvent:@"prop_click" params:params needStagingFlag:NO];
}

- (NSDictionary *)trackingInfoDictionary
{
    if (_trackingInfoDictionary == nil) {
        AWEVideoPublishViewModel *publishModel = self.inputData.publishModel;
        _trackingInfoDictionary = @{
            @"creation_id" : publishModel.repoContext.createId ?: @"",
            @"shoot_way" : publishModel.repoTrack.referString ?: @"",
            @"enter_from" : @"video_shoot_page",
            @"group_id" : self.inputData.groupID ?: @"",
        };
    }

    return _trackingInfoDictionary;
}

#pragma mark - ACCViewModel

- (void)dealloc
{
    [[AWEStickerDownloadManager manager] removeObserver:self];
    [_propSelectionSubject sendCompleted];
    [_enableCaptureSubject sendCompleted];
    [_downloadProgressSubject sendCompleted];
    [_selectItemSubject sendCompleted];
}

@end
