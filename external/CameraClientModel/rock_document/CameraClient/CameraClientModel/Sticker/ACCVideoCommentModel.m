//
//  ACCVideoCommentModel.m
//  CameraClient-Pods-Aweme
//
//  Created by Daniel on 2021/3/16.
//

#import "ACCVideoCommentModel.h"

#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>

@implementation ACCVideoCommentModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"userId" : @"user_id",
        @"userName" : @"user_name",
        @"avatarURLList" : @"user_avatar",
        @"commentMsg" : @"comment_msg",
        @"commentId" : @"comment_id",
        @"awemeId" : @"aweme_id",
        @"replyId" : @"reply_id",
        @"replyToReplyId" : @"reply_to_reply_id",
        @"channelId" : @"channel_id",
        @"emojiURLList" : @"emoji",
        @"isAuthor" : @"is_author",
        @"relationTag" : @"relation_tag",
        @"isDeleted" : @"is_deleted",
    };
}

+ (nullable ACCVideoCommentModel *)createModelFromJSON:(NSString *)jsonStr
{
    if (jsonStr == nil) {
        return nil;
    }
    NSError *error;
    NSData *objectData = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:objectData
                                                         options:NSJSONReadingMutableContainers
                                                           error:&error];
    if (error) {
        AWELogToolError2(@"video_comment_createModelFromJSON", AWELogToolTagRecord, @"%@", error);
        return nil;
    }
    error = nil;
    ACCVideoCommentModel *videoCommentModel = [MTLJSONAdapter modelOfClass:[ACCVideoCommentModel class]
                                                            fromJSONDictionary:json
                                                                         error:&error];
    if (error) {
        AWELogToolError2(@"video_comment_createModelFromJSON", AWELogToolTagRecord, @"%@", error);
        return nil;
    }
    return videoCommentModel;
}

- (NSString *)convertToJSONString
{
    NSError *error = nil;
    NSDictionary *JSONDictionary = [MTLJSONAdapter JSONDictionaryFromModel:self error:&error];
    if (error) {
        AWELogToolError2(@"video_comment_convertTOJSONString", AWELogToolTagRecord, @"%@", error);
        return @"";
    }
    return [JSONDictionary acc_dictionaryToJson];
}

@end
