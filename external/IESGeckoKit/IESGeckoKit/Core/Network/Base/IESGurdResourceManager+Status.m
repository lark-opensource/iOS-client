//
//  IESGurdResourceManager+Status.m
//  IESGeckoKit
//
//  Created by 陈煜钏 on 2020/8/31.
//

#import "IESGurdResourceManager+Status.h"

#import "IESGurdEventTraceManager+Message.h"

@implementation IESGurdResourceManager (Status)

static NSInteger kIESGurdRequestFailTimes = 0;
static NSInteger const kIESGurdRequestMaxFailTimes = 3;

static NSDate *kIESGurdRequestLastFailedDate = nil;
static NSDate *kIESGurdRequestFirstFailedDate = nil;

+ (void)updateServerAvailable:(BOOL)isAvailable
{
    if (isAvailable) {
        IESGurdResourceManager.retryEnabled = YES;
        IESGurdResourceManager.pollingEnabled = YES;
        
        kIESGurdRequestFailTimes = 0;
        kIESGurdRequestLastFailedDate = nil;
        kIESGurdRequestFirstFailedDate = nil;
        return;
    }
    
    kIESGurdRequestFailTimes += 1;
    kIESGurdRequestLastFailedDate = [NSDate date];
    
    NSString *message = [NSString stringWithFormat:@"【Server】Request failed %zd times", kIESGurdRequestFailTimes];
    [IESGurdEventTraceManager traceEventWithMessage:message hasError:YES shouldLog:YES];
    
    if (!kIESGurdRequestFirstFailedDate) {
        kIESGurdRequestFirstFailedDate = [NSDate date];
        return;
    }
    if ([[NSDate date] timeIntervalSinceDate:kIESGurdRequestFirstFailedDate] > 1800) {
        IESGurdResourceManager.retryEnabled = NO;
        IESGurdResourceManager.pollingEnabled = NO;
    }
}

+ (BOOL)checkIfServerAvailable
{
    if (kIESGurdRequestLastFailedDate) {
        if ([[NSDate date] timeIntervalSinceDate:kIESGurdRequestLastFailedDate] > 60) {
            kIESGurdRequestFailTimes = 0;
            kIESGurdRequestLastFailedDate = nil;
        }
    }
    
    return (kIESGurdRequestFailTimes < kIESGurdRequestMaxFailTimes);
}

#pragma mark - Accessor

static BOOL kIsRetryEnabled = YES;
+ (BOOL)isRetryEnabled
{
    return kIsRetryEnabled;
}

+ (void)setRetryEnabled:(BOOL)retryEnabled
{
    kIsRetryEnabled = retryEnabled;
}

static BOOL kIsPollingEnabled = YES;
+ (BOOL)isPollingEnabled
{
    return kIsPollingEnabled;
}

+ (void)setPollingEnabled:(BOOL)pollingEnabled
{
    kIsPollingEnabled = pollingEnabled;
}

@end
