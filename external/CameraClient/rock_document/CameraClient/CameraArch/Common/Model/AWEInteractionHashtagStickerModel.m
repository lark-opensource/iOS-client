//
//  AWEInteractionHashtagStickerModel.m
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2021/4/27.
//

#import "AWEInteractionHashtagStickerModel.h"

@implementation AWEInteractionHashtagStickerModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    NSMutableDictionary *keyPathDict = [NSMutableDictionary dictionaryWithDictionary:[[[AWEInteractionHashtagStickerModel class] superclass] JSONKeyPathsByPropertyKey]];
    [keyPathDict addEntriesFromDictionary:@{
        @"hashtagInfo" : @"hashtag_info"
    }];
    return keyPathDict;
}

- (NSInteger)indexFromType
{
    return 0;
}

@end
