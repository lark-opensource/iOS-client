//
//  ACCVideoReplyStickerConfig.h
//  CameraClient-Pods-Aweme
//
//  视频评论视频
//
//  Created by Daniel on 2021/7/27.
//

#import "ACCCommonStickerConfig.h"

typedef NS_OPTIONS(NSUInteger, ACCVideoReplyStickerConfigOptions) {
    ACCVideoReplyStickerConfigOptionsNone = 0,
    ACCVideoReplyStickerConfigOptionsSelectTime = 1 << 0,
    ACCVideoReplyStickerConfigOptionsPreview = 1 << 1,
};

@interface ACCVideoReplyStickerConfig : ACCCommonStickerConfig

@property (nonatomic, copy, nullable) void (^onPreviewCallback)(void);

- (nullable instancetype)initWithOption:(ACCVideoReplyStickerConfigOptions)options NS_DESIGNATED_INITIALIZER;
- (nullable instancetype)init NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(nullable NSCoder *)coder NS_UNAVAILABLE;
- (nullable instancetype)initWithDictionary:(nonnull NSDictionary *)dictionaryValue error:(NSError * __autoreleasing _Nullable * _Nonnull)error NS_UNAVAILABLE;

@end
