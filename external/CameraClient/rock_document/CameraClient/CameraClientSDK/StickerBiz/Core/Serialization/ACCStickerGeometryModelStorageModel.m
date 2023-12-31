//
//  ACCStickerGeometryModelStorageModel.m
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/12/21.
//

#import "ACCStickerGeometryModelStorageModel.h"
#import <CreativeKitSticker/ACCStickerGeometryModel.h>

@implementation ACCStickerGeometryModelStorageModel

+ (NSArray<NSString *> *)accs_excludeKeys
{
    return nil;
}

+ (NSSet<Class> *)accs_acceptClasses
{
    return [NSSet setWithArray:@[ACCStickerGeometryModel.class]];
}

@end
