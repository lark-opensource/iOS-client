//
// BDXServiceManager+Register.m
// BDXServiceCenter-Pods-Aweme
//
// Created by bill on 2021/3/2.
//

#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import <objc/runtime.h>

#import "BDXService.h"
#import "BDXServiceManager+Register.h"
#import "BDXServiceManager.h"

static NSArray<NSString *> *s_autoRegisteredService = nil;
static NSString *const BDXSERVICE_AUTO_REGISTER_PREFIX = @"__bdxservice_auto_register_serivce__";

@implementation BDXServiceManager (Register)

+ (void)_autoCollectBDXService
{
    NSMutableArray<NSString *> *autoRegisteredService = [NSMutableArray new];
    unsigned int methodCount = 0;
    Method *methods = class_copyMethodList(object_getClass([self class]), &methodCount);
    for (unsigned int i = 0; i < methodCount; i++) {
        Method method = methods[i];
        SEL selector = method_getName(method);
        if ([NSStringFromSelector(selector) hasPrefix:BDXSERVICE_AUTO_REGISTER_PREFIX]) {
            IMP imp = method_getImplementation(method);
            NSString *className = ((NSString * (*)(id, SEL)) imp)(self, selector);
            if ([className isKindOfClass:[NSString class]] && className.length > 0) {
                [autoRegisteredService btd_addObject:className];
            }
        }
    }

    free(methods);
    s_autoRegisteredService = [autoRegisteredService copy];
}

+ (NSArray<NSString *> *)bdxservice_autoRegisteredService
{
    if (s_autoRegisteredService == nil || s_autoRegisteredService.count == 0) {
        [self _autoCollectBDXService];
    }

    return s_autoRegisteredService;
}

- (void)bdx_autoRegisterService
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray<NSString *> *autoRegisteredService = [[self class] bdxservice_autoRegisteredService];
        [autoRegisteredService enumerateObjectsUsingBlock:^(NSString *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
            Class cls = NSClassFromString(obj);
            if (cls != nil) {
                [self __autoRegisterBDXServiceClass:cls];
            }
        }];
    });
}

- (void)__autoRegisterBDXServiceClass:(Class)cls
{
    // check cls is nil? and check is subclass of BDXService?
    if (cls == nil || ![cls conformsToProtocol:@protocol(BDXServiceProtocol)]) {
        return;
    }

    [BDXServiceManager registerDefaultSercice:cls];
}

@end
