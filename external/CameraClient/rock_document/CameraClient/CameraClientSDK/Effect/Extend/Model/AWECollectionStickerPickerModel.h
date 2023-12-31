//
//  AWECollectionStickerPickerModel.h
//  CameraClient
//
//  Created by zhangchengtao on 2020/4/14.
//

#import <Foundation/Foundation.h>
#import <EffectPlatformSDK/IESEffectModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface AWECollectionStickerPickerModel : NSObject

@property (nonatomic, copy) NSArray<IESEffectModel *> *stickers;

@property (nonatomic, strong, nullable) IESEffectModel *currentSticker; // 当前选中的道具

@property (nonatomic, strong, nullable) IESEffectModel *stickerWillSelect; // 即将选中的道具，当前正在下载中

@end

NS_ASSUME_NONNULL_END
