//
//  TSPKMemoryStore.m
//  BDRuleEngine-Pods-Baymax_MusicallyTests-Unit-_Tests
//
//  Created by admin on 2022/6/29.
//

#import "TSPKMemoryStore.h"
#import "TSPKLock.h"

@interface TSPKMemoryStore ()

@property (nonatomic, strong, nullable) NSMutableDictionary<NSString *, id> *valueDict;
@property (nonatomic, strong) id<TSPKLock> lock;

@end

@implementation TSPKMemoryStore

- (instancetype)init
{
    self = [super init];
    if (self) {
        _valueDict = [NSMutableDictionary dictionary];
        _lock = [TSPKLockFactory getLock];
    }
    return self;
}

+ (instancetype)sharedStore {
    static TSPKMemoryStore *store;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        store = [[TSPKMemoryStore alloc] init];
    });
    return store;
}

- (void)put:(NSString *)key value:(id)value {
    if (key) {
        [_lock lock];
        if (value) {
            [_valueDict setValue:value forKey:key];
        } else {
            [_valueDict setValue:[NSNull null] forKey:key];
        }
        [_lock unlock];
    }
}

- (id)get:(NSString *)key {
    [_lock lock];
    id value = _valueDict[key];
    [_lock unlock];
    if ([value isEqual:[NSNull null]]) {
        return nil;
    }
    return value;
}

- (BOOL)containsKey:(NSString *)key {
    [_lock lock];
    BOOL isContain = [_valueDict objectForKey:key] != nil;
    [_lock unlock];
    return isContain;
}

@end
