//
//  ACCPollStickerConfig.h
//  CameraClient-Pods-DouYin
//
//  Created by guochenxiang on 2020/9/7.
//

#import "ACCCommonStickerConfig.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCPollStickerConfig : ACCCommonStickerConfig

@property (nonatomic, copy) void (^editPoll)(void);

@end

NS_ASSUME_NONNULL_END
