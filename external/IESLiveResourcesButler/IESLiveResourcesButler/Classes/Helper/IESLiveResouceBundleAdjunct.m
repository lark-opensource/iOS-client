//
//  IESLiveResouceBundleAdjunct.m
//  Pods
//
//  Created by Zeus on 2017/2/9.
//
//

#import "IESLiveResouceBundleAdjunct.h"
#import "IESLiveResouceManager.h"
#import <objc/runtime.h>

@implementation IESLiveResouceBundleAdjunct

//补丁的资源优先级高于原资源包，所以使用preHook
- (IESLiveResouceBundlePreHookBlock)preHook {
    IESLiveResouceBundlePreHookBlock preHook = objc_getAssociatedObject(self, @selector(preHook));
    if (preHook) {
        return preHook;
    }
    __weak typeof(self) weakSelf = self;
    preHook = ^(NSString *key, NSString *type, NSString *category){
        return [weakSelf objectForKey:key type:type];
    };
    objc_setAssociatedObject(self, @selector(preHook), preHook, OBJC_ASSOCIATION_COPY);
    return preHook;
}

//补丁包不允许有继承关系
- (id)objectForKey:(NSString *)key type:(NSString *)type {
    return [self.assetManagers[type] objectForKey:key];
}

@end

@implementation IESLiveResouceBundle (Adjunct)

- (void)applyAdjunct:(IESLiveResouceBundleAdjunct *)adjunct {
    [self addHooker:adjunct];
}

+ (void)applyAdjunct:(IESLiveResouceBundleAdjunct *)adjunct forCategory:(NSString *)category {
    [self addHooker:adjunct forCategory:category];
}

@end
