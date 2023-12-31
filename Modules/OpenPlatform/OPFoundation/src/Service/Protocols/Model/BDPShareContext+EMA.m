//
//  BDPShareContext+EMA.m
//  EEMicroAppSDK
//
//  Created by tujinqiu on 2019/10/22.
//

#import "BDPShareContext+EMA.h"
#import <objc/runtime.h>

@implementation BDPShareContext (EMA)

- (NSString *)PCPath
{
    return objc_getAssociatedObject(self, @selector(PCPath));
}

- (void)setPCPath:(NSString *)PCPath
{
    objc_setAssociatedObject(self, @selector(PCPath), PCPath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)PCMode
{
    return objc_getAssociatedObject(self, @selector(PCMode));
}

- (void)setPCMode:(NSString *)PCMode
{
    objc_setAssociatedObject(self, @selector(PCMode), PCMode, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
