//
//  ACCModernPOIStickerConfig.h
//  CameraClient-Pods-Aweme
//
//  Created by 卜旭阳 on 2020/10/21.
//

#import "ACCCommonStickerConfig.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCModernPOIStickerConfig : ACCCommonStickerConfig

@property (nonatomic, copy) void (^editPOI)(void);

@end

NS_ASSUME_NONNULL_END
