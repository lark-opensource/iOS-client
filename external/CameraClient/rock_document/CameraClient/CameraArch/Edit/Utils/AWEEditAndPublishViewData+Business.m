//
//  AWEEditAndPublishViewData+Business.m
//  CameraClient-Pods-Aweme
//
//  Created by Liu Deping on 2021/3/30.
//

#import "AWEEditAndPublishViewData+Business.h"
#import <objc/runtime.h>

@implementation AWEEditAndPublishViewData (Business)

@dynamic type;

- (void)setType:(AWEEditAndPublishViewDataType)type
{
    objc_setAssociatedObject(self, @selector(type), @(type), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (AWEEditAndPublishViewDataType)type
{
    return [objc_getAssociatedObject(self, _cmd ) integerValue];
}

@end
