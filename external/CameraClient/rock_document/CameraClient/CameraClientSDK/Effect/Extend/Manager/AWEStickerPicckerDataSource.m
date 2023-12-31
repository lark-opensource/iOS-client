//
//  AWEStickerPicckerDataSource.m
//  CameraClient-Pods-Aweme
//
//  Created by Chipengliu on 2020/11/5.
//

#import "AWEStickerPicckerDataSource.h"
#import "ACCConfigKeyDefines.h"
#import "AWEDouyinStickerCategoryModel.h"
#import "AWEStickerPickerTabViewLayout.h"
#import "AWEStickerPickerDataContainer.h"
#import "ACCPropExploreExperimentalControl.h"

#import <CameraClient/ACCConfigKeyDefines.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreativeKit/ACCWebImageProtocol.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreativeKit/ACCMacros.h>
#import <EffectPlatformSDK/EffectPlatform.h>

@interface AWEStickerPicckerDataSource ()

@property (nonatomic, strong) AWEStickerPickerTabViewLayout *tabViewLayout;
@property (nonatomic, strong, readwrite) dispatch_queue_t dataHanleQueue;
@property (nonatomic, strong) NSMutableDictionary<NSString*, IESEffectModel*> *effectMap;

@property (nonatomic, strong) NSArray<id<AWEStickerPickerDataContainerProtocol>> *dataContainers;
@property (nonatomic, strong) id<AWEStickerPickerDataContainerProtocol> currentDataContainer;


@end

@implementation AWEStickerPicckerDataSource

- (instancetype)init {
    if (self = [super init]) {
        _dataHanleQueue = dispatch_queue_create("AWEStickerPicckerDataSourceQueue", DISPATCH_QUEUE_SERIAL);
        _effectMap = [[NSMutableDictionary alloc] init];
    }
    return self;
}


#pragma mark - Public Methods
- (id<AWEStickerPickerDataContainerProtocol>)dataContainer
{
    @synchronized (self) {
        if (!self.currentDataContainer) {
            if (!self.dataContainers || self.dataContainers.count == 0) {
                AWEStickerPickerDataContainer *defaultContainer = [[AWEStickerPickerDataContainer alloc] init];
                defaultContainer.dataHanleQueue = self.dataHanleQueue;
                self.dataContainers = @[defaultContainer];
            }
            self.currentDataContainer = self.dataContainers.firstObject;
        }
        return self.currentDataContainer;
    }
}


- (void)useDataContainer:(NSString *)identifier
{
    @synchronized (self) {
        [self.dataContainers enumerateObjectsUsingBlock:^(id<AWEStickerPickerDataContainerProtocol> obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([identifier isEqualToString:obj.identifier]) {
                self.currentDataContainer = obj;
                *stop = YES;
            }
        }];
    }
}

- (void)setupDataContainers:(NSArray<id<AWEStickerPickerDataContainerProtocol>> *)containers
{
    @synchronized (self) {
        self.dataContainers = [containers copy];
    }
}

- (AWEStickerCategoryModel *)favoriteCategoryModel
{
    @synchronized (self) {
        return self.dataContainer.favoriteCategoryModel;
    }
}

- (IESEffectModel *)effectFromMapForId:(NSString *)identifier {
    return [self dataContainer:self.dataContainer effectFromMapForId:identifier];
}

- (IESEffectModel *)dataContainer:(id<AWEStickerPickerDataContainerProtocol>)dataContainer
               effectFromMapForId:(NSString *)identifier {
    NSAssert(identifier.length > 0, @"identifier is invalid!!");
    if (identifier.length == 0) {
        return nil;
    }
    @synchronized (self) {
        return self.effectMap[identifier];
    }
}

- (void)addEffectsToMap:(NSArray<IESEffectModel *> *)effectArray {
    @synchronized (self) {
        for (IESEffectModel *effect in effectArray) {
            if (effect.effectIdentifier.length > 0) {
                self.effectMap[effect.effectIdentifier] = effect;
            }
        }
    }
}

- (CGSize)cellSizeForTabIndex:(NSInteger)index {
    return [self dataContainer:self.dataContainer cellSizeForTabIndex:index];
}

