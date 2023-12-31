//
//  IESGurdAppLog.m
//  BDAlogProtocol
//
//  Created by 陈煜钏 on 2020/5/21.
//

#import "IESGurdAppLog.h"

#import <IESGeckoKit/IESGeckoKit.h>
#import <BDTrackerProtocol/BDTrackerProtocol.h>

@implementation IESGurdAppLog

+ (void)load
{
    IESGurdKit.appLogDelegate = [self sharedInstance];
}

+ (instancetype)sharedInstance
{
    static IESGurdAppLog *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

#pragma mark - IESGurdAppLogDelegate

- (void)trackEvent:(NSString *)event params:(NSDictionary *)params
{
    if (event.length == 0 || params.count == 0) {
        return;
    }
    [BDTrackerProtocol eventV3:event params:params];
}

@end
