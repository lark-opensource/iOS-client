//  视频回复评论二期
//  ACCVideoReplyCommentModel.m
//  CameraClientModel-Pods-Aweme
//
//  Created by lixuan on 2021/10/8.
//

#import "ACCVideoReplyCommentModel.h"
#import <AWEBaseModel/AWEURLModel.h>
#import <Mantle/EXTKeyPathCoding.h>

@implementation ACCVideoReplyCommentModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    ACCVideoReplyCommentModel *model = nil;
    return @{
        @keypath(model, commentId) : @"reply_id",
        @keypath(model, commentText) : @"comment_text",
        @keypath(model, commentUserId) : @"reply_user_id",
        @keypath(model, commentAuthorNickname) : @"comment_author_nickname",
        @keypath(model, commentAuthorAvatar) : @"comment_author_avatar",
        @keypath(model, awemeId) : @"reply_aweme_id",
        @keypath(model, commentToCommentId) : @"reply_to_reply_id",
        @keypath(model, awemeTitle) : @"aweme_desc",
        @keypath(model, coverModel) : @"aweme_cover",
        @keypath(model, commentSticker) : @"comment_sticker",
        @keypath(model, replyType) : @"reply_type",
        @keypath(model, aliasCommentId) : @"alias_comment_id",
        @keypath(model, viewType) : @"type",
    };
}


+ (NSValueTransformer *)coverModelJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:[AWEURLModel class]];
}

+ (NSValueTransformer *)commentAuthorAvatarJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:[AWEURLModel class]];
}

+ (NSValueTransformer *)commentStickerJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:[AWEURLModel class]];
}
@end
