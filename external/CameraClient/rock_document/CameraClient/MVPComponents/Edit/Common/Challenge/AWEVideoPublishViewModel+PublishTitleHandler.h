//
//  AWEVideoPublishViewModel+PublishTitleHandler.h
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2020/11/22.
//

#import <CreationKitArch/AWEVideoPublishViewModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface AWEVideoPublishViewModel (PublishTitleHandler)

/// 同步@的用户信息到标题里
- (void)syncMentionUserToTitleIfNeed;

/// 向标题里拼接绑定的话题参数 .e.g. 我是标题 #话题1 #话题2
/// @param maxTitleLength 标题的最大字数
- (void)appendChallengesToTitleWithNames:(NSArray <NSString *> *)challengeNames
                          maxTitleLength:(NSInteger)maxTitleLength;
/// 移除标题中绑定的话题(如果有)
- (void)removeChallengesFromTitleWithNames:(NSArray <NSString *> *)challengeNames;
- (void)removeChallengeFromTitleWithName:(NSString *)challengeName;

/// 将当前标题绑定的话题立即同步到publish model的ExtraInfo字段里
- (void)syncTitleChallengeInfosToTitleExtraInfo;


@end

NS_ASSUME_NONNULL_END
