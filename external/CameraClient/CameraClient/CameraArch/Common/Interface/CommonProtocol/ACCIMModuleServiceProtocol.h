//
//  ACCIMModuleServiceProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by Daniel on 2021/4/7.
//

#ifndef ACCIMModuleServiceProtocol_h
#define ACCIMModuleServiceProtocol_h

#import <Foundation/Foundation.h>
@class AWEVideoPublishViewModel;
NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ACCIMXmojiPullStatus) {
    ///拉取成功
    ACCIMXmojiPullStatusSucceed = 0,
    ///拉取失败
    ACCIMXmojiPullStatusFailed,
    ///正在生成
    ACCIMXmojiPullStatusInProgress,
    ///超时
    ACCIMXmojiPullStatusTimeout
};

@protocol ACCIMModuleServiceProtocol <NSObject>

- (void)replaceEmotionIconTextInAttributedString:(NSMutableAttributedString *)attributedString
                                            font:(UIFont *)font;

- (void)replaceEmotionIconTextInAttributedString:(NSMutableAttributedString *)attributedString
                                            font:(UIFont *)font
                                       emojiSize:(CGSize)size;

- (BOOL)isPublishAtMentionWithRepository:(AWEVideoPublishViewModel *)reposity;

- (void)updateXmojiInfoIfNeededOnCompletion:(void (^ __nullable)(BOOL updated, ACCIMXmojiPullStatus status))completion;

@end

NS_ASSUME_NONNULL_END

#endif
