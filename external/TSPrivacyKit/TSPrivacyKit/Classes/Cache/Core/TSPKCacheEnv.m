//
//  TSPKCacheEnv.m
//  T-Develop
//
//  Created by admin on 2022/6/29.
//

#import "TSPKCacheEnv.h"
#import "TSPKCacheProcessor.h"
#import "TSPKLock.h"

@interface TSPKCacheEnv ()

@property (nonatomic, strong, nullable) NSMutableDictionary<NSString *, TSPKCacheProcessor *> *processorDict;
@property (nonatomic, strong) id<TSPKLock> lock;

@end

@implementation TSPKCacheEnv

- (instancetype)init
{
    self = [super init];
    if (self) {
        _processorDict = [NSMutableDictionary dictionary];
        _lock = [TSPKLockFactory getLock];
    }
    return self;
}

+ (nonnull instancetype)shareEnv {
    static TSPKCacheEnv *env;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        env = [[TSPKCacheEnv alloc] init];
    });
    return env;
}

- (void)registerProcessor:(TSPKCacheProcessor *)processor key:(NSString *)key {
    [_lock lock];
    [self.processorDict setValue:processor forKey:key];
    [_lock unlock];
}

- (void)unregisterProcessor:(NSString *)key {
    [_lock lock];
    [self.processorDict removeObjectForKey:key];
    [_lock unlock];
}

- (BOOL)containsProcessor:(NSString *)key {
    BOOL isContain = NO;
    [_lock lock];
    isContain = self.processorDict[key] != nil;
    [_lock unlock];
    return isContain;
}

- (BOOL)needUpdate:(NSString *)key {
    [_lock lock];
    TSPKCacheProcessor *processor = self.processorDict[key];
    [_lock unlock];
    if (processor) {
        return [processor needUpdate:key];
    }
    return YES;
}

- (id)get:(NSString *)key {
    [_lock lock];
    TSPKCacheProcessor *processor = self.processorDict[key];
    [_lock unlock];
    if (processor) {
        return [processor get:key];
    }
    return nil;
}

- (void)updateCache:(NSString *)key newValue:(id)value {
    [_lock lock];
    TSPKCacheProcessor *processor = self.processorDict[key];
    [_lock unlock];
    if (processor) {
        [processor updateCache:key newValue:value];
    }
}

@end
