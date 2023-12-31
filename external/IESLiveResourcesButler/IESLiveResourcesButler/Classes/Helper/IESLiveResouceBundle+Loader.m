//
//  IESLiveResouceBundle+Loader.m
//  Pods
//
//  Created by Zeus on 2016/12/23.
//
//

#import "IESLiveResouceBundle+Loader.h"

@implementation IESLiveResouceBundle (Loader)

+ (NSArray <NSString *>*)loadBundleNamesWithCategory:(NSString *)category {
    NSArray *filesInMainBundle = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[[NSBundle mainBundle] bundlePath] error:nil];
    NSMutableArray<NSString *> *bundleNames = [NSMutableArray array];
    for (NSString *fileName in filesInMainBundle) {
        if ([[fileName pathExtension] isEqualToString:@"bundle"]) {
            NSDictionary *bundleInfo = [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%@/Info",fileName] ofType:@"plist"]];
            NSString *bundleCategory = bundleInfo[@"category"];
            if (bundleCategory == nil) {
                bundleInfo = [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%@/Config",fileName] ofType:@"plist"]];
                bundleCategory = bundleInfo[@"category"];
            }
            if ([bundleCategory isEqualToString:category]) {
                [bundleNames addObject:fileName];
            }
        }
    }
    return [bundleNames copy];
}

+ (IESLiveResouceBundle *)loadAssetBundleWithCategory:(NSString *)category {
    NSMutableSet<NSString *> *validBundleNames = [NSMutableSet setWithArray:[self loadBundleNamesWithCategory:category]];
    NSMutableSet<NSString *> *parentBundleNames = [NSMutableSet set];
    NSDictionary *bundleInfo = nil;
    for (NSString *bundleName in validBundleNames) {
        bundleInfo = [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%@/Info",bundleName] ofType:@"plist"]];
        NSString *parentBundleName = bundleInfo[@"parent"];
        if (parentBundleName == nil) {
        bundleInfo = [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%@/Config",bundleName] ofType:@"plist"]];
            parentBundleName = bundleInfo[@"parent"];
        }
        if (parentBundleName) {
            IESLiveResouceBundle *parentBundle = [IESLiveResouceBundle assetBundleWithBundleName:parentBundleName];
            do {
                [parentBundleNames addObject:parentBundle.bundleName];
                parentBundle = parentBundle.parent;
            } while (parentBundle != nil);
        }
    }
    [validBundleNames minusSet:parentBundleNames];
    if ([validBundleNames count] > 0) {
        return [self assetBundleWithBundleName:[validBundleNames anyObject]];
    }
    return nil;
}

@end
