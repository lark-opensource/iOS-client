//
//  OKInternalTask.m
//  OKStartUp
//
//  Created by bob on 2020/1/15.
//

#import "OKInternalTask.h"
#import "OKSectionFunction.h"
#import "OKStartUpFunction.h"

@implementation OKInternalTask

- (void)startWithLaunchOptions:(NSDictionary<UIApplicationLaunchOptionsKey,id> *)launchOptions {
    OKSectionFunction *function = [OKSectionFunction sharedInstance];
    [function excuteFunctionsForKey:@OKAppLoadService];
    [function excuteSwiftFunctionsForKey:@OKAppLoadService];
    
    [function excuteFunctionsForKey:@OKAppInfoConfigKey];
    [function excuteSwiftFunctionsForKey:@OKAppInfoConfigKey];
    
    [function excuteFunctionsForKey:@OKAppTaskConfigKey];
    [function excuteSwiftFunctionsForKey:@OKAppTaskConfigKey];
    
    [function excuteFunctionsForKey:@OKAppTaskAddKey];
    [function excuteSwiftFunctionsForKey:@OKAppTaskAddKey];
}

@end
