//
//  ACCStickerHandler+SocialData.h
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2021/3/24.
//

#import "ACCStickerHandler.h"

NS_ASSUME_NONNULL_BEGIN

@class AWEVideoPublishViewModel;

@interface ACCStickerHandler (SocialData)

/// 包括文字贴纸、mention/hashtag贴纸 已经自动添加的此类贴纸
/// 注意 mention 和 hashtag贴纸只要添加了就算一个 不区分是否真的绑定了
- (NSInteger)allMentionCountInSticker;
- (NSInteger)allHashtahCountInSticker;

@end

NS_ASSUME_NONNULL_END
