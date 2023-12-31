//
//  AWEStickerPickerModel.m
//  CameraClient
//
//  Created by zhangchengtao on 2019/12/16.
//

#import "AWEStickerPickerModel.h"
#import "AWEStickerDownloadManager.h"
#import "AWEStickerPickerLogMarcos.h"
#import "AWEDouyinStickerCategoryModel.h"
#import "ACCPropExploreExperimentalControl.h"

#import <CameraClient/ACCConfigKeyDefines.h>
#import <EffectPlatformSDK/EffectPlatform.h>

@interface AWEStickerPickerModel () <AWEStickerCategoryModelDelegate, AWEStickerCategoryModelDataSource, AWEStickerDownloadObserverProtocol>

@property (nonatomic, copy, readwrite) NSString *panelName;

@property (nonatomic, readwrite, getter=isLoading) BOOL loading;

@property (nonatomic, copy, readwrite) NSArray<NSString *> *urlPrefix;

@property (nonatomic, strong) NSMutableDictionary *bindStickerMap; // 关联道具查询表

@property (nonatomic, assign) BOOL hotTabChanged;

@end

@implementation AWEStickerPickerModel

- (instancetype)initWithPanelName:(NSString *)panelName
                   currentSticker:(IESEffectModel * _Nullable)currentSticker
              currentChildSticker:(IESEffectModel * _Nullable)currentChildSticker
{
    if (self = [super init]) {
        _panelName = [panelName copy];
        _currentSticker = currentSticker;
        _currentChildSticker = currentChildSticker;
        _loading = NO;
        _bindStickerMap = [[NSMutableDictionary alloc] init];
        [self initSearchProperties];
        [[AWEStickerDownloadManager manager] addObserver:self];
    }
    return self;
}

- (void)initSearchProperties
{
    _isUseHot = NO;
    _isFromHashtag = NO;
    _isCompleted = YES;

    _searchText = @"";
    _searchID = @"";
    _searchTips = @"";
    _searchMethod = @"";

    _recommendationList = @[@"变漫画", @"潜水艇小游戏"];
}

- (void)resetHotTab
{
    if (!self.hotTabChanged) {
        return;
    }
    __block AWEStickerCategoryModel *category = nil;
    [self.stickerCategoryModels enumerateObjectsUsingBlock:^(AWEStickerCategoryModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (!obj.favorite && !obj.isSearch) {
            category = obj;
            *stop = YES;
        }
    }];
    category.stickers = [category.orignalStickers copy];
    
    // 通知category的delegate数据源有更新
    if ([category.delegate respondsToSelector:@selector(stickerCategoryModelDidUpdateStickers:)]) {
        [category.delegate stickerCategoryModelDidUpdateStickers:category];
    }
    self.hotTabChanged = NO;
}

- (void)insertStickersAtHotTab:(NSArray<IESEffectModel *> *)stickers {
    // 手动插入到“第一个非收藏分类”的首位
    if (stickers.count > 0) {
        // effectIdentifiers need to insert.
        NSMutableSet *effectIdentifierSet = [[NSMutableSet alloc] init];
        [stickers enumerateObjectsUsingBlock:^(IESEffectModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.effectIdentifier) {
                [effectIdentifierSet addObject:obj.effectIdentifier];
            }
        }];
        
        // Find hot tab.
        __block AWEStickerCategoryModel *category = nil;
        [self.stickerCategoryModels enumerateObjectsUsingBlock:^(AWEStickerCategoryModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (!obj.favorite && !obj.isSearch) {
                category = obj;
                *stop = YES;
            }
        }];
        
        // Insert.
        if (category.orignalStickers.count > 0) {
            NSMutableArray *stickersCopy = [[NSMutableArray alloc] initWithCapacity:stickers.count + category.orignalStickers.count];
            [stickersCopy addObjectsFromArray:stickers]; // Insert at head position.
            [category.orignalStickers enumerateObjectsUsingBlock:^(IESEffectModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (obj.effectIdentifier) {
                    if (![effectIdentifierSet containsObject:obj.effectIdentifier]) {
                        [stickersCopy addObject:obj];
                    }
                }
            }];
            category.stickers = [stickersCopy copy];
            
            // 通知category的delegate数据源有更新
            if ([category.delegate respondsToSelector:@selector(stickerCategoryModelDidUpdateStickers:)]) {
                [category.delegate stickerCategoryModelDidUpdateStickers:category];
            }
            self.hotTabChanged = YES;
        }
    }
}

- (BOOL)isLoaded {
    if (self.stickerCategoryModels.count > 0) {
        return YES;
    }
    return NO;
}