- (CGSize)dataContainer:(id<AWEStickerPickerDataContainerProtocol>)dataContainer
    cellSizeForTabIndex:(NSInteger)index {
    NSAssert(index < dataContainer.categoryArray.count, @"index is invalid!!!");
    if (index < dataContainer.categoryArray.count) {
        return dataContainer.categoryArray[index].cellSize;
    }
    return CGSizeZero;
}

// 插入到热门分类tab的道具
- (void)insertPrioritizedStickers:(NSArray<IESEffectModel *> *)stickers {
    [self dataContainer:self.dataContainer insertPrioritizedStickers:stickers];
}

- (void)dataContainer:(id<AWEStickerPickerDataContainerProtocol>)dataContainer
insertPrioritizedStickers:(NSArray<IESEffectModel *> *)stickers {
    dataContainer.insertStickers = stickers;
    [self mergeWithInsertStickers:dataContainer];
}

#pragma mark - private
- (NSArray<IESEffectModel *> *)dataContainer:(id<AWEStickerPickerDataContainerProtocol>)dataContainer
                   effectArrayForCategoryKey:(NSString *)categoryKey {
    NSArray<IESEffectModel *> *arr = nil;
    if (categoryKey.length == 0) {
        return arr;
    }
    
    @synchronized (dataContainer.effectArrayMap) {
        arr = dataContainer.effectArrayMap[categoryKey];
        return [arr copy];
    }
}

- (void)dataContainer:(id<AWEStickerPickerDataContainerProtocol>)dataContainer
updateEffectArrayForCategoryKey:(NSString *)categoryKey
          effectArray:(NSArray<IESEffectModel *> *)effectArray {
    @synchronized (dataContainer.effectArrayMap) {
        dataContainer.effectArrayMap[categoryKey] = [effectArray copy];
    }
}

- (AWEStickerPickerTabViewLayout *)tabViewLayout {
    if (!_tabViewLayout) {
        _tabViewLayout = [[AWEStickerPickerTabViewLayout alloc] init];
    }
    return _tabViewLayout;
}

// IESCategoryModel -> AWEDouyinStickerCategoryModel
- (NSArray <AWEDouyinStickerCategoryModel *> *)transformWithCategories:(NSArray <IESCategoryModel *> *)categories
                                                             panelName:(NSString *)panelName
                                                         dataContainer:(id<AWEStickerPickerDataContainerProtocol>)dataContainer {
    NSMutableArray *stickerCategoryModels = [[NSMutableArray alloc] init];
    
    // search for tab entrance
    if (self.isOnRecordingPage && dataContainer.enableSearch && [self shouldSupportSearchFeature] == ACCPropPanelSearchEntranceTypeTab && dataContainer.searchCategoryModel == nil) {
        AWEDouyinStickerCategoryModel *searchCategory = [AWEDouyinStickerCategoryModel searchCategoryModel];
        dataContainer.searchCategoryModel = searchCategory;
        searchCategory.panelName = panelName;
        if (self.stickerFilterBlock) {
            searchCategory.stickerFilterBlock = self.stickerFilterBlock;
        }
        [self updateTabLayoutForCategory:searchCategory tabIndex:0];
        [stickerCategoryModels acc_addObject:searchCategory];
    }
    
    if (self.needFavorite && dataContainer.favoriteCategoryModel == nil) {
        // favorite
        AWEDouyinStickerCategoryModel *favoriteCategory = [AWEDouyinStickerCategoryModel favoriteCategoryModel];
        dataContainer.favoriteCategoryModel = favoriteCategory;
        favoriteCategory.panelName = panelName;
        [self updateTabLayoutForCategory:favoriteCategory tabIndex:1];
        [stickerCategoryModels acc_addObject:dataContainer.favoriteCategoryModel];
    }
    
    [categories enumerateObjectsUsingBlock:^(IESCategoryModel * _Nonnull categoryModel, NSUInteger idx, BOOL * _Nonnull stop) {
        AWEDouyinStickerCategoryModel *category = [[AWEDouyinStickerCategoryModel alloc] initWithIESCategoryModel:categoryModel];
        category.panelName = panelName;
        category.orignalStickers = category.stickers;
        if (self.stickerFilterBlock) {
            category.stickerFilterBlock = self.stickerFilterBlock;
        }
        [self updateTabLayoutForCategory:category tabIndex:stickerCategoryModels.count];
        [stickerCategoryModels acc_addObject:category];
    }];
    
    return [stickerCategoryModels copy];
}

