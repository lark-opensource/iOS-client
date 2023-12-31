//
//  ACCBaseStickerView+Adsorbing.m
//  CameraClient
//
//  Created by Yangguocheng on 2020/6/8.
//

#import "ACCBaseStickerView+Adsorbing.h"
#import <objc/runtime.h>

@implementation ACCBaseStickerView (Adsorbing)

static void * const kAngleAdsorbingKey = (void*)&kAngleAdsorbingKey;

- (BOOL)isAngleAdsorbing
{
    return [objc_getAssociatedObject(self, kAngleAdsorbingKey) boolValue];
}

- (void)setIsAngleAdsorbing:(BOOL)isAngleAdsorbing
{
    objc_setAssociatedObject(self, kAngleAdsorbingKey, @(isAngleAdsorbing), OBJC_ASSOCIATION_ASSIGN);
}

@end
