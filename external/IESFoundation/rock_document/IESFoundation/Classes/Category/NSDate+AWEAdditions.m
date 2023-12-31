//
//  NSDate+AWEAdditions.m
//  AWEFoundationKit-Pods-Aweme
//
//  Created by 陈煜钏 on 2020/2/7.
//

#import "NSDate+AWEAdditions.h"

static long long kServerTimeInterval = 0;

@implementation NSDate (AWEAdditions)

+ (void)awe_adjustWithServerTime:(long long)serverTime
{
    if (serverTime > 0) {
        long long currentTime = [[self date] timeIntervalSince1970] * 1000;
        kServerTimeInterval = currentTime - serverTime;
    }
}

+ (long long)awe_currentServerTime
{
    long long currentTime = [[self date] timeIntervalSince1970] * 1000;
    return currentTime - kServerTimeInterval;
}

@end
