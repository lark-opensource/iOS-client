//
//  IESEffectModel+DStickerAddditions.h
//  CameraClient-Pods-CameraClient
//
//  Created by Howie He on 2021/3/22.
//

#import <EffectPlatformSDK/IESEffectModel.h>
#import <CreationKitArch/IESEffectModel+ACCSticker.h>

NS_ASSUME_NONNULL_BEGIN

@interface IESEffectModel (DStickerAddditions)

- (BOOL)isDouyinCard; // 抖音卡专属贴纸
- (BOOL)karaokeBanned; //  K歌场景下不支持该道具
- (BOOL)forbidFavorite; // 不支持收藏
- (BOOL)needReloadWhenApply;

- (BOOL)isFlowerBooking; // 春节预约道具
- (BOOL)isFlowerProp; // 春节活动道具
- (BOOL)isFlowerPropAduit; // 提审道具
- (BOOL)isGrootProp; // groot道具
@end

NS_ASSUME_NONNULL_END
