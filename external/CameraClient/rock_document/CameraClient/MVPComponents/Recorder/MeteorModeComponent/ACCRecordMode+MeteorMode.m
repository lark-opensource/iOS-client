//
//  ACCRecordMode+MeteorMode.m
//  CameraClient-Pods-Aweme
//
//  Created by Chen Long on 2021/5/17.
//

#import "ACCRecordMode+MeteorMode.h"

#import <objc/runtime.h>

@implementation ACCRecordMode (MeteorMode)

- (BOOL)isMeteorMode
{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setIsMeteorMode:(BOOL)isMeteorMode
{
    objc_setAssociatedObject(self, @selector(isMeteorMode), @(isMeteorMode), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
