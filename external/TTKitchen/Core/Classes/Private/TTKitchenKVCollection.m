//
//  TTKitchenKVCollection.m
//  Pods
//
//  Created by SongChai on 2018/5/19.
//

#import "TTKitchenKVCollection.h"
#import <pthread/pthread.h>

static NSString * const kTTKitchenKeyAccessTime = @"kTTKitchenKeyAccessTime";

@implementation TTKitchenKVCollection {
    NSMutableDictionary *_accessTimeDict;
    dispatch_semaphore_t _lock;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _dictionary = [NSMutableDictionary dictionary];
        _accessTimeDict = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:kTTKitchenKeyAccessTime]];
        _lock = dispatch_semaphore_create(1);
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    }
    return self;
}

- (NSArray *)allValues {
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    NSArray *result = [_dictionary allValues];
    dispatch_semaphore_signal(_lock);
    return result;
}

- (NSArray *)allKeys {
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    NSArray *result = [_dictionary allKeys];
    dispatch_semaphore_signal(_lock);
    return result;
}

- (void)setObject:(id)anObject forKey:(id<NSCopying>)aKey {
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    [_dictionary setObject:anObject forKey:aKey];
    dispatch_semaphore_signal(_lock);
}

- (id)objectForKey:(id)aKey {
    NSTimeInterval accessTime = [[NSDate date] timeIntervalSince1970];
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    id result = [_dictionary objectForKey:aKey];
    [_accessTimeDict setObject:@(accessTime) forKey:aKey];
    dispatch_semaphore_signal(_lock);
    return result;
}

- (NSDictionary *)keyAccessTime {
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    NSDictionary *result = [_accessTimeDict copy];
    dispatch_semaphore_signal(_lock);
    return result;
}

- (void)enumerateKeysAndObjectsUsingBlock:(void (^)(id, id, BOOL *))block {
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    NSDictionary *dic = _dictionary.copy;
    dispatch_semaphore_signal(_lock);
    if (block) {
        [dic enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            block(key, obj, stop);
        }];
    }
}

- (void)willResignActive:(NSNotification *)notification {
    if (_shouldSaveKeyAccessTimeBeforeResigning) {
        [[NSUserDefaults standardUserDefaults] setObject:self.keyAccessTime forKey:kTTKitchenKeyAccessTime];
    }
}

@end
