//
//  AWEInteractionVideoReplyStickerModel.m
//  Indexer
//
//  Created by Daniel on 2021/8/23.
//

#import "AWEInteractionVideoReplyStickerModel.h"

@implementation AWEInteractionVideoReplyStickerModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    NSMutableDictionary *keyPathDict = [NSMutableDictionary dictionaryWithDictionary:[[[AWEInteractionVideoReplyStickerModel class] superclass] JSONKeyPathsByPropertyKey]];
    [keyPathDict addEntriesFromDictionary:@{
        @"videoReplyUserInfo" : @"reply_to_aweme"
    }];
    return keyPathDict;
}

+ (NSValueTransformer *)videoReplyUserInfoModelJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:[ACCVideoReplyModel class]];
}

@end
