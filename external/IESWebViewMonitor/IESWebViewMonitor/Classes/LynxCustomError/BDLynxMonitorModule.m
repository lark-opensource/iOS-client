//
//  BDLynxMonitorModule.m
//  IESWebViewMonitor
//
//  Created by Paklun Cheng on 2020/9/24.
//

#import "BDLynxMonitorModule.h"
#import "BDLynxMonitorPool.h"
#import "IESLynxPerformanceDictionary.h"
#import "IESLiveMonitorUtils.h"
#import "IESLynxMonitor.h"
#import <Lynx/LynxError.h>
#import "BDLynxCustomErrorMonitor.h"
#import "BDHybridMonitor.h"
#import "LynxView+Monitor.h"
#import "BDMonitorThreadManager.h"

typedef NS_ENUM(NSInteger, LynxCallbackStatus) {
    LynxCallbackStatusFailed = -1,
    LynxCallbackStatusSucceed = 0,
};

@interface BDLynxMonitorModule()

@property (nonatomic, strong) NSString *containerID;

@end

@implementation BDLynxMonitorModule
+ (NSDictionary<NSString *, NSString *> *)methodLookup
{
    return @{
        @"reportJSError" : NSStringFromSelector(@selector(reportJSError:callback:)),
        @"customReport":
            NSStringFromSelector(@selector(customReport:callback:))
    };
}

+ (NSString *)name
{
    return @"hybridMonitor";
}

- (instancetype)initWithParam:(NSDictionary *)param
{
    self = [super init];
    if (self) {
        _containerID = param[@"containerID"];
    }
    return self;
}

#pragma mark -
- (void)customReport:(NSDictionary *)params  callback:(LynxCallbackBlock)callback{
    [BDMonitorThreadManager dispatchAsyncHandlerForceOnMonitorThread:^{
        NSString *eventName = params[@"eventName"];
        NSMutableDictionary *encodedMessage = [NSMutableDictionary new];
        if (eventName.length <= 0) {
            encodedMessage[@"errorCode"] = @(-1);
            encodedMessage[@"errorMessage"] = @"without event name";
            if (callback) {
                callback(encodedMessage);
            }
            return;;
        }
        
        BOOL canSample = YES;
        if (params[@"canSample"]) {
            NSInteger value = [params[@"canSample"] integerValue];
            canSample = (value==1);
        }
        LynxView *lynxView = [BDLynxMonitorPool lynxViewForContainerID:self.containerID];
        [BDHybridMonitor lynxReportCustomWithEventName:eventName
                                              LynxView:lynxView
                                                metric:params[@"metrics"]
                                              category:params[@"category"]
                                                 extra:params[@"extra"]
                                                timing:params[@"timing"]
                                             maySample:canSample];
        encodedMessage[@"errorCode"] = @(0);
        if (callback) {
            callback(encodedMessage);
        }
    }];
}

- (void)reportJSError:(NSDictionary *)params  callback:(LynxCallbackBlock)callback{
    [BDMonitorThreadManager dispatchAsyncHandlerForceOnMonitorThread:^{
        LynxView *lynxView = [BDLynxMonitorPool lynxViewForContainerID:self.containerID];
        NSString *userInfo = [IESLiveMonitorUtils convertToJsonData:params];
        NSError *customError = [[NSError alloc] initWithDomain:@"customReportJSError" code:LynxErrorCodeJavaScript userInfo:@{LynxErrorUserInfoKeyMessage:userInfo ? : @""}];
        NSMutableDictionary *encodedMessage = [[NSMutableDictionary alloc] init];
        if(!lynxView) {
            encodedMessage[@"errorCode"] = @(LynxCallbackStatusFailed);
            encodedMessage[@"errorMessage"] = @"associate lynxView is nil";
            if (callback) {
                callback(encodedMessage);
            }
        } else {
            [BDLynxCustomErrorMonitor lynxView:lynxView didRecieveError:customError];
            encodedMessage[@"errorCode"] = @(LynxCallbackStatusSucceed);
            if (callback) {
                callback(encodedMessage);
            }
        }
    }];
}



@end
