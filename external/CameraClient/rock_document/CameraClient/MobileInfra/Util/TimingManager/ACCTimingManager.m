//
//  ACCTimingManager.m
//  ACCFoundation
//
//  Created by Stan Shan on 2018/6/5.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import "ACCTimingManager.h"

@interface ACCTimingManager()

@property (nonatomic, strong) NSMutableDictionary<id<NSCopying>, NSNumber *> *timingDict;
@property (nonatomic, strong) dispatch_semaphore_t lock;

@end

@implementation ACCTimingManager

+ (instancetype)sharedInstance {
    static ACCTimingManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [self new];
    });
    return instance;
}

#pragma mark - Initialization

- (instancetype)init
{
    self = [super init];
    if (self) {
        _lock = dispatch_semaphore_create(1);
    }
    return self;
}

#pragma mark - Public Methods

- (void)startTimingForKey:(id<NSCopying>)key
{
    if (key) {
        dispatch_semaphore_wait(self.lock, DISPATCH_TIME_FOREVER);
        NSNumber *startTime = @(CACurrentMediaTime() * 1000.0f);
        [[self timingDict] setObject:startTime forKey:key];
        dispatch_semaphore_signal(self.lock);
    }
}

- (NSTimeInterval)timeIntervalForKey:(nonnull id<NSCopying>)key
{
    NSNumber *startTime = [self.timingDict objectForKey:key];
    if (startTime == nil) {
        return 0;
    }
    double endTime = CACurrentMediaTime() * 1000.0f;
    NSTimeInterval timeInterval = endTime - [startTime doubleValue];
    return timeInterval;
}

- (NSTimeInterval)stopTimingForKey:(id<NSCopying>)key
{
    NSTimeInterval timeInterval = [self timeIntervalForKey:key];
    [self cancelTimingForKey:key];
    return timeInterval;
}

- (void)cancelTimingForKey:(nonnull id<NSCopying>)key
{
    if (key) {
        dispatch_semaphore_wait(self.lock, DISPATCH_TIME_FOREVER);
        [self.timingDict removeObjectForKey:key];
        dispatch_semaphore_signal(self.lock);
    }
}

#pragma mark - Properties

- (NSMutableDictionary *)timingDict
{
    if (!_timingDict) {
        _timingDict = [[NSMutableDictionary alloc] init];
    }
    return _timingDict;
}

@end
