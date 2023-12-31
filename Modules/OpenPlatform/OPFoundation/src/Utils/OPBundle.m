//
//  OPBundle.m
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/1/8.
//

#import "OPBundle.h"

@implementation OPBundle

+ (NSBundle *)bundle {
    // Load Custom Bundle
    //TODO: nico chagne this bundle name after EEMicroSDK is abandoned.
    NSString *bundleName = @"EEMicroAppSDK";
    NSURL *bundleURL = [[NSBundle bundleForClass:[self class]] URLForResource:bundleName withExtension:@"bundle"];
    NSBundle *bundle = nil;
    if (bundleURL) {
        bundle = [NSBundle bundleWithURL:bundleURL];
    } else {
        bundleURL = [[NSBundle mainBundle] URLForResource:bundleName withExtension:@"bundle"];
        if (bundleURL) {
            bundle = [NSBundle bundleWithURL:bundleURL];
        }
    }

    if (bundle) {
        return bundle;
    }

    return [NSBundle mainBundle];
}

+ (NSBundle *)bundleWithName:(NSString *)bundleName inFramework:(NSString *)framworkClassName {
    // Load Custom Bundle
    if (!bundleName || bundleName.length <= 0) {
        return [NSBundle mainBundle];
    }
    Class cls = NSClassFromString(framworkClassName);
    if (!cls) {
        return [NSBundle mainBundle];
    }
    NSBundle *bundle = [NSBundle bundleForClass:cls];
    NSURL *url = [bundle URLForResource:bundleName withExtension:@"bundle"];
    if (!url) {
        bundle = [NSBundle mainBundle];
        url = [bundle URLForResource:bundleName withExtension:@"bundle"];
        if (!url) {
            return [NSBundle mainBundle];
        }
    }
    bundle = [NSBundle bundleWithURL:url];
    return bundle;
}

@end
