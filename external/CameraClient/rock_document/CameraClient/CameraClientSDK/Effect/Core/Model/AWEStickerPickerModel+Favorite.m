//
//  AWEStickerPickerModel+Favorite.m
//  CameraClient
//
//  Created by zhangchengtao on 2020/4/23.
//

#import "AWEStickerPickerModel+Favorite.h"
#import <EffectPlatformSDK/EffectPlatform.h>

@implementation AWEStickerPickerModel (Favorite)

- (BOOL)isMyFavoriteSticker:(IESEffectModel *)sticker {
    __block BOOL isFavorite = NO;
    if (self.favoriteCategoryModel.stickers.count > 0) {
        [self.favoriteCategoryModel.stickers enumerateObjectsUsingBlock:^(IESEffectModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.effectIdentifier isEqualToString:sticker.effectIdentifier]) {
                isFavorite = YES;
                *stop = YES;
            }
        }];
    }
    
    return isFavorite;
}

- (void)updateSticker:(IESEffectModel *)sticker favoriteStatus:(BOOL)selected completion:(void (^ _Nullable)(BOOL success, NSError * _Nullable error))completion {
    if (self.dataSource) {
        [self.dataSource stickerPickerModel:self
                changeFavoriteWithEffectIDs:@[sticker.effectIdentifier]
                                  panelName:self.panelName
                                   favorite:selected
                          completionHandler:^(NSError * _Nullable error) {
            if (error == nil) {
                // 通过delegate通知收藏面板更新UI
                if ([self.favoriteCategoryModel.delegate respondsToSelector:@selector(stickerCategoryModelDidUpdateStickers:)]) {
                    [self.favoriteCategoryModel.delegate stickerCategoryModelDidUpdateStickers:self.favoriteCategoryModel];
                }
            }
            
            if (completion) {
                completion(error == nil, error);
            }
            
            if ([self.delegate respondsToSelector:@selector(stickerPickerModelDidUpdateSticker:favoriteStatus:error:)]) {
                [self.delegate stickerPickerModelDidUpdateSticker:sticker favoriteStatus:selected error:error];
            }
        }];
    } else {
        @weakify(self);
        [EffectPlatform changeEffectsFavoriteWithEffectIDs:@[sticker.effectIdentifier]
                                                     panel:self.panelName
                                             addToFavorite:selected
                                                completion:^(BOOL success, NSError * _Nullable error) {
            @strongify(self);
            [self handleResponse:success error:error sticker:sticker favorite:selected completion:completion];
        }];
    }
}

- (void)handleResponse:(BOOL)success
                 error:(NSError *)error
               sticker:(IESEffectModel *)sticker
              favorite:(BOOL)favorite
            completion:(void (^ _Nullable)(BOOL success, NSError * _Nullable error))completion
{
    if (success && !error) {
        // 更新收藏面板数据
        if (favorite) {
            [self p_insertStickerToFavorite:sticker];
        } else {
            [self p_deleteStickerFromFavorite:sticker];
        }
    }
    
    if (completion) {
        completion(success, error);
    }
    
    if ([self.delegate respondsToSelector:@selector(stickerPickerModelDidUpdateSticker:favoriteStatus:error:)]) {
        [self.delegate stickerPickerModelDidUpdateSticker:sticker favoriteStatus:favorite error:error];
    }
}

- (void)p_insertStickerToFavorite:(IESEffectModel *)sticker {
    if (!sticker) {
        return;
    }

    if (self.favoriteCategoryModel) {
        NSMutableArray *stickers = [[NSMutableArray alloc] init];
        [stickers addObject:sticker];
        if (self.favoriteCategoryModel.stickers.count > 0) {
            [stickers addObjectsFromArray:self.favoriteCategoryModel.stickers];
        }
        self.favoriteCategoryModel.stickers = stickers;

        // 通过delegate通知收藏面板更新UI
        if ([self.favoriteCategoryModel.delegate respondsToSelector:@selector(stickerCategoryModelDidUpdateStickers:)]) {
            [self.favoriteCategoryModel.delegate stickerCategoryModelDidUpdateStickers:self.favoriteCategoryModel];
        }
    }
}

- (void)p_deleteStickerFromFavorite:(IESEffectModel *)sticker {
    if (!sticker) {
        return;
    }

    if (self.favoriteCategoryModel.stickers.count > 0) {
        NSMutableArray *stickers = [[NSMutableArray alloc] initWithArray:self.favoriteCategoryModel.stickers];
        NSUInteger index = [stickers indexOfObject:sticker];
        if (NSNotFound != index) {
            [stickers removeObjectAtIndex:index];
            self.favoriteCategoryModel.stickers = stickers;

            // 通过delegate通知收藏面板更新UI
            if ([self.favoriteCategoryModel.delegate respondsToSelector:@selector(stickerCategoryModelDidUpdateStickers:)]) {
                [self.favoriteCategoryModel.delegate stickerCategoryModelDidUpdateStickers:self.favoriteCategoryModel];
            }
        }
    }
}

@end
