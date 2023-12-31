//
//  KAServiceLocator.m
//  KAServiceLocator
//
//  Created by bytedance on 2021/12/20.
//

#import "LKServiceLocator.h"

@interface LKServiceLocator ()

@property (nonatomic, strong) NSDictionary *_map;
@property (nonatomic, strong) NSMutableDictionary *_cache;

@end

@implementation LKServiceLocator

+ (LKServiceLocator *)shared {
    static LKServiceLocator *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
        instance._cache = [NSMutableDictionary new];
        [instance _registry];
    });
    return instance;
}

- (void)_registry {
    self._map = @{@"LKAppLinkServiceInterface": @"LKAppLinkServiceImpl"};
}

+ (_Nullable id)locateService:(Protocol *)serviceProtocol {
    @synchronized (LKServiceLocator.shared) {

        NSString *key = NSStringFromProtocol(serviceProtocol);

        id cachedValue = LKServiceLocator.shared._cache[key];
        if (cachedValue) {
            return cachedValue;
        }

        NSString *implStr = LKServiceLocator.shared._map[key];
        if (implStr) {
            id instance = [[NSClassFromString(implStr) alloc] init];
            if ([instance conformsToProtocol:serviceProtocol]) {
                LKServiceLocator.shared._cache[key] = instance;
                return instance;
            } else {
                return nil;
            }
        } else {
            return nil;
        }

    }
}

@end
