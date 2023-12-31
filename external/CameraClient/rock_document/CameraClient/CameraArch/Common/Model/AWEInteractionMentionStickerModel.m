//
//  AWEInteractionMentionStickerModel.m
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2021/4/27.
//

#import "AWEInteractionMentionStickerModel.h"

@implementation AWEInteractionMentionStickerModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    NSMutableDictionary *keyPathDict = [NSMutableDictionary dictionaryWithDictionary:[[[AWEInteractionMentionStickerModel class] superclass] JSONKeyPathsByPropertyKey]];
    [keyPathDict addEntriesFromDictionary:@{
        @"mentionedUserInfo" : @"mention_info"
    }];
    return keyPathDict;
}

- (NSInteger)indexFromType
{
    return 0;
}

@end
