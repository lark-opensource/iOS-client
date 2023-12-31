//
//  AWEStickerPickerModel+Favorite.h
//  CameraClient
//
//  Created by zhangchengtao on 2020/4/23.
//

#import "AWEStickerPickerModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface AWEStickerPickerModel (Favorite)

/**
 * 判断道具是否是我的收藏道具
 */
- (BOOL)isMyFavoriteSticker:(IESEffectModel *)sticker;

/**
 * 添加道具到我的收藏，或者从我的收藏删除道具
 * @param sticker 道具
 * @param selected YES表示添加，NO表示删除
 * @param completion 回调block
 */
- (void)updateSticker:(IESEffectModel *)sticker favoriteStatus:(BOOL)selected completion:(void (^ _Nullable)(BOOL success, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
