//
//  AWEInteractionVideoShareStickerModel.m
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2021/4/20.
//

#import "AWEInteractionVideoShareStickerModel.h"

@implementation AWEInteractionVideoShareStickerModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    NSMutableDictionary *keyPathDict = [NSMutableDictionary dictionaryWithDictionary:[[[AWEInteractionVideoShareStickerModel class] superclass] JSONKeyPathsByPropertyKey]];
    [keyPathDict addEntriesFromDictionary:@{
        @"videoShareInfo" : @"video_share_info"
    }];
    return keyPathDict;
}

+ (NSValueTransformer *)videoShareInfoJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:AWEVideoShareInfoModel.class];
}

@end

@implementation AWEVideoShareInfoModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"videoItemId" : @"aweme_id",
        @"authorId" : @"author_id",
        @"authorSecId" : @"sec_author_id",
        @"authorName" : @"author_name",
        @"commentUserId" : @"comment_user_id",
        @"commentUserSecId" : @"comment_user_sec_id",
        @"commentContent" : @"comment_content",
        @"commentUserNickname" : @"comment_user_nickname",
        @"commentId" : @"comment_id"
    };
}

- (NSInteger)indexFromType
{
    return -1;
}

- (id)copyWithZone:(NSZone *)zone
{
    AWEVideoShareInfoModel *model = [[[self class] alloc] init];
    model.videoItemId = self.videoItemId;
    model.authorId = self.authorId;
    model.authorSecId = self.authorSecId;
    model.authorName = self.authorName;
    model.commentUserId = self.commentUserId;
    model.commentUserSecId = self.commentUserSecId;
    model.commentContent = self.commentContent;
    model.commentUserNickname = self.commentUserNickname;
    model.commentId = self.commentId;
    return model;
}

@end
