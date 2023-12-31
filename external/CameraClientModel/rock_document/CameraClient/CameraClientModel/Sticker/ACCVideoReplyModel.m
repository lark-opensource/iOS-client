//
//  ACCVideoReplyModel.m
//  CameraClientModel-Pods-Aweme
//
//  视频评论视频
//
//  Created by Daniel on 2021/7/27.
//

#import "ACCVideoReplyModel.h"

#import <AWEBaseModel/AWEURLModel.h>
#import <Mantle/EXTKeyPathCoding.h>

@implementation ACCVideoReplyModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    ACCVideoReplyModel *model = nil;
    return @{
        @keypath(model, awemeId) : @"aweme_id",
        @keypath(model, userId) : @"user_id",
        @keypath(model, secUserId) : @"sec_user_id",
        @keypath(model, username) : @"author_nickname",
        @keypath(model, title) : @"desc",
        @keypath(model, coverModel) : @"cover",
        @keypath(model, awemeType) : @"aweme_type",
        @keypath(model, deleted) : @"deleted",
        @keypath(model, isAvailable) : @"is_available",
        @keypath(model, playingAwemeId) : @"playing_aweme_id",
        @keypath(model, replyId) : @"reply_id",
        @keypath(model, replyToReplyId) : @"reply_to_reply_id",
        @keypath(model, aliasCommentId) : @"alias_comment_id",
        @keypath(model, userAvatarModel) : @"author_avatar",
        @keypath(model, viewType) : @"type",
    };
}

+ (NSValueTransformer *)coverModelJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:[AWEURLModel class]];
}

+ (NSValueTransformer *)userAvatarModelJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:[AWEURLModel class]];
}
@end
