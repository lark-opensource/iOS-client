//
//  ACCLiveStickerConfig.h
//  CameraClient-Pods-Aweme
//
//  Created by 卜旭阳 on 2021/1/4.
//

#import "ACCCommonStickerConfig.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCLiveStickerConfig : ACCCommonStickerConfig

@property (nonatomic, copy, nullable) dispatch_block_t editLive;

@end

NS_ASSUME_NONNULL_END
