//
//  AWEStickerCategoryModel.m
//  CameraClient
//
//  Created by zhangchengtao on 2020/4/23.
//

#import "AWEStickerCategoryModel.h"
#import <CameraClient/ACCConfigKeyDefines.h>
#import <EffectPlatformSDK/EffectPlatform.h>

@interface AWEStickerCategoryModel ()

@property (atomic, assign, getter=isLoading) BOOL loading;

@property (nonatomic, strong) IESCategoryModel *categoryModel;

@property (nonatomic, strong) AWEStickerCategoryModel *favoriteCategoryModel;

@end

@implementation AWEStickerCategoryModel

- (instancetype)initWithIESCategoryModel:(IESCategoryModel *)model {
    if (self = [super init]) {
        self.categoryIdentifier = model.categoryIdentifier;
        self.categoryKey = model.categoryKey;
        self.categoryName = model.categoryName;
        self.favorite = NO;
        self.isSearch = NO;
        self.stickers = model.effects;
        self.normalIconUrls = [model.normalIconUrls copy];
        self.categoryModel = model;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    AWEStickerCategoryModel *copy = [[self.class allocWithZone:zone] init];
    copy.categoryIdentifier = [self.categoryIdentifier copy];
    copy.categoryKey = [self.categoryKey copy];
    copy.categoryName = [self.categoryName copy];
    copy.favorite = self.favorite;
    copy.isSearch = self.isSearch;
    copy.loading = self.isLoading;
    copy.stickers = [self.stickers copy];
    copy.normalIconUrls = [self.normalIconUrls copy];
    copy.categoryModel = [self.categoryModel copy];
    return copy;
}

- (void)loadStickerListIfNeeded {
    // 已加载或正在加载
    if (self.stickers.count > 0 || self.isLoading) {
        return;
    }
    
    self.loading = YES;
    if ([self.delegate respondsToSelector:@selector(stickerCategoryModelDidBeginLoadStickers:)]) {
        [self.delegate stickerCategoryModelDidBeginLoadStickers:self];
    }

    if (self.isSearch) {
        // do nothing
    } else if (self.favorite) {
        [self fetchFavorite];
    } else {
        [self fetchEffectList];
    }
}

- (void)setStickers:(NSArray<IESEffectModel *> *)stickers {
    if (_stickers != stickers) {
        if (self.stickerFilterBlock) {
            NSMutableArray *stickersCopy = [[NSMutableArray alloc] initWithCapacity:stickers.count];
            [stickers enumerateObjectsUsingBlock:^(IESEffectModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (self.stickerFilterBlock(obj, self)) {
                    [stickersCopy addObject:obj];
                }
            }];
            _stickers = [stickersCopy copy];
        } else {
            _stickers = [stickers copy];
        }
    }
}

- (void)markAsReaded {
    [self.categoryModel markAsReaded];
}

- (IESCategoryModel *)category {
    return self.categoryModel;
}

- (BOOL)shouldShowYellowDot {
    return [self.category showRedDotWithTag:@"new"];
}

- (BOOL)isHotTab
{
    return [self.category.categoryKey isEqualToString:@"hot"];
}

#pragma mark - private

- (void)fetchFavorite {
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(stickerCategoryModel:fetchFavoriteForPanelName:completionHandler:)]) {
        [self.dataSource stickerCategoryModel:self fetchFavoriteForPanelName:self.panelName completionHandler:^(NSArray<IESEffectModel *> * _Nullable effectList, NSError * _Nullable error) {
            if ([NSThread isMainThread]) {
                [self handleWitFavoirteEffectList:effectList error:error];
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self handleWitFavoirteEffectList:effectList error:error];
                });
            }
        }];
    } else {
        [self fetchFavoriteInternal];
    }
}

- (void)fetchFavoriteInternal {
    @weakify(self);
    [EffectPlatform downloadMyEffectListWithPanel:self.panelName completion:^(NSError * _Nullable error, NSArray<IESMyEffectModel *> * _Nullable myEffects) {
        @strongify(self);
        if (!self) {
            return;
        }

        [self handleWitFavoirteEffectList:myEffects.firstObject.effects error:error];
    }];
}

