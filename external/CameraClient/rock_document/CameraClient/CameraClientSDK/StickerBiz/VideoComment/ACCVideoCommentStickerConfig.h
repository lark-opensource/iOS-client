//
//  ACCVideoCommentStickerConfig.h
//  CameraClient-Pods-Aweme
//
//  Created by Daniel on 2021/3/18.
//

#import "ACCCommonStickerConfig.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSUInteger, ACCVideoCommentStickerConfigOptions) {
    ACCVideoCommentStickerConfigOptionsNone = 0,
    ACCVideoCommentStickerConfigOptionsSelectTime = 1 << 0,
};

@interface ACCVideoCommentStickerConfig : ACCCommonStickerConfig

@property (nonatomic, copy) void (^onSelectTimeCallback)(void);

- (instancetype)initWithOption:(ACCVideoCommentStickerConfigOptions)options;

@end

NS_ASSUME_NONNULL_END