- (void)updateTabLayoutForCategory:(AWEDouyinStickerCategoryModel *)category
                          tabIndex:(NSInteger)tabIndex {
    @weakify(category);
    [self.tabViewLayout categoryViewLayoutWithContainerHeight:40
                                                        title:category.categoryName
                                                        image:category.image
                                                   completion:^(CGSize cellSize, CGRect titleFrame, CGRect imageFrame) {
        @strongify(category);
        category.cellSize = cellSize;
        category.titleFrame = titleFrame;
        category.imageFrame = imageFrame;
    }];
    
    if (category.selectedIconUrls.count > 0) {
        @weakify(self);
        NSArray *selectedIconUrls = category.selectedIconUrls;
        [ACCWebImage() requestImageWithURLArray:selectedIconUrls completion:^(UIImage *image, NSURL *url, NSError *error) {
            @strongify(self);
            @strongify(category);
            if (!image || error || !url) {
                AWELogToolError(AWELogToolTagNone, @"requestImageWithURLArray failed, error=%@", error);
                return;
            }
            category.image = image;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tabViewLayout categoryViewLayoutWithContainerHeight:40
                                                                    title:category.categoryName
                                                                    image:category.image
                                                               completion:^(CGSize cellSize, CGRect titleFrame, CGRect imageFrame) {
                    @strongify(category);
                    category.cellSize = cellSize;
                    category.titleFrame = titleFrame;
                    category.imageFrame = imageFrame;
                    
                    if (self.tabSizeUpdateHandler) {
                        self.tabSizeUpdateHandler(tabIndex);
                    }
                }];
            });
        }];
    }
}

// 每次请求到tab下的道具列表都执行一次merge，知道成功merge到hot分类下
- (void)mergeWithInsertStickers:(id<AWEStickerPickerDataContainerProtocol>)dataContainer {
    AWELogToolDebug(AWELogToolTagNone, @"start merge insert stickers");
    
    if (dataContainer.categoryArray.count == 0) {
        return;
    }
    // Find hot tab.
    __block AWEDouyinStickerCategoryModel *hotCategory = nil;
    [dataContainer.categoryArray enumerateObjectsUsingBlock:^(AWEDouyinStickerCategoryModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isHotTab]) {
            hotCategory = obj;
            *stop = YES;
        }
    }];
    
    // 手动插入到“第一个非收藏分类”的首位
    NSArray<IESEffectModel *> *stickers = dataContainer.insertStickers;
    // 插入之前进行数据过滤，如果过滤之后数据为空了，就不再插入了
    stickers = [self filterEffects:stickers category:hotCategory];
    if (stickers.count > 0 && hotCategory) {
        AWELogToolInfo(AWELogToolTagNone, @"insert stickers count=%zi", stickers.count);
        
        // effectIdentifiers need to insert.
        NSMutableSet *effectIdentifierSet = [[NSMutableSet alloc] init];
        [stickers enumerateObjectsUsingBlock:^(IESEffectModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.effectIdentifier.length > 0) {
                [effectIdentifierSet addObject:obj.effectIdentifier];
                [self addEffectsToMap:@[obj]];
            }
        }];
        
        // Insert.
        if (hotCategory.orignalStickers.count > 0) {
            NSMutableArray *stickersCopy = [[NSMutableArray alloc] initWithCapacity:stickers.count + hotCategory.orignalStickers.count];
            [stickersCopy acc_addObjectsFromArray:stickers]; // Insert at head position.
            [hotCategory.orignalStickers enumerateObjectsUsingBlock:^(IESEffectModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (obj.effectIdentifier) {
                    if (![effectIdentifierSet containsObject:obj.effectIdentifier]) {
                        [stickersCopy acc_addObject:obj];
                    }
                }
            }];
            hotCategory.stickers = [stickersCopy copy];
            [self dataContainer:dataContainer updateEffectArrayForCategoryKey:hotCategory.categoryKey effectArray:stickersCopy];
            
            // 插入完之后移除
            dataContainer.insertStickers = nil;
            
            // 通知category的delegate数据源有更新
            if ([hotCategory.delegate respondsToSelector:@selector(stickerCategoryModelDidUpdateStickers:)]) {
                [hotCategory.delegate stickerCategoryModelDidUpdateStickers:hotCategory];
            }
        }
    }
}

