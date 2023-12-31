//
//  TSPKAdvanceAppStatusTrigger.m
//  TSPrivacyKit
//
//  Created by PengYan on 2021/3/27.
//

#import "TSPKAdvanceAppStatusTrigger.h"

#import "TSPKUtils.h"

const NSTimeInterval defaultMinAppStatusChangeTime = 2;

@interface TSPKAdvanceAppStatusTrigger ()

@property (nonatomic) BOOL detectEnterForeground;

@property (nonatomic) NSTimeInterval minAppStatusChangeTime;
@property (nonatomic) NSTimeInterval lastTimeInBackground;

@end

@implementation TSPKAdvanceAppStatusTrigger

- (void)decodeParams:(NSDictionary *_Nonnull)params
{
    self.detectEnterForeground = false;
    self.minAppStatusChangeTime = defaultMinAppStatusChangeTime;
    
    NSString *appStatus = (NSString *)params[@"appStatus"];
    if ([appStatus isEqualToString:@"Active"]) {
        self.detectEnterForeground = true;
    }
    if (params[@"minAppStatusChangeTime"]) {
        self.minAppStatusChangeTime = MAX(0, [params[@"minAppStatusChangeTime"] doubleValue]);
    }
}

- (void)setup
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationEnterForeground)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationEnterBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)applicationEnterForeground
{
    if (!self.detectEnterForeground) {
        return;
    }
    
    if (self.lastTimeInBackground < DBL_EPSILON) {
        return;
    }
    
    NSTimeInterval currentTime = [TSPKUtils getRelativeTime];
    // in case some border condition
    if (currentTime - self.lastTimeInBackground < self.minAppStatusChangeTime) {
        return;
    }
    
    [self executeDetectAction];
}

- (void)applicationEnterBackground
{
    self.lastTimeInBackground = [TSPKUtils getRelativeTime];
}

- (void)executeDetectAction
{
    TSPKDetectCondition *condition = [TSPKDetectCondition new];
    condition.timeGapToIgnoreStatus = self.minAppStatusChangeTime / 2;
    TSPKDetectEvent *event = [TSPKDetectEvent new];
    event.condition = condition;
    !self.detectAction ?: self.detectAction(event);
}

@end
