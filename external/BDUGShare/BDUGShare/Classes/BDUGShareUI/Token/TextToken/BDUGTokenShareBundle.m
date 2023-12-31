//
//  BDUGTokenShareBundle.m
//  BDUGTokenShare
//
//  Created by 梁浩 on 2019/3/8.
//

#import "BDUGTokenShareBundle.h"

@implementation BDUGTokenShareBundle

+ (NSBundle *)resourceBundle {
    static NSBundle *bundle;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *bundlePath = [[NSBundle bundleForClass:self.class].resourcePath stringByAppendingPathComponent:@"BDUGShareTokenResource.bundle"];
        bundle = [NSBundle bundleWithPath:bundlePath];
        if (!bundle) {
            NSAssert(0, @"bundle of BDUGTokenShareBundle can't load");
            bundle = [NSBundle mainBundle];
        }
    });
    return bundle;
}

@end
