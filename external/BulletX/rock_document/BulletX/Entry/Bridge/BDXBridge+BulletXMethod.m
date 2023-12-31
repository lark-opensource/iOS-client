//
//  BDXBridge+BulletXMethod.m
//  Bullet-Pods-Aweme
//
//  Created by bill on 2020/12/6.
//

#import <BDXBridgeKit/BDXBridgeContext.h>
#import <BDXBridgeKit/BDXBridgeMethod.h>
#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import <objc/runtime.h>
#import "BDXBridge+BulletXMethod.h"

static NSArray<NSString *> *s_autoRegisteredMethods = nil;
static NSString *const BDXBRIDGE_BDX_AUTO_PLUGIN_PREFIX = @"__bdxbridge_bullet_auto_method__";

@implementation BDXBridge (BulletXMethod)

+ (void)_autoCollectBulletXRegisteredMethods
{
    NSMutableArray<NSString *> *autoRegisteredMethods = [NSMutableArray new];
    unsigned int methodCount = 0;
    Method *methods = class_copyMethodList(object_getClass([self class]), &methodCount);
    for (unsigned int i = 0; i < methodCount; i++) {
        Method method = methods[i];
        SEL selector = method_getName(method);
        if ([NSStringFromSelector(selector) hasPrefix:BDXBRIDGE_BDX_AUTO_PLUGIN_PREFIX]) {
            IMP imp = method_getImplementation(method);
            NSString *className = ((NSString * (*)(id, SEL)) imp)(self, selector);
            if ([className isKindOfClass:[NSString class]] && className.length > 0) {
                [autoRegisteredMethods btd_addObject:className];
            }
        }
    }
    free(methods);
    s_autoRegisteredMethods = [autoRegisteredMethods copy];
}

+ (NSArray<NSString *> *)bdx_bulletAutoRegisteredMethods
{
    if (s_autoRegisteredMethods == nil || s_autoRegisteredMethods.count == 0) {
        [self _autoCollectBulletXRegisteredMethods];
    }
    return s_autoRegisteredMethods;
}

- (void)bdx_bulletAutoRegisterMethodsWithContext:(BDXBridgeContext *)context
{
    NSArray<NSString *> *autoRegisteredMethods = [[self class] bdx_bulletAutoRegisteredMethods];
    [autoRegisteredMethods enumerateObjectsUsingBlock:^(NSString *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        Class clazz = NSClassFromString(obj);
        if (clazz != nil) {
            [self __autoRegisterBulletXMethodClass:clazz withContext:context];
        }
    }];
}

- (void)__autoRegisterBulletXMethodClass:(Class)clazz withContext:(BDXBridgeContext *)context
{
    if (clazz == nil || [clazz isSubclassOfClass:[BDXBridgeMethod class]] == NO) {
        return;
    }
    BDXBridgeMethod *method = [[clazz alloc] initWithContext:context];
    if (method == nil) {
        return;
    }
    [self registerLocalMethod:method];
}

@end