- (AWEStickerCategoryModel *)searchCategoryModel
{
    if (!_searchCategoryModel) {
        if ([self shouldSupportSearchFeature] == ACCPropPanelSearchEntranceTypeTab) {
            __block AWEStickerCategoryModel *category = nil;
            [self.stickerCategoryModels enumerateObjectsUsingBlock:^(AWEStickerCategoryModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (obj.isSearch) {
                    category = obj;
                    *stop = YES;
                }
            }];
            _searchCategoryModel = category;
        } else {
            _searchCategoryModel = [AWEDouyinStickerCategoryModel searchCategoryModel];
        }
    }
    return _searchCategoryModel;
}

- (void)loadStickerCategoryList {
    self.stickerCategoryModels = nil;
    if ([self.dataSource respondsToSelector:@selector(stickerPickerModel:fetchCategoryListForPanelName:completionHandler:)]) {
        
        if (self.dataSource.categoryListIsLoading) {
            AWEStickerPickerLogWarn(@"skip load category list");
            return;
        }
        
        if ([self.delegate respondsToSelector:@selector(stickerPickerModelDidBeginLoadCategories:)]) {
            [self.delegate stickerPickerModelDidBeginLoadCategories:self];
        }
        
        @weakify(self);
        [self.dataSource stickerPickerModel:self
              fetchCategoryListForPanelName:self.panelName
                          completionHandler:^(NSArray<AWEStickerCategoryModel *> * _Nullable categoryList, NSArray<NSString *> * _Nullable urlPrefix, NSError * _Nullable error) {
            @strongify(self);
            AWEStickerPickerLogInfo(@"fetch category list|panelName=%@|category count=%zi", self.panelName, categoryList.count);
            
            self.urlPrefix = urlPrefix;
            self.stickerCategoryModels = categoryList.copy;
            self.currentCategoryModel = self.stickerCategoryModels.firstObject;
            for (AWEStickerCategoryModel *category in categoryList) {
                if (self.dataSource) {
                    category.dataSource = self;
                }
                category.delegate = self;
            }
            
            if (!error) {
                if ([self.delegate respondsToSelector:@selector(stickerPickerModelDidFinishLoadCategories:)]) {
                    [self.delegate stickerPickerModelDidFinishLoadCategories:self];
                }
            } else {
                if ([self.delegate respondsToSelector:@selector(stickerPickerModelDidFailLoadCategories:withError:)]) {
                    [self.delegate stickerPickerModelDidFailLoadCategories:self withError:error];
                }
            }
        }];
    } else {
        
        if (self.isLoading) {
            AWEStickerPickerLogWarn(@"skip load category list");
            return;
        }
        self.loading = YES;
        if ([self.delegate respondsToSelector:@selector(stickerPickerModelDidBeginLoadCategories:)]) {
            [self.delegate stickerPickerModelDidBeginLoadCategories:self];
        }
        [self fetchStickerCategoryListInternal];
    }
}

- (void)loadStickerCategoryListIfNeeded
{
    if (self.dataSource.categoryArray.count > 0) {
        self.stickerCategoryModels = self.dataSource.categoryArray.copy;
        self.currentCategoryModel = self.stickerCategoryModels.firstObject;
        for (AWEStickerCategoryModel *category in self.stickerCategoryModels) {
            if (self.dataSource) {
                category.dataSource = self;
            }
            category.delegate = self;
        }
        if ([self.delegate respondsToSelector:@selector(stickerPickerModelDidFinishLoadCategories:)]) {
            [self.delegate stickerPickerModelDidFinishLoadCategories:self];
        }
        return;
    }
    
    [self loadStickerCategoryList];
}

- (void)setCurrentSticker:(IESEffectModel *)currentSticker {
    if (_currentSticker != currentSticker) {
        if ([self.delegate respondsToSelector:@selector(stickerPickerModel:shouldApplySticker:)] &&
            ![self.delegate stickerPickerModel:self shouldApplySticker:currentSticker]) {
            return;
        }
        
        IESEffectModel *oldSticker = _currentSticker;
        _currentSticker = currentSticker;
        if ([self.delegate respondsToSelector:@selector(stickerPickerModelDidSelectNewSticker:oldSticker:)]) {
            [self.delegate stickerPickerModelDidSelectNewSticker:currentSticker oldSticker:oldSticker];
        }
    }
}

- (void)downloadStickerIfNeed:(IESEffectModel *)effectModel {
    [[AWEStickerDownloadManager manager] downloadStickerIfNeed:effectModel];
}

- (void)updateDownloadedCell:(IESEffectModel *)effectModel {
    [[AWEStickerDownloadManager manager] updatePropCellDownloaded:effectModel];
}

#pragma mark - private
- (BOOL)isLoading
{
    if (self.dataSource) {
        return self.dataSource.categoryListIsLoading;
    }
    return _loading;
}

