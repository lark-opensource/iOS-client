//
//  ACCSocialStickerConfig.h
//  CameraClient-Pods-Aweme-CameraResource_base
//
//  Created by qiuhang on 2020/8/5.
//

#import "ACCCommonStickerConfig.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCSocialStickerConfig : ACCCommonStickerConfig

@property (nonatomic, copy) void (^editText)(void);
@property (nonatomic, copy) void (^selectTime)(void);

@end

NS_ASSUME_NONNULL_END
