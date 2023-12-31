//
//  TSPKAppBackgroundFunc.m
//  Indexer
//
//  Created by admin on 2022/2/15.
//

#import "TSPKAppBackgroundFunc.h"
#import "TSPKAppLifeCycleObserver.h"
#import "TSPKUtils.h"

static const NSInteger defaultDelayTime = 2;

@implementation TSPKAppBackgroundFunc

- (NSString *)symbol {
    return @"is_background";
}

- (id)execute:(NSMutableArray *)params {
    if ([[TSPKAppLifeCycleObserver sharedObserver] isAppBackground]) {
        NSTimeInterval interval = [TSPKUtils getUnixTime] - [[TSPKAppLifeCycleObserver sharedObserver] getTimeLastDidEnterBackground];
        NSTimeInterval delayTime = defaultDelayTime;
        if ([params count] == 1 ) {
            delayTime = [[params objectAtIndex:0] intValue];
        }
        return @(interval > delayTime);
    }
    return @(NO);
}

@end