- (void)dataContainer:(id<AWEStickerPickerDataContainerProtocol>)dataContainer
       updateFavorite:(BOOL)isFavorite
            effectIDS:(NSArray<NSString *> *)effectIDS {
    if (isFavorite) {
        for (NSString *toToAddId in effectIDS) {
            if (toToAddId.length > 0 && [self.effectMap objectForKey:toToAddId]) {
                IESEffectModel *effectModel = [self.effectMap objectForKey:toToAddId];
                [self dataContainer:dataContainer addEffectToFavorite:effectModel];
            }
        }
    } else {
        NSMutableArray *favoriteEffectArray = [dataContainer.favoriteEffectArray mutableCopy];
        for (NSString *toDeleteId in effectIDS) {
            __block NSInteger toDeleteIdx = -1;
            [favoriteEffectArray enumerateObjectsUsingBlock:^(IESEffectModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([obj.effectIdentifier isEqualToString:toDeleteId]) {
                    toDeleteIdx = idx;
                    *stop = YES;
                }
            }];
            
            if (toDeleteIdx >= 0) {
                [favoriteEffectArray acc_removeObjectAtIndex:toDeleteIdx];
                dataContainer.favoriteEffectArray = [favoriteEffectArray copy];
                dataContainer.favoriteCategoryModel.stickers = dataContainer.favoriteEffectArray;
            }
        }
    }
}

- (void)dataContainer:(id<AWEStickerPickerDataContainerProtocol>)dataContainer
  addEffectToFavorite:(IESEffectModel *)toAddEffectModel {
    BOOL hasSame = NO;
    NSMutableArray *favoriteEffectArray = [dataContainer.favoriteEffectArray mutableCopy];
    for (IESEffectModel *effect in favoriteEffectArray) {
        if ([effect.effectIdentifier isEqualToString:toAddEffectModel.effectIdentifier]) {
            hasSame = YES;
            break;
        }
    }
    
    if (!hasSame) {
        [favoriteEffectArray acc_insertObject:toAddEffectModel atIndex:0];
    }
    dataContainer.favoriteEffectArray = [favoriteEffectArray copy];
    dataContainer.favoriteCategoryModel.stickers = dataContainer.favoriteEffectArray;
}

#pragma mark - Fetch
- (void)fetchCategoryListForPanelName:(NSString *)panelName
                        dataContainer:(id<AWEStickerPickerDataContainerProtocol>)dataContainer
                    completionHandler:(void (^)(NSArray<AWEStickerCategoryModel*> * _Nullable categoryList, NSArray<NSString *> * _Nullable urlPrefix, NSError * _Nullable error))completionHandler {
    
    @weakify(self);
    [dataContainer fetchCategoryListForPanelName:panelName completionHandler:^(NSError * _Nullable error, IESEffectPlatformNewResponseModel * _Nullable response) {
        @strongify(self);
        if (self) {
            dispatch_async(self.dataHanleQueue, ^{
                
                IESEffectPlatformNewResponseModel *responseMode = response;
                if (error) {
                    AWELogToolError(AWELogToolTagNone, @"data source fetch category failed, error=%@", error);
                } else {
                    [self handleCategoryResponse:responseMode panelName:panelName dataContainer:dataContainer];
                }
                
                if (completionHandler) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completionHandler(dataContainer.categoryArray, responseMode.urlPrefix, error);
                    });
                }
            });
        } else {
            if (completionHandler) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionHandler(dataContainer.categoryArray, response.urlPrefix, error);
                });
            }
        }
    }];
}

