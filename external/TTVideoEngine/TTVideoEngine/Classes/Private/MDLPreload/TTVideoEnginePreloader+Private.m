//
//  TTVideoEnginePreloader+Private.m
//  TTVideoEngine
//
//  Created by 黄清 on 2020/4/20.
//

#import "TTVideoEnginePreloader+Private.h"
#import "TTVideoEngineUtilPrivate.h"
#import <Foundation/Foundation.h>

static NSMutableSet *s_preload_class_set = nil;

@implementation TTVideoEnginePreloader (Private)

+(NSMutableSet *)classSet {
    @synchronized (TTVideoEnginePreloader.class) {
        if (s_preload_class_set == nil) {
            s_preload_class_set = [NSMutableSet set];
        }
        return s_preload_class_set;
    }
    return s_preload_class_set;
}

+ (BOOL)hasRegistClass {
    BOOL result = NO;
    @synchronized (TTVideoEnginePreloader.class) {
        result = ([self classSet].count > 0);
    }
    return result;
}

+ (void)notifyPreload:(TTVideoEngine *)engine info:(NSDictionary *)info {
    NSSet *temSet = nil;
    @synchronized (TTVideoEnginePreloader.class) {
        temSet = [self classSet].copy;
    }
    
    [temSet enumerateObjectsUsingBlock:^(Class c, BOOL * _Nonnull stop) {
        if ([c shouldPreload:engine]) {
            [c engine:engine prelaod:info];
        }
    }];
}

+ (void)notifyPreloadCancel:(nullable TTVideoEngine *)engine info:(NSDictionary *)info {
    NSSet *temSet = nil;
    @synchronized (TTVideoEnginePreloader.class) {
        temSet = [self classSet].copy;
    }
    
    [temSet enumerateObjectsUsingBlock:^(Class c, BOOL * _Nonnull stop) {
        [c engine:engine cancelAllPrelaod:info];
    }];
}

@end
