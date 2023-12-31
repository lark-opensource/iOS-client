//
//  HTSVideoData+AWEAIVideoClipInfo.m
//  Pods
//
//  Created by wang ya on 2019/8/2.
//

#import "HTSVideoData+AWEAIVideoClipInfo.h"
#import <AWELazyRegister/AWELazyRegisterPremain.h>
#import <CreativeKit/NSObject+ACCSwizzle.h>
#import <objc/runtime.h>

@implementation HTSVideoData (AWEAIVideoClipInfo)

AWELazyRegisterPremainClassCategory(HTSVideoData, AWEAIVideoClipInfo)
{
    [self acc_swizzleMethodsOfClass:self originSelector:@selector(copyWithZone:) targetSelector:@selector(studio_copyWithZone:)];
}

- (instancetype)studio_copyWithZone:(NSZone *)zone
{
    HTSVideoData *video = [self studio_copyWithZone:zone];
    video.studio_videoClipResolveType = self.studio_videoClipResolveType;

    return video;
}

- (void)setStudio_videoClipResolveType:(AWEAIVideoClipInfoResolveType)studio_videoClipResolveType
{
    objc_setAssociatedObject(self, @selector(studio_videoClipResolveType), @(studio_videoClipResolveType), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (AWEAIVideoClipInfoResolveType)studio_videoClipResolveType
{
    NSNumber *numberValue = objc_getAssociatedObject(self, _cmd);
    if (numberValue) {
        return (AWEAIVideoClipInfoResolveType)[numberValue integerValue];
    }
    return AWEAIVideoClipInfoResolveTypeNone;
}

@end