- (void)fetchStickerCategoryListInternal {
    @weakify(self);
    [EffectPlatform checkPanelUpdateWithPanel:self.panelName effectTestStatusType:ACCConfigInt(kConfigInt_effect_test_status_code) completion:^(BOOL needUpdate) {
        @strongify(self);
        if (!self) {
            return;
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            IESEffectPlatformNewResponseModel *cachedResponse = [EffectPlatform cachedCategoriesOfPanel:self.panelName];
            dispatch_async(dispatch_get_main_queue(), ^{
                BOOL hasValidCache = cachedResponse.categories.count > 0;
                if (!needUpdate && hasValidCache) {
                    [self handleWithCategories:cachedResponse.categories urlPrefix:cachedResponse.urlPrefix error:nil];
                    self.loading = NO;
                } else {
                    @weakify(self);
                    [EffectPlatform fetchCategoriesListWithPanel:self.panelName
                                    isLoadDefaultCategoryEffects:YES
                                                 defaultCategory:@""
                                                       pageCount:0
                                                          cursor:0
                                                       saveCache:YES
                                            effectTestStatusType:ACCConfigInt(kConfigInt_effect_test_status_code)
                                                      completion:^(NSError * _Nullable error, IESEffectPlatformNewResponseModel * _Nullable response) {
                        @strongify(self);
                        if (!self) {
                            return;
                        }
                        
                        [self handleWithCategories:response.categories urlPrefix:response.urlPrefix error:error];
                        self.loading = NO;
                    }];
                }
            });
        });
    }];
}

- (void)handleWithCategories:(NSArray <IESCategoryModel *> *)categories urlPrefix:(NSArray<NSString *> *)urlPrefix error:(NSError *)error {
    if (categories.count > 0) {
        self.urlPrefix = urlPrefix;
        NSMutableArray *stickerCategoryModels = [[NSMutableArray alloc] init];
        // 插入道具分类
        for (IESCategoryModel *categoryModel in categories) {
            AWEStickerCategoryModel *category = [[AWEStickerCategoryModel alloc] initWithIESCategoryModel:categoryModel];
            category.panelName = self.panelName;
            category.orignalStickers = category.stickers;
            if (self.dataSource) {
                category.dataSource = self;
            }
            category.delegate = self;
            [stickerCategoryModels addObject:category];
        }
        
        self.stickerCategoryModels = stickerCategoryModels.copy;
        self.currentCategoryModel = self.stickerCategoryModels.firstObject;
        
        if ([self.delegate respondsToSelector:@selector(stickerPickerModelDidFinishLoadCategories:)]) {
            [self.delegate stickerPickerModelDidFinishLoadCategories:self];
        }
    } else {
        if ([self.delegate respondsToSelector:@selector(stickerPickerModelDidFailLoadCategories:withError:)]) {
            [self.delegate stickerPickerModelDidFailLoadCategories:self withError:error];
        }
    }
    
    AWEStickerPickerLogInfo(@"handleWithCategories|self.stickerCategoryModels.count=%zi", self.stickerCategoryModels.count);
}

- (AWEStickerCategoryModel *)favoriteCategoryModel
{
    return self.dataSource.favoriteCategoryModel;
}

/// 没找到则返回 NSNotFound
- (NSInteger)tabIndexForCategoryModel:(AWEStickerCategoryModel *)categoryModel {
    __block NSInteger index = NSNotFound;
    [self.stickerCategoryModels enumerateObjectsUsingBlock:^(AWEStickerCategoryModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ((obj.favorite && categoryModel.favorite) || obj == categoryModel) {
            index = idx;
            *stop = YES;
        }
    }];
    
    if (index == NSNotFound) {
        
    }
    return index;
}

#pragma mark - AWEStickerCategoryModelDelegate

- (void)stickerCategoryModelDidBeginLoadStickers:(AWEStickerCategoryModel *)categoryModel {
    if ([self.delegate respondsToSelector:@selector(stickerPickerModel:didBeginLoadStickersWithCategory:tabIndex:)]) {
        NSInteger tabIndex = [self tabIndexForCategoryModel:categoryModel];
        if (tabIndex != NSNotFound) {
            [self.delegate stickerPickerModel:self didBeginLoadStickersWithCategory:categoryModel tabIndex:tabIndex];
        }
    }
}

- (void)stickerCategoryModelDidFinishLoadStickers:(AWEStickerCategoryModel *)categoryModel {
    if ([self.delegate respondsToSelector:@selector(stickerPickerModel:didFinishLoadStickersWithCategory:tabIndex:)]) {
        NSInteger tabIndex = [self tabIndexForCategoryModel:categoryModel];
        if (tabIndex != NSNotFound) {
            [self.delegate stickerPickerModel:self didFinishLoadStickersWithCategory:categoryModel tabIndex:tabIndex];
        }
    }
}

