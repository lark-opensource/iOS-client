//
//  NSObject+BDWRuntime.m
//  ByteWebView
//
//  Created by Lin Yong on 2019/2/27.
//

#import "NSObject+BDWRuntime.h"
#import <objc/runtime.h>

@implementation NSObject (BDWRuntime)


- (const void *)bdw_computedKeyFromString:(NSString *)key {
    return (char *)((__bridge void*)self) + [key hash] + [key characterAtIndex:0] + [key characterAtIndex:key.length - 1];
}

- (void)bdw_attachObject:(id)obj forKey:(NSString *)key {
    [self bdw_attachObject:obj forKey:key isWeak:NO];
}

- (id)bdw_getAttachedObjectForKey:(NSString *)key {
    return [self bdw_getAttachedObjectForKey:key isWeak:NO];
}

- (void)bdw_attachObject:(nullable id)obj forKey:(NSString *)key isWeak:(BOOL)bWeak {
    if (key.length > 0) {
        if (bWeak) {
            id __weak weakObject = obj;
            id (^block)(void) = ^{ return weakObject; };
            objc_setAssociatedObject(self,
                                     [self bdw_computedKeyFromString:key],
                                     block,
                                     OBJC_ASSOCIATION_COPY);
            return;
        }
        else {
            objc_setAssociatedObject(self,
                                     [self bdw_computedKeyFromString:key],
                                     obj,
                                     OBJC_ASSOCIATION_RETAIN);
        }
    }
}

- (nullable id)bdw_getAttachedObjectForKey:(NSString *)key isWeak:(BOOL)bWeak {
    if (key.length <= 0) {
        return nil;
    }
    if (bWeak) {
        id (^block)(void) = objc_getAssociatedObject(self,
                                                     [self bdw_computedKeyFromString:key]);
        return (block ? block() : nil);
    }
    else {
        return objc_getAssociatedObject(self,
                                        [self bdw_computedKeyFromString:key]);
    }
}

@end
