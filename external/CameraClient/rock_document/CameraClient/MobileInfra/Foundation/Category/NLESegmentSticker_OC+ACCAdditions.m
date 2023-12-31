//
//  NLESegmentSticker_OC+ACCAdditions.m
//  CameraClient-Pods-Aweme
//
//  Created by fangxiaomin on 2021/2/9.
//

#import "NLESegmentSticker_OC+ACCAdditions.h"
#import <objc/runtime.h>
#import <CameraClientModel/ACCCrossPlatformStickerType.h>

@implementation NLESegmentSticker_OC (ACCAdditions)

- (void)setStickerType:(ACCCrossPlatformStickerType)stickerType
{
    objc_setAssociatedObject(self, @selector(stickerType), @(stickerType), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (ACCCrossPlatformStickerType)stickerType
{
    NSNumber *type = objc_getAssociatedObject(self, _cmd);
    if (type == nil) {
        return ACCCrossPlatformStickerTypeInfo;
    } else {
        return [type integerValue];
    }
}

- (void)setExtraDict:(NSMutableDictionary *)extraDic
{
    objc_setAssociatedObject(self, @selector(extraDict), extraDic, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSMutableDictionary *)extraDict
{
    return objc_getAssociatedObject(self, _cmd);
}

@end