- (void)stickerCategoryModelDidFailLoadStickers:(AWEStickerCategoryModel *)categoryModel withError:(NSError *)error {
    if ([self.delegate respondsToSelector:@selector(stickerPickerModel:didFailLoadStickersWithCategory:tabIndex:error:)]) {
        NSInteger tabIndex = [self tabIndexForCategoryModel:categoryModel];
        if (tabIndex != NSNotFound) {
            [self.delegate stickerPickerModel:self didFailLoadStickersWithCategory:categoryModel tabIndex:tabIndex error:error];
        }
    }
}

- (void)stickerCategoryModelDidUpdateStickers:(AWEStickerCategoryModel *)categoryModel {
    if ([self.delegate respondsToSelector:@selector(stickerPickerModel:didUpdateStickersWithCategory:tabIndex:)]) {
        NSInteger tabIndex = [self tabIndexForCategoryModel:categoryModel];
        if (tabIndex != NSNotFound) {
            [self.delegate stickerPickerModel:self didUpdateStickersWithCategory:categoryModel tabIndex:tabIndex];
        }
    }
}

#pragma mark - AWEStickerCategoryModelDataSource

- (void)stickerCategoryModel:(AWEStickerCategoryModel *)categoryModel
   fetchFavoriteForPanelName:(NSString *)panelName
           completionHandler:(void (^)(NSArray<IESEffectModel *> * _Nullable, NSError * _Nullable))completionHandler {
    if ([self.dataSource respondsToSelector:@selector(stickerPickerModel:fetchFavoriteForPanelName:completionHandler:)]) {
        [self.dataSource stickerPickerModel:self fetchFavoriteForPanelName:panelName completionHandler:^(NSArray<IESEffectModel *> * _Nullable effectList, NSError * _Nullable error) {
            if (completionHandler) {
                completionHandler(effectList, error);
            }
        }];
    } else {
        NSAssert(NO, @"dataSource has not implement method!!");
        NSError *error = [NSError errorWithDomain:@"com.aweme.cameraclient.sticker" code:-1 userInfo:@{
            NSLocalizedFailureReasonErrorKey: @"dataSource has not implement method",
        }];
        
        if (completionHandler) {
            completionHandler(nil, error);
        }
    }
}

- (void)stickerCategoryModel:(AWEStickerCategoryModel *)categoryModel
 fetchEffectListForPanelName:(NSString *)panelName
                 categoryKey:(NSString *)categoryKey
           completionHandler:(void (^)(NSArray<IESEffectModel *> * _Nullable, NSError * _Nullable))completionHandler {
    if ([self.dataSource respondsToSelector:@selector(stickerPickerModel:fetchEffectListForPanelName:categoryKey:completionHandler:)]) {
        [self.dataSource stickerPickerModel:self fetchEffectListForPanelName:panelName categoryKey:categoryKey completionHandler:completionHandler];
    } else {
        NSAssert(NO, @"dataSource has not implement method!!");
        NSError *error = [NSError errorWithDomain:@"com.aweme.cameraclient.sticker" code:-1 userInfo:@{
            NSLocalizedFailureReasonErrorKey: @"dataSource has not implement method",
        }];
        if (completionHandler) {
            completionHandler(nil, error);
        }
    }
}


#pragma mark - AWEStickerDownloadObserverProtocol

- (void)stickerDownloadManager:(AWEStickerDownloadManager *)manager didBeginDownloadSticker:(IESEffectModel *)sticker {
    if ([self.delegate respondsToSelector:@selector(stickerPickerModel:didBeginDownloadSticker:)]) {
        [self.delegate stickerPickerModel:self didBeginDownloadSticker:sticker];
    }
}

- (void)stickerDownloadManager:(AWEStickerDownloadManager *)manager didFinishDownloadSticker:(IESEffectModel *)sticker {
    if ([self.delegate respondsToSelector:@selector(stickerPickerModel:didFinishDownloadSticker:)]) {
        [self.delegate stickerPickerModel:self didFinishDownloadSticker:sticker];
    }
    
    if ([sticker.effectIdentifier isEqualToString:self.stickerWillSelect.effectIdentifier]) {
        self.currentSticker = sticker;
    }
}

- (void)stickerDownloadManager:(AWEStickerDownloadManager *)manager didFailDownloadSticker:(IESEffectModel *)sticker withError:(NSError *)error {
    if ([self.delegate respondsToSelector:@selector(stickerPickerModel:didFailDownloadSticker:withError:)]) {
        [self.delegate stickerPickerModel:self didFailDownloadSticker:sticker withError:error];
    }
}

#pragma mark - AB Experiment

- (ACCPropPanelSearchEntranceType)shouldSupportSearchFeature
{
    if ([[ACCPropExploreExperimentalControl sharedInstance] hiddenSearchEntry])  {
        return ACCPropPanelSearchEntranceTypeNone;
    }
    return ACCConfigEnum(kConfigInt_new_search_effect_config, ACCPropPanelSearchEntranceType);
}

@end
