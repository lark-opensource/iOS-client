//
//  AWEInteractionGrootStickerModel.m
//  CameraClient-Pods-Aweme
//
//  Created by 饶骏华 on 2021/5/15.
//

#import "AWEInteractionGrootStickerModel.h"

@implementation AWEInteractionGrootStickerModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    NSMutableDictionary *keyPathDict = [NSMutableDictionary dictionaryWithDictionary:[[[AWEInteractionGrootStickerModel class] superclass] JSONKeyPathsByPropertyKey]];
    [keyPathDict addEntriesFromDictionary:@{
        @"grootInteraction" : @"groot_interaction"
    }];
    return keyPathDict;
}

- (NSInteger)indexFromType
{
    return 0;
}

@end
