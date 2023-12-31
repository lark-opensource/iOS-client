//
//  ACCRecognitionGrootStickerConfig.h
//  CameraClient-Pods-Aweme
//
//  Created by Ryan Yan on 2021/8/23.
//

#import "ACCCommonStickerConfig.h"

typedef NS_OPTIONS(NSUInteger, ACCRecognitionGrootStickerConfigOptions) {
    ACCRecognitionGrootStickerConfigOptionsNone = 0,
    ACCRecognitionGrootStickerConfigOptionsSelectTime = 1 << 0,
};

@interface ACCRecognitionGrootStickerConfig : ACCCommonStickerConfig

@property (nonatomic, copy) void (^onSelectTimeCallback)(void);

- (instancetype)initWithOption:(ACCRecognitionGrootStickerConfigOptions)options;

@end
