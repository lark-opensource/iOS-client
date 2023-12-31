//
//  BDPBundle.m
//
//  Created by CsoWhy on 2018/9/14.
//

#import "BDPBundle.h"

@implementation BDPBundle

+ (NSBundle *)mainBundle
{
    // Load Custom Bundle
    NSBundle *bundle = nil;
    NSURL *bundleURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"TimorAssetBundle" withExtension:@"bundle"];
    if (bundleURL) {
        bundle = [NSBundle bundleWithURL:bundleURL];
    }
    
    // Invalid Bundle
    if (!bundle || ![bundle isKindOfClass:[NSBundle class]]) {
        return [NSBundle mainBundle];
    }
    return bundle;
}

+ (NSBundle *)universeDesignIconBundle
{
    // Load Custom Bundle
    NSBundle *bundle = nil;
    NSURL *bundleURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"UniverseDesignIcon" withExtension:@"bundle"];
    if (bundleURL) {
        bundle = [NSBundle bundleWithURL:bundleURL];
    }
    
    // Invalid Bundle
    if (!bundle || ![bundle isKindOfClass:[NSBundle class]]) {
        return [NSBundle mainBundle];
    }
    return bundle;
}

@end