- (void)handleWitFavoirteEffectList:(NSArray<IESEffectModel *> *)effectList error:(NSError *)error {
    self.loading = NO;
    if (error == nil) {
        self.stickers = effectList;
        if ([self.delegate respondsToSelector:@selector(stickerCategoryModelDidFinishLoadStickers:)]) {
            [self.delegate stickerCategoryModelDidFinishLoadStickers:self];
        }
    } else {
        self.stickers = effectList;
        if ([self.delegate respondsToSelector:@selector(stickerCategoryModelDidFailLoadStickers:withError:)]) {
            [self.delegate stickerCategoryModelDidFailLoadStickers:self withError:error];
        }
    }
}

- (void)fetchEffectList {
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(stickerCategoryModel:fetchEffectListForPanelName:categoryKey:completionHandler:)]) {
        [self.dataSource stickerCategoryModel:self fetchEffectListForPanelName:self.panelName categoryKey:self.categoryKey completionHandler:^(NSArray<IESEffectModel *> * _Nullable effectList, NSError * _Nullable error) {
            if ([NSThread isMainThread]) {
                [self handleWithEffectList:effectList error:error];
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self handleWithEffectList:effectList error:error];
                });
            }
        }];
    } else {
        [self fetchEffectListInternal];
    }
}

- (void)fetchEffectListInternal {
    @weakify(self);
    [EffectPlatform checkEffectUpdateWithPanel:self.panelName category:self.categoryKey effectTestStatusType:ACCConfigInt(kConfigInt_effect_test_status_code) completion:^(BOOL needUpdate) {
        @strongify(self);
        if (!self) {
            return;
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            IESEffectPlatformNewResponseModel *cachedResponse = [EffectPlatform cachedEffectsOfPanel:self.panelName category:self.categoryKey];
            dispatch_async(dispatch_get_main_queue(), ^{
                BOOL hasValidCache = cachedResponse.categoryEffects.effects.count > 0;
                if (!needUpdate && hasValidCache) {
                    self.stickerListLoadFromCache = YES;
                    [self handleWithEffectList:cachedResponse.categoryEffects.effects error:nil];
                } else {
                    self.stickerListStartTime = CFAbsoluteTimeGetCurrent();
                    @weakify(self);
                    [EffectPlatform downloadEffectListWithPanel:self.panelName
                                                       category:self.categoryKey
                                                      pageCount:0
                                                         cursor:0
                                                sortingPosition:0
                                           effectTestStatusType:ACCConfigInt(kConfigInt_effect_test_status_code)
                                                     completion:^(NSError * _Nullable error, IESEffectPlatformNewResponseModel * _Nullable response) {
                        @strongify(self);
                        if (!self) {
                            return;
                        }
                        
                        self.loading = NO;
                        if (response) {
                            self.stickers = response.categoryEffects.effects;
                            self.stickerListLoadFromCache = NO;
                            if ([self.delegate respondsToSelector:@selector(stickerCategoryModelDidFinishLoadStickers:)]) {
                                [self.delegate stickerCategoryModelDidFinishLoadStickers:self];
                            }
                        } else {
                            if ([self.delegate respondsToSelector:@selector(stickerCategoryModelDidFailLoadStickers:withError:)]) {
                                [self.delegate stickerCategoryModelDidFailLoadStickers:self withError:error];
                            }
                        }
                    }];
                }
            });
        });
    }];
}

- (void)handleWithEffectList:(NSArray<IESEffectModel *> *)effectList error:(NSError *)error {
    self.loading = NO;
    if (error) {
        self.stickers = effectList;
        if ([self.delegate respondsToSelector:@selector(stickerCategoryModelDidFailLoadStickers:withError:)]) {
            [self.delegate stickerCategoryModelDidFailLoadStickers:self withError:error];
        }
    } else {
        self.stickers = effectList;
        if ([self.delegate respondsToSelector:@selector(stickerCategoryModelDidFinishLoadStickers:)]) {
            [self.delegate stickerCategoryModelDidFinishLoadStickers:self];
        }
    }
}

@end