- (void)fetchEffectListWithPanelName:(NSString *)panelName
                         categoryKey:(NSString *)categoryKey
                       dataContainer:(id<AWEStickerPickerDataContainerProtocol>)dataContainer
                   completionHandler:(void (^)(NSArray<IESEffectModel *> * _Nullable effectList, NSError * _Nullable error))completionHandler {
    @weakify(self);
    [EffectPlatform checkEffectUpdateWithPanel:panelName category:categoryKey effectTestStatusType:ACCConfigInt(kConfigInt_effect_test_status_code) completion:^(BOOL needUpdate) {
        @strongify(self);
        if (self) {
            [self onEffectListCheckUpdateCallback:needUpdate
                                        panelName:panelName
                                      categoryKey:categoryKey
                                    dataContainer:dataContainer
                                completionHandler:completionHandler];
        } else {
            AWELogToolWarn(AWELogToolTagNone, @"data source has dealloc when fetch effect list callback|categoryKey=%@", categoryKey);
            if (completionHandler) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionHandler(nil, nil);
                });
            }
        }
    }];
}

- (void)fetchMyEffectListForPanelName:(NSString *)panelName
                    completionHandler:(void (^)(NSArray<IESEffectModel *> * _Nullable effectList, NSError * _Nullable error))completionHandler {
    @weakify(self);
    [EffectPlatform downloadMyEffectListWithPanel:panelName completion:^(NSError * _Nullable error, NSArray<IESMyEffectModel *> * _Nullable myEffects) {
        @strongify(self);
        if (self) {
            dispatch_async(self.dataHanleQueue, ^{
                for (id<AWEStickerPickerDataContainerProtocol> dataContainer in self.dataContainers) {
                    dataContainer.favoriteEffectArray = [self filterEffects:myEffects.firstObject.effects category:dataContainer.favoriteCategoryModel];
                }
                
                [self addEffectsToMap:myEffects.firstObject.effects];
                // 关联道具
                [self addEffectsToMap:myEffects.firstObject.bindEffects];
                
                if (completionHandler) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completionHandler(self.dataContainer.favoriteEffectArray, error);
                    });
                }
            });
        } else {
            AWELogToolWarn(AWELogToolTagNone, @"data source has dealloc when fetch my callback");
            if (completionHandler) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionHandler(nil, error);
                });
            }
        }
    }];
}

- (void)handleCategoryResponse:(IESEffectPlatformNewResponseModel *)response
                     panelName:(NSString *)panelName
                 dataContainer:(id<AWEStickerPickerDataContainerProtocol>)dataContainer {
    NSArray<AWEDouyinStickerCategoryModel *> *arr = [self transformWithCategories:response.categories panelName:panelName dataContainer:dataContainer];
    dataContainer.categoryArray = [self filterCategories:arr];
    [self mergeWithInsertStickers:dataContainer];
    [self addEffectsToMap:response.categoryEffects.effects];
    // 关联道具
    [self addEffectsToMap:response.categoryEffects.bindEffects];
}

