//
//  ACCStickerTimeRangeModelStorageModel.m
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/12/21.
//

#import "ACCStickerTimeRangeModelStorageModel.h"
#import <CreativeKitSticker/ACCStickerTimeRangeModel.h>

@implementation ACCStickerTimeRangeModelStorageModel

+ (NSArray<NSString *> *)accs_excludeKeys
{
    return nil;
}

+ (NSSet<Class> *)accs_acceptClasses
{
    return [NSSet setWithArray:@[ACCStickerTimeRangeModel.class]];
}

@end
