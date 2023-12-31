//
//  IESLiveResouceBundleGroup.m
//  Pods
//
//  Created by Zeus on 2016/12/23.
//
//

#import "IESLiveResouceBundleGroup.h"

@interface IESLiveResouceBundleGroup ()

@property (nonatomic, copy) NSArray <IESLiveResouceBundle *> *bundles;

@end

@implementation IESLiveResouceBundleGroup

- (instancetype)initWithBundleNames:(NSArray<NSString *> *)bundleNames {
    self = [super init];
    if (self) {
        NSMutableArray<IESLiveResouceBundle *> *bundles = [NSMutableArray array];
        for (NSString *bundleName in bundleNames) {
            IESLiveResouceBundle *bundle = [[self class] assetBundleWithBundleName:bundleName];
            if (bundle) {
                [bundles addObject:bundle];
            }
        }
        self.bundles = bundles;
    }
    return self;
}

- (instancetype)initWithBundles:(NSArray<IESLiveResouceBundle *> *)bundles {
    self = [super init];
    if (self) {
        self.bundles = bundles;
    }
    return self;
}

- (id)objectForKey:(NSString *)key type:(NSString *)type {
    for (IESLiveResouceBundle *bundle in self.bundles) {
        id value = [bundle objectForKey:key type:type];
        if (value) {
            return value;
        }
    }
    return nil;
}

@end