- (void)onEffectListCheckUpdateCallback:(BOOL)needUpdate
                              panelName:(NSString *)panelName
                            categoryKey:(NSString *)categoryKey
                          dataContainer:(id<AWEStickerPickerDataContainerProtocol>)dataContainer
                      completionHandler:(void (^)(NSArray<IESEffectModel *> * _Nullable effectList, NSError * _Nullable error))completionHandler {
    
    dispatch_async(self.dataHanleQueue, ^{
        
        IESEffectPlatformNewResponseModel *cachedResponse = [EffectPlatform cachedEffectsOfPanel:panelName category:categoryKey];
        
        BOOL hasValidCache = cachedResponse.categoryEffects.effects.count > 0;
        
        if (!needUpdate && hasValidCache && dataContainer.effectListUseCache) {
            if (categoryKey.length > 0) {
                NSArray<IESEffectModel *> *filterArray = [self dataContainer:dataContainer filterEffects:cachedResponse.categoryEffects.effects categoryKey:categoryKey];
                [self dataContainer:dataContainer updateEffectArrayForCategoryKey:categoryKey effectArray:filterArray];
            }
            
            [self mergeWithInsertStickers:dataContainer];
            [self addEffectsToMap:cachedResponse.categoryEffects.effects];
            [self addEffectsToMap:cachedResponse.categoryEffects.bindEffects];
            
            if (completionHandler) {
                NSArray<IESEffectModel *> *callbackArray = [self dataContainer:dataContainer effectArrayForCategoryKey:categoryKey];
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionHandler(callbackArray, nil);
                });
            }
        } else {
            @weakify(self);
            [EffectPlatform downloadEffectListWithPanel:panelName
                                               category:categoryKey
                                              pageCount:0
                                                 cursor:0
                                        sortingPosition:0
                                   effectTestStatusType:ACCConfigInt(kConfigInt_effect_test_status_code)
                                             completion:^(NSError * _Nullable error, IESEffectPlatformNewResponseModel * _Nullable response) {
                @strongify(self);
                if (self) {
                    dispatch_async(self.dataHanleQueue, ^{
                        NSArray<IESEffectModel *> *filterArray = [self dataContainer:dataContainer filterEffects:response.categoryEffects.effects categoryKey:categoryKey];
                        if (categoryKey.length > 0) {
                            [self dataContainer:dataContainer updateEffectArrayForCategoryKey:categoryKey effectArray:filterArray];
                        }
                        
                        [self mergeWithInsertStickers:dataContainer];
                        [self addEffectsToMap:response.categoryEffects.effects];
                        [self addEffectsToMap:response.categoryEffects.bindEffects];
                        
                        if (completionHandler) {
                            NSArray<IESEffectModel *> *callbackArray = [self dataContainer:dataContainer effectArrayForCategoryKey:categoryKey];
                            dispatch_async(dispatch_get_main_queue(), ^{
                                completionHandler(callbackArray, error);
                            });
                        }
                    });
                } else {
                    if (completionHandler) {
                        NSArray<IESEffectModel *> *callbackArray = [self dataContainer:dataContainer effectArrayForCategoryKey:categoryKey];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            completionHandler(callbackArray, error);
                        });
                    }
                }
            }];
        }
    });
}


#pragma mark - filter
- (NSArray<AWEDouyinStickerCategoryModel *> *)filterCategories:(NSArray<AWEDouyinStickerCategoryModel *> *)categories {
    
    NSMutableArray *filterResult = [NSMutableArray array];
    if (self.stickerCategoryFilterBlock) {
        for (AWEDouyinStickerCategoryModel *category in categories.copy) {
            if (self.stickerCategoryFilterBlock(category)) {
                [filterResult acc_addObject:category];
            }
        }
    }
    for (AWEDouyinStickerCategoryModel *category in filterResult.copy) {
        category.stickers = [self filterEffects:category.stickers category:category];
    }
    
    return [filterResult copy];
}

- (NSArray<IESEffectModel *> *)dataContainer:(id<AWEStickerPickerDataContainerProtocol>)dataContainer
                               filterEffects:(NSArray<IESEffectModel *> *)effects
                                 categoryKey:(NSString *)categoryKey {
    AWEDouyinStickerCategoryModel *category = nil;
    for (AWEDouyinStickerCategoryModel *model in dataContainer.categoryArray) {
        if ([model.categoryKey isEqualToString:categoryKey]) {
            category = model;
            break;
        }
    }
    
    return [self filterEffects:effects category:category];
}

- (NSArray<IESEffectModel *> *)filterEffects:(NSArray<IESEffectModel *> *)effects category:(AWEDouyinStickerCategoryModel *)category {
    if (self.stickerFilterBlock && category) {
        NSMutableArray *filterArray = [NSMutableArray array];
        for (IESEffectModel *effect in effects) {
            if (self.stickerFilterBlock(effect, category)) {
                [filterArray acc_addObject:effect];
            }
        }
        
        return [filterArray copy];
    }
    return [effects copy];
}

#pragma mark - AWEStickerPickerControllerDataSource
- (BOOL)categoryListIsLoading
{
    @synchronized (self) {
        return self.dataContainer.loading;
    }
}

