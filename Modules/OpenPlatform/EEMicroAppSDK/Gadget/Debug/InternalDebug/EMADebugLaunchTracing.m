//
//  EMADebugLaunchTracing.m
//  EEMicroAppSDK
//
//  Created by Limboy on 2020/3/10.
//

#import "EMADebugLaunchTracing.h"
#import "EERoute.h"
#import "EMAAppEngine.h"
#import <OPFoundation/EMADebugUtil.h>
#import <OPFoundation/BDPDeviceHelper.h>
#import <ECOInfra/BDPLog.h>
#import <OPFoundation/BDPMonitorHelper.h>
#import <OPFoundation/BDPTrackerEvents.h>
#import <OPFoundation/BDPUtils.h>
#import <ECOInfra/EMAConfigManager.h>
#import <EEMicroAppSDK/EEMicroAppSDK-Swift.h>

@interface EMADebugLaunchTracing()
@property (nonatomic, strong) NSMutableArray *tracingEvents;
@property (nonatomic) BOOL shouldStopTracing;
@end

@implementation EMADebugLaunchTracing

+ (instancetype)sharedInstance {
    static id sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (dispatch_queue_t)serialQueue {
    static dispatch_queue_t serialQueue;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        serialQueue = dispatch_queue_create("debug.launchTracing.queue", DISPATCH_QUEUE_SERIAL);;
    });
    return serialQueue;
}

- (void)updateDebugConfig {
    // 用于获取最新的 JSSDK URL
    NSString *jssdkURL = @"https://cloudapi.bytedance.net/faas/services/ttnbrzs5vgcryya2z2/invoke/jssdk_url";

    // 开启的话，使用指定的 jssdk
    if ([EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDEnableLaunchTracing].boolValue) {
        NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:jssdkURL]];
        NSURLSession *session = [NSURLSession sharedSession];
        NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:urlRequest
                                                    completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            if (httpResponse.statusCode == 200) {
                NSError *parseError = nil;
                NSDictionary *response = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
                if (!parseError && response[@"url"]) {
                    [EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDUseSpecificJSSDKURL].boolValue = @(YES);
                    [EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDSpecificJSSDKURL].stringValue = response[@"url"];
                    [EMAAppEngine.currentEngine.configManager updateConfig];
                } else {
                    BDPLogError(@"%@", parseError);
                }
            }
        }];
        [dataTask resume];
    } else {
        [EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDUseSpecificJSSDKURL].boolValue = @(NO);
        [EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDSpecificJSSDKURL].stringValue = @"";
    }
    [EMAAppEngine.currentEngine.configManager updateConfig];
}

- (void)processIfNeeded:(NSString *)name attributes:(NSDictionary *)attributes
{
    // 只有 Launch Tracing 开关打开，才会上报
    if ([EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDEnableLaunchTracing].boolValue) {
        if ([name isEqualToString:kEventName_mp_app_launch_start]) {
            [self launchTracingStart];
        }
        [self launchTracingWithName:name attributes:attributes];
        if ([name isEqualToString:BDPTELoadDomReadyEnd]) {
            [self launchTracingStop];
        }
    }
}

- (void)launchTracingStart
{
    self.shouldStopTracing = NO;
    self.tracingEvents = [[NSMutableArray alloc] init];
}

- (void)launchTracingWithName:(NSString *)name attributes:(NSDictionary *)attributes {
    [self launchTracingWithName:name
                                 pid:@"Main"
                                 tid:[NSString stringWithFormat:@"%@", [NSThread currentThread]]
                          attributes:attributes];
}

- (void)launchTracingWithName:(NSString *)name tid:(NSString *)tid attributes:(NSDictionary *)attributes {
    [self launchTracingWithName:name
                                 pid:@"Main"
                                 tid:tid
                          attributes:attributes];
}

- (void)launchTracingWithName:(NSString *)name pid:(NSString *)pid tid:(NSString *)tid attributes:(NSDictionary *)attributes {
    if (!self.shouldStopTracing) {
        if (BDPIsEmptyString(name)) {
            name = @"Undefined";
        }
        if (BDPIsEmptyString(tid)) {
            tid = @"Unknown";
        }
        if (BDPIsEmptyString(pid)) {
            pid = @"Unknown";
        }

        attributes = attributes.count == 0 ? @{} : attributes;
        NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:attributes];
        params[@"pid"] = pid;
        params[@"tid"] = tid;
        dispatch_async(self.serialQueue, ^{
            [self.tracingEvents addObject:@{name: params}];
        });
    }
}

- (void)launchTracingStop
{
    if (self.shouldStopTracing) {
        return;
    }

    self.shouldStopTracing = YES;
    if (!self.tracingEvents || self.tracingEvents.count == 0) {
        BDPLogInfo(@"no tracing events");
        return;
    }

    dispatch_async(self.serialQueue, ^{
        NSError *error;
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:nil delegateQueue:nil];
        // 这个 URL 会将打点信息处理成 Tracing 信息
        NSURL *url = [NSURL URLWithString:@"https://cloudapi.bytedance.net/faas/services/ttnbrzs5vgcryya2z2/invoke/interactive_tracing_gadget_launch"];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                               cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                           timeoutInterval:60.0];

        [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];

        [request setHTTPMethod:@"POST"];

        NSString *deviceID;
        id<EMAProtocol> delegate = [EMARouteProvider getEMADelegate];
        if([delegate respondsToSelector:@selector(hostDeviceID)]) {
            deviceID = [delegate hostDeviceID];
        }

        if (BDPIsEmptyString(deviceID)) {
            deviceID = [UIDevice currentDevice].identifierForVendor.UUIDString;
            if (BDPIsEmptyString(deviceID)) {
                deviceID = @"Unknown";
            }
        }

        NSDictionary *data = @{
            @"device": @{@"model": [BDPDeviceHelper getDeviceName],
                         @"system": [NSString stringWithFormat:@"iOS %@",  [[UIDevice currentDevice] systemVersion]],
                         @"did": deviceID
            },
            @"app": @{@"version": [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]},
            @"tracing_events": self.tracingEvents,
        };
        NSData *postData = [NSJSONSerialization dataWithJSONObject:data options:0 error:&error];
        [request setHTTPBody:postData];

        NSURLSessionDataTask *postDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error) {
                BDPLogError(@"tracing events send error: %@", error);
            }
        }];

        [postDataTask resume];
    });
}

@end
