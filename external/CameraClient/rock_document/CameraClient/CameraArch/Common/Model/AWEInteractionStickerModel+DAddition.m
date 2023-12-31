//
//  AWEInteractionStickerModel+DAddition.m
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2021/4/21.
//

#import "AWEInteractionStickerModel+DAddition.h"

@implementation AWEInteractionStickerModel (DAddition)

+ (NSComparisonResult)compareIndexOfSticker1:(AWEInteractionStickerModel *)sticker1 sticker2:(AWEInteractionStickerModel *)sticker2
{
    //compare indexFromType first
    if ([sticker1 indexFromType] < [sticker2 indexFromType]) {
        return NSOrderedAscending;
    } else if ([sticker1 indexFromType] > [sticker2 indexFromType]) {
        return NSOrderedDescending;
    } else {// if they have same indexFromType, then compare index
        if (sticker1.index < sticker2.index) {
            return NSOrderedAscending;
        } else if (sticker1.index > sticker2.index) {
            return NSOrderedDescending;
        } else {
            return NSOrderedSame;
        }
    }
}

- (NSInteger)indexFromType
{
    switch (self.type) {
        case AWEInteractionStickerTypeEditTag:
            return 400;
        case AWEInteractionStickerTypePoll:
            return 100;
        case AWEInteractionStickerTypeLive:
            return 90;
        case AWEInteractionStickerTypeVideoReply:
        case AWEInteractionStickerTypeVideoReplyComment:
            return 80;
        case AWEInteractionStickerTypeComment:
            return 1;
        case AWEInteractionStickerTypeMention:
        case AWEInteractionStickerTypeHashtag:
        case AWEInteractionStickerTypeSocialText:
        case AWEInteractionStickerTypeGroot:
            return 0;
        case AWEInteractionStickerTypeProps:
        case AWEInteractionStickerTypeNone:
        case AWEInteractionStickerTypeVideoVote:
        case AWEInteractionStickerTypeVideoShare:
        default:
            return -1;
            break;
    }
    return -2;
}

- (AWEInteractionStickerLocationModel *)generateLocationModel
{
    AWEInteractionStickerLocationModel *location = nil;
    NSData* data = [self.trackInfo dataUsingEncoding:NSUTF8StringEncoding];
    if (!data) {
        return nil;
    }
    NSError *error = nil;
    NSArray *values = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    if ([values count]) {
        NSArray *locationArr = [MTLJSONAdapter modelsOfClass:[AWEInteractionStickerLocationModel class] fromJSONArray:values error:&error];
        if ([locationArr count]) {
            location = [locationArr firstObject];
        }
    }
    return location;
}

- (void)updateLocationInfo:(AWEInteractionStickerLocationModel *)location
{
    if (location) {
        NSError *error = nil;
        NSArray *arr = [MTLJSONAdapter JSONArrayFromModels:@[location] error:&error];
        NSData *arrJsonData = [NSJSONSerialization dataWithJSONObject:arr options:kNilOptions error:&error];
        if (arrJsonData && !error) {
            NSString *arrJsonStr = [[NSString alloc] initWithData:arrJsonData encoding:NSUTF8StringEncoding];
            self.trackInfo = arrJsonStr;
        }
    }
}

@end
