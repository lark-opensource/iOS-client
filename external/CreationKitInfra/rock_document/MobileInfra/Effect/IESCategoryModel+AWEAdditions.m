//
//  IESCategoryModel+AWEAdditions.m
//  AWEStudio
//
//  Copyright © 2018 bytedance. All rights reserved.
//

#import "IESCategoryModel+AWEAdditions.h"
#import <objc/runtime.h>

@implementation IESCategoryModel (AWEAdditions)

- (NSArray<IESEffectModel *> *)aweStickers
{
    NSArray<IESEffectModel *> * stickers = [objc_getAssociatedObject(self, @selector(aweStickers)) mutableCopy];
    if (stickers.count == 0) {
        stickers = self.effects;
    }
    
    return stickers;
}

- (void)setAweStickers:(NSArray<IESEffectModel *> *)aweStickers
{
    objc_setAssociatedObject(self, @selector(aweStickers), aweStickers, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


- (BOOL)shouldUseIconDisplay
{
    return self.normalIconUrls.count > 0;
}

@end
