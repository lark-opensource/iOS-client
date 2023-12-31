//
//  NSBundle+AWEAdditions.m
//  AWEFoundationKit-Pods-Aweme
//
//  Created by 陈煜钏 on 2020/2/7.
//
//
#import "NSBundle+AWEAdditions.h"

NSBundle *AWEBundleWithName(NSString *name)
{
    static NSMutableDictionary *kBundleStore = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kBundleStore = [NSMutableDictionary new];
    });
    
    @synchronized (kBundleStore) {
        NSBundle *bundle = kBundleStore[name];
        if (!bundle) {
            NSString *bundlePath = [[NSBundle mainBundle] pathForResource:name ofType:@"bundle"];
            bundle = [NSBundle bundleWithPath:bundlePath];
            kBundleStore[name] = bundle;
        }
        return bundle;
    }
}
