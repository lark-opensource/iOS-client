//
//  BDRuleModel+Precache.m
//  Indexer
//
//  Created by WangKun on 2022/2/7.
//

#import "BDRuleModel+Precache.h"
#import "BDREExprRunner.h"

#import <objc/runtime.h>

@implementation BDRuleModel (Precache)

+ (void)preload
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self __swizzleInstanceMethod:@selector(setCel:) with:@selector(precache_setCel:)];
    });
}

- (void)precache_setCel:(NSString *)cel
{
    if (!self.commands.count) {
        dispatch_async(preCacheQueue(), ^{
            [[BDREExprRunner sharedRunner] commandsFromExpr:cel];
        });
    }
    [self precache_setCel:cel];
}

static dispatch_queue_t preCacheQueue() {
    static dispatch_queue_t queue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("queue-BDRuleEnginePreCache", DISPATCH_QUEUE_SERIAL);
    });
    return queue;
}


+ (BOOL)__swizzleInstanceMethod:(SEL)origSelector with:(SEL)newSelector
{
    Method originalMethod = class_getInstanceMethod(self, origSelector);
    Method swizzledMethod = class_getInstanceMethod(self, newSelector);
    if (!originalMethod || !swizzledMethod) {
        return NO;
    }
    if (class_addMethod(self,
                        origSelector,
                        method_getImplementation(swizzledMethod),
                        method_getTypeEncoding(swizzledMethod))) {
        class_replaceMethod(self,
                            newSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
        
    } else {
        class_replaceMethod(self,
                            newSelector,
                            class_replaceMethod(self,
                                                origSelector,
                                                method_getImplementation(swizzledMethod),
                                                method_getTypeEncoding(swizzledMethod)),
                            method_getTypeEncoding(originalMethod));
    }
    return YES;
}
@end
