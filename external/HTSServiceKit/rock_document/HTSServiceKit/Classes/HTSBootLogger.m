//
//  HTSBootLogger.m
//  HTSBootLoader
//
//  Created by Huangwenchen on 2019/11/16.
//  Copyright © 2019 bytedance. All rights reserved.
//

#import "HTSBootLogger.h"

@interface HTSBootLogger()

@property (strong, nonatomic) NSMutableArray * mainData;
@property (strong, nonatomic) NSMutableArray * backgroundData;

@end

@implementation HTSBootLogger

+ (instancetype)sharedLogger{
    static dispatch_once_t onceToken;
    static HTSBootLogger * _instance;
    dispatch_once(&onceToken, ^{
        _instance = [[HTSBootLogger alloc] init];
    });
    return _instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _mainData = [[NSMutableArray alloc] init];
        _backgroundData = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)logName:(NSString *)name duration:(NSTimeInterval)duration{
    if (!name) {
        return;
    }
    NSDictionary * metrics = @{
        @"name": name,
        @"duration": @(duration)
    };
    @synchronized (self) {
        if ([NSThread currentThread].isMainThread) {
            [self.mainData addObject:metrics];
        }else{
            [self.backgroundData addObject:metrics];
        }
    }
}

- (NSArray *)backgroundMetrics{
    NSArray * data;
    @synchronized (self) {
        data = self.backgroundData.copy;
    }
    return data;
}

- (NSArray *)mainMetrics{
    NSArray * data;
    @synchronized (self) {
        data = self.mainData.copy;
    }
    return data;
}

@end

