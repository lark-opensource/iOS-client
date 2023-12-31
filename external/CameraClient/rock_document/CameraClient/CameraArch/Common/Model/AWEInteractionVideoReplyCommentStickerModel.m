//  视频回复评论二期
//  AWEInteractionVideoReplyCommentStickerModel.m
//  CameraClientModel-Pods-Aweme
//
//  Created by lixuan on 2021/10/8.
//

#import "AWEInteractionVideoReplyCommentStickerModel.h"

@implementation AWEInteractionVideoReplyCommentStickerModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    NSMutableDictionary *keyPathDict = [NSMutableDictionary dictionaryWithDictionary:[[[AWEInteractionVideoReplyCommentStickerModel class] superclass] JSONKeyPathsByPropertyKey]];
    [keyPathDict addEntriesFromDictionary:@{
        @"videoReplyCommentInfo" : @"reply_to_comment"
    }];
    
    return keyPathDict;
}

+ (NSValueTransformer *)videoReplyCommentInfoJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:[ACCVideoReplyCommentModel class]];
}
@end
