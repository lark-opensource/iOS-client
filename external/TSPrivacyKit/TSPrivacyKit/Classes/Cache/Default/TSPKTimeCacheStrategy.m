//
//  TSPKTimeCacheStrategy.m
//  BDRuleEngine-Pods-Baymax_MusicallyTests-Unit-_Tests
//
//  Created by admin on 2022/6/29.
//

#import "TSPKTimeCacheStrategy.h"
#import "TSPKLock.h"

@interface TSPKTimeCacheStrategy ()

@property (nonatomic) NSInteger duration;
@property (nonatomic, strong, nullable) NSMutableDictionary<NSString *, NSNumber *> *lastTimeStampDict;
@property (nonatomic, strong) id<TSPKLock> lock;

@end

@implementation TSPKTimeCacheStrategy

- (instancetype)init
{
    self = [super init];
    if (self) {
        _lastTimeStampDict = [NSMutableDictionary dictionary];
        _lock = [TSPKLockFactory getLock];
    }
    return self;
}

+ (instancetype)generate:(NSDictionary *)config {
    NSInteger duration = [[config objectForKey:@"duration"] intValue];
    if (duration > 0) {
        return [self initWithDuration:duration];
    }
    return [self initWithDuration:60];
}

+ (instancetype)initWithDuration:(NSInteger)duration {
    TSPKTimeCacheStrategy *strategy = [TSPKTimeCacheStrategy new];
    strategy.duration = duration;
    return strategy;
}

- (BOOL)needUpdate:(NSString *)key cacheStore:(id<TSPKCacheStore>)store {
    CFAbsoluteTime currentTime = CFAbsoluteTimeGetCurrent();
    
    // 判断是否已经缓存
    BOOL hasContained = [store containsKey:key];
    if (!hasContained) {
        [_lock lock];
        [_lastTimeStampDict setValue:@(currentTime) forKey:key];
        [_lock unlock];
        return YES;
    }
    
    [_lock lock];
    NSNumber *lastTimeStamp = _lastTimeStampDict[key];
    [_lock unlock];
    if (lastTimeStamp) {
        if (currentTime - [lastTimeStamp doubleValue] <= _duration) {
            return NO;
        }
    }
    [_lock lock];
    [_lastTimeStampDict setValue:@(currentTime) forKey:key];
    [_lock unlock];
    return YES;
}



@end
