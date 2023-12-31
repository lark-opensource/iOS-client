//
//  BDUGShareDialogBundle.m
//  BDUGTokenShare
//
//  Created by yangyang on 2019/3/8.
//

#import "BDUGShareDialogBundle.h"

@implementation BDUGShareDialogBundle

+ (NSBundle *)resourceBundle {
    static NSBundle *bundle;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *bundlePath = [[NSBundle bundleForClass:self.class].resourcePath stringByAppendingPathComponent:@"BDUGShareDialogResource.bundle"];
        bundle = [NSBundle bundleWithPath:bundlePath];
        if (!bundle) {
            NSAssert(0, @"bundle of BDUGShareDialogBundle can't load");
            bundle = [NSBundle mainBundle];
        }
    });
    return bundle;
}

@end
