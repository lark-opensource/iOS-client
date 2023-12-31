//
//  ACCGrootStickerConfig.h
//  CameraClient-Pods-Aweme
//
//  Created by 饶骏华 on 2021/5/14.
//

#import "ACCCommonStickerConfig.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCGrootStickerConfig : ACCCommonStickerConfig

@property (nonatomic, copy) void (^editText)(void);

@end

NS_ASSUME_NONNULL_END
