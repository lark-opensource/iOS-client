//
//  OKServiceCenter.m
//  OneKit
//
//  Created by bob on 2020/5/11.
//

#import "OKServiceCenter.h"
#import "OKService.h"

@interface OKServiceCenter ()

@property (nonatomic, strong) NSMutableDictionary<NSString * ,id> *services;
@property (nonatomic, strong) dispatch_semaphore_t semaphore;

@end

@implementation OKServiceCenter

+ (instancetype)sharedInstance {
    static OKServiceCenter *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });

    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.services = [NSMutableDictionary new];
        self.semaphore = dispatch_semaphore_create(1);
    }
    
    return self;
}

- (void)bindClass:(Class)cls forProtocol:(Protocol *)protocol {
    if (![cls conformsToProtocol:protocol]) {
        return;
    }
    NSString *key = [OKServiceCenter stringKeyForProtocol:protocol];
    [self bindClass:cls forKey:key];
}

- (void)bindClass:(Class)cls forKey:(NSString *)key {
    NSCAssert(key != nil && key.length > 0, @"key should not be nil");
    if (key.length < 1) {
        return;
    }
    
    intptr_t timeout = dispatch_semaphore_wait(self.semaphore, dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC));
    if ([self.services objectForKey:key] == nil) {
        id service = nil;
        if ([cls respondsToSelector:@selector(sharedInstance)]) {
            service = [cls sharedInstance];
        } else {
            service = [[cls alloc] init];
        }
        
        NSCAssert(service != nil, @"Protocol sharedInstance should not be nil");
        [self.services setValue:service forKey:key];
    }
    if (!timeout) {
        dispatch_semaphore_signal(self.semaphore);
    }
}

- (void)bindObject:(id)service forProtocol:(Protocol *)protocol {
    if (![service conformsToProtocol:protocol]) {
        return;
    }
    
    NSString *key = [OKServiceCenter stringKeyForProtocol:protocol];
    [self bindObject:service forKey:key];
}

- (void)bindObject:(id)service forKey:(NSString *)key {
    NSCAssert(key != nil && key.length > 0, @"key should not be nil");
    if (key.length < 1) {
        return;
    }
    
    intptr_t timeout = dispatch_semaphore_wait(self.semaphore, dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC));
    if ([self.services objectForKey:key] == nil) {
        [self.services setValue:service forKey:key];
    }
    if (!timeout) {
        dispatch_semaphore_signal(self.semaphore);
    }
}

- (id)serviceForProtocol:(Protocol *)protocol {
    NSString *key = [OKServiceCenter stringKeyForProtocol:protocol];
    
    return [self serviceForKey:key];
}

- (id)serviceForKey:(NSString *)key {
    NSCAssert(key != nil && key.length > 0, @"key should not be nil");
    if (key.length < 1) {
        return nil;
    }
    intptr_t timeout = dispatch_semaphore_wait(self.semaphore, dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC));
    id service = [self.services objectForKey:key];
    if (!timeout) {
        dispatch_semaphore_signal(self.semaphore);
    }
    
    return service;
}

#pragma mark -- Helper

+ (NSString *)stringKeyForProtocol:(Protocol *)protocol {
    return [NSString stringWithFormat:@"com.OKServiceCenter.%@", NSStringFromProtocol(protocol)];
}

@end
