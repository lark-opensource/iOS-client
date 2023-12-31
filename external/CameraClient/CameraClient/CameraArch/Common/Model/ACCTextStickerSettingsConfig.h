//
//  ACCTextStickerSettingsConfig.h
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2021/4/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCTextStickerSettingsConfig : NSObject

// 单个文字贴纸 最大的mention / hashtag的最大单项绑定个数 已全量 10
+ (NSInteger)singleTextStickerEachSociaMaxBindCount;

// 所有贴纸 共享的最大的mention / hashtag的最大单项绑定个数 已全量 30
+ (NSInteger)allStickerEachSociaMaxBindCount;

@end

NS_ASSUME_NONNULL_END