- (NSArray<AWEDouyinStickerCategoryModel *> *)categoryArray
{
    @synchronized (self) {
        return self.dataContainer.categoryArray;
    }
}

- (void)stickerPickerController:(AWEStickerPickerController *)stickerPickerController
  fetchCategoryListForPanelName:(NSString *)panelName
              completionHandler:(void (^)(NSArray<AWEStickerCategoryModel* > * _Nullable categoryList, NSArray<NSString *> * _Nullable urlPrefix, NSError * _Nullable error))completionHandler {
    @weakify(self);
    id<AWEStickerPickerDataContainerProtocol> dataContainer = self.dataContainer;
    [self fetchCategoryListForPanelName:panelName dataContainer:dataContainer completionHandler:^(NSArray<AWEStickerCategoryModel *> * _Nullable categoryList, NSArray<NSString *> * _Nullable urlPrefix, NSError * _Nullable error) {
        @strongify(self);
        // dataContainer存在切换情况，如果不相等就不回调了
        if (dataContainer == self.dataContainer) {
            ACCBLOCK_INVOKE(completionHandler, categoryList, urlPrefix, error);
        }
    }];
}

- (void)stickerPickerController:(AWEStickerPickerController *)stickerPickerController
    fetchEffectListForPanelName:(NSString *)panelName
                    categoryKey:(NSString *)categoryKey
              completionHandler:(void (^)(NSArray<IESEffectModel *> * _Nullable effectList, NSError * _Nullable error))completionHandler {
    @weakify(self);
    id<AWEStickerPickerDataContainerProtocol> dataContainer = self.dataContainer;
    [self fetchEffectListWithPanelName:panelName categoryKey:categoryKey dataContainer:dataContainer completionHandler:^(NSArray<IESEffectModel *> * _Nullable effectList, NSError * _Nullable error) {
        @strongify(self);
        if (dataContainer == self.dataContainer) {
            ACCBLOCK_INVOKE(completionHandler, effectList, error);
        }
    }];
}

- (void)stickerPickerController:(AWEStickerPickerController *)stickerPickerController
      fetchFavoriteForPanelName:(NSString *)panelName
              completionHandler:(void (^)(NSArray<IESEffectModel *> * _Nullable, NSError * _Nullable error))completionHandler {
    [self fetchMyEffectListForPanelName:panelName completionHandler:^(NSArray<IESEffectModel *> * _Nullable effectList, NSError * _Nullable error) {
        ACCBLOCK_INVOKE(completionHandler, effectList, error);
    }];
}

- (void)stickerPickerController:(AWEStickerPickerController *)stickerPickerController
    changeFavoriteWithEffectIDs:(NSArray<NSString *> *)effectIDS
                      panelName:(NSString *)panelName
                       favorite:(BOOL)favorite
              completionHandler:(void (^)(NSError * _Nullable error))completionHandler {
    @weakify(self);
    
    [EffectPlatform changeEffectsFavoriteWithEffectIDs:effectIDS
                                                 panel:panelName
                                         addToFavorite:favorite
                                            completion:^(BOOL success, NSError * _Nullable error) {
        @strongify(self);
        if (self) {
            dispatch_async(self.dataHanleQueue, ^{
                if (!error) {
                    for (id<AWEStickerPickerDataContainerProtocol> dataContainer in self.dataContainers) {
                        [self dataContainer:dataContainer updateFavorite:favorite effectIDS:effectIDS];
                    }
                }
                if (completionHandler) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completionHandler(error);
                    });
                }
            });
        } else {
            if (completionHandler) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionHandler(error);
                });
            }
        }
    }];
}

#pragma mark - AB Experiments
- (ACCPropPanelSearchEntranceType)shouldSupportSearchFeature
{
    if ([[ACCPropExploreExperimentalControl sharedInstance] hiddenSearchEntry])  {
        return ACCPropPanelSearchEntranceTypeNone;
    }
    return ACCConfigEnum(kConfigInt_new_search_effect_config, ACCPropPanelSearchEntranceType);
}

@end
