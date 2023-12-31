//
//  MMMemoryRecordLaunchTime.m
//  Pods-IESDetection_Example
//
//  Created by zhufeng on 2021/8/25.
//

#import "MMMemoryRecordLaunchTime.h"
#import "MMMatrixPathUtil.h"
#import "MMMemoryLog.h"

@interface MMMemoryRecordLaunchTime ()
@property (nonatomic, assign) uint64_t lastSessionLaunchTime;
@property (nonatomic, assign) uint64_t currentSessionLaunchTime;
@end

@implementation MMMemoryRecordLaunchTime

+ (instancetype)shared {
    static MMMemoryRecordLaunchTime *obj;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        obj = [[MMMemoryRecordLaunchTime alloc] init];
    });
    return obj;
}

- (void)onAppLaunch {
    self.currentSessionLaunchTime = (uint64_t)time(NULL);
    
    // read last launch time
    self.lastSessionLaunchTime = [MMMemoryRecordLaunchTime readLaunchTime];
    
    // write
    [MMMemoryRecordLaunchTime writeLaunchTime:self.currentSessionLaunchTime];
}


+ (uint64_t)readLaunchTime {
    uint64_t launchTime = 0;
    @try {
        NSString *path = [MMMatrixPathUtil memoryStatLaunchTimePath];
        NSData * data = [[NSData alloc] initWithContentsOfFile:path];
        [data getBytes:&launchTime length:sizeof(uint64_t)];
    } @catch (NSException *e) {
        MatrixError(@"read launch time exception = %@",e)
    }
    return launchTime;
}

+ (void)writeLaunchTime:(uint64_t)launchTime {
    @try {
        NSString *path = [MMMatrixPathUtil memoryStatLaunchTimePath];
        NSData * data = [[NSData alloc] initWithBytes:&launchTime length:sizeof(uint64_t)];
        [data writeToFile:path atomically:YES];
    } @catch (NSException *e) {
        MatrixError(@"write launch time exception = %@",e)
    }
}


@end
