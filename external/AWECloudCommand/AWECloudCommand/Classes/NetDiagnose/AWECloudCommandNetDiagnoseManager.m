//
//  AWECloudCommandNetDiagnoseManager.m
//  AWECloudCommand
//
//  Created by songxiangwu on 2018/4/16.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import "AWECloudCommandNetDiagnoseManager.h"

#import "AWECloudCommandNetDiagnoseAddressInfo.h"
#import "AWECloudCommandNetDiagnoseConnect.h"
#import "AWECloudCommandNetDiagnoseTraceRoute.h"
#import "AWECloudCommandNetDiagnoseUpSpeed.h"
#import "AWECloudCommandNetDiagnoseDownSpeed.h"
#import "AWECloudCommandReachability.h"
#import "NSString+AWECloudCommandUtil.h"

#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>

static NSString *const kDefaultTestHost = @"bW9uLnppamllYXBpLmNvbQ=="; //mon.zijieapi.com

@interface AWECloudCommandNetDiagnoseManager () <AWECloudCommandNetDiagnoseConnectDelegate, AWECloudCommandNetDiagnoseTraceRouteDelegate>
{
    dispatch_queue_t _processQueue;
    dispatch_semaphore_t _processSem;
}

@property (nonatomic, strong) NSMutableString *logInfo;
@property (atomic, assign) BOOL isRuning;

@property (nonatomic, assign) CGFloat currentPercent;
@property (nonatomic, copy) void(^progressBlock)(CGFloat percentage);

@property (nonatomic, strong) AWECloudCommandNetDiagnoseConnect *ConnectTester;
@property (nonatomic, strong) AWECloudCommandNetDiagnoseTraceRoute *traceRouteTester;
@property (nonatomic, strong) AWECloudCommandNetDiagnoseUpSpeed *upSpeedTester;
@property (nonatomic, strong) AWECloudCommandNetDiagnoseDownSpeed *downSpeedTester;

@end

@implementation AWECloudCommandNetDiagnoseManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        _processQueue = dispatch_queue_create("awe_net_diagnose_queue", DISPATCH_QUEUE_SERIAL);
        _processSem = dispatch_semaphore_create(0);
    }
    return self;
}

- (void)dealloc
{
    _ConnectTester.delegate = nil;
    _traceRouteTester.delegate = nil;
}

- (void)startNetDiagnose
{
    [self startNetDiagnoseWithCompletionBlock:nil];
}

- (void)startNetDiagnoseWithCompletionBlock:(void (^_Nullable)(NSString *))completion
{
    [self startNetDiagnoseWithProgressBlock:nil completionBlock:completion];
}

- (void)startNetDiagnoseWithProgressBlock:(void (^ _Nullable)(CGFloat))progressBlock completionBlock:(void (^ _Nullable)(NSString *))completion
{
    self.isRuning = YES;
    dispatch_async(_processQueue, ^{
        self.currentPercent = 0;
        self.progressBlock = progressBlock;
        if (!self.testHost) {
            self.testHost = [kDefaultTestHost cloudcommand_base64Decode];
        }
        self.logInfo = [[NSMutableString alloc] initWithString:@""];
        [self _outputInfo:@"Start diagnosis..."];
        [self _outputAppInfo];
        AWECloudCommandNetworkStatus status = [AWECloudCommandReachability reachabilityForInternetConnection].currentReachabilityStatus;
        if (status != AWECloudCommandNotReachable) {
            [self _outputNetInfo];
            [self _outputConnectInfo];
        }
        self.currentPercent = 1;
        [self _updateProgress];
        [self _netDiagnoseDidFinish];
        if (completion) {
            completion(self.logInfo);
        }
    });
}

- (void)stopNetDiagnose
{
    self.isRuning = NO;
    if (_processSem) {
        dispatch_semaphore_signal(_processSem);
    }
    __weak typeof(self) weakSelf =self;
    dispatch_async(_processQueue, ^{
        __strong typeof(weakSelf) self = weakSelf;
        self.progressBlock = nil;
        [self.ConnectTester stop];
        [self.traceRouteTester stopTrace];
    });
}

- (void)_outputAppInfo
{
    UIDevice *device = [UIDevice currentDevice];
    [self _outputInfo:[NSString stringWithFormat:@"Application Code: %@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"SSAppID"]]];
    [self _outputInfo:[NSString stringWithFormat:@"Application Name: %@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"AppName"]]];
    [self _outputInfo:[NSString stringWithFormat:@"Application Version: %@", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]]];
    [self _outputInfo:[NSString stringWithFormat:@"Machine Type: %@", device.model]];
    [self _outputInfo:[NSString stringWithFormat:@"System Version: %@", device.systemVersion]];
    [self _outputInfo:[NSString stringWithFormat:@"Operator: %@", [self _carrierName]]];
    [self _outputInfo:[NSString stringWithFormat:@"Network Type: %@", [self.class _networkType]]];
    [self _updateProgress];
}

- (void)_outputNetInfo
{
    [self _outputInfo:[NSString stringWithFormat:@"Current Native IP: %@", [AWECloudCommandNetDiagnoseAddressInfo deviceIPAdress]]];
    [self _outputInfo:[NSString stringWithFormat:@"Local Gateway: %@", [AWECloudCommandNetDiagnoseAddressInfo getGatewayIPAddress]]];
    [self _outputInfo:[NSString stringWithFormat:@"Local DNS: %@", [AWECloudCommandNetDiagnoseAddressInfo outPutDNSServers]]];
    [self _updateProgress];
}

- (void)_outputConnectInfo
{
    NSTimeInterval st =0;
    long long duration = 0;
    NSString *contrastHost = @"";
    [self _outputInfo:[NSString stringWithFormat:@"Start domain name resolution: %@...", self.testHost]];
    st = [[NSDate date] timeIntervalSince1970];
    NSArray *ipArray = [AWECloudCommandNetDiagnoseAddressInfo getDNSsWithDormain:self.testHost];
    duration = ([[NSDate date] timeIntervalSince1970] - st) * 1000;
    if (!ipArray.count) {
        [self _outputInfo:[NSString stringWithFormat:@"Domain name resolution results: Failure"]];
        [self _updateProgress];
    } else {
        [self _outputInfo:[NSString stringWithFormat:@"Domain name resolution results:: %@ (%lldms)", ipArray, duration]];
        [self _updateProgress];
    }
    
    if (!self.isRuning) {
        return;
    }
    
    [self _outputInfo:[NSString stringWithFormat:@"Start ping: %@...", self.testHost]];
    [self.ConnectTester startPingWithHost:self.testHost maxLoop:4];
    dispatch_semaphore_wait(_processSem, DISPATCH_TIME_FOREVER);
    [self _outputInfo:@"End ping"];
    [self _updateProgress];
    
    if (!self.isRuning) {
        return;
    }
    
    contrastHost = @"www.baidu.com";
    [self _outputInfo:[NSString stringWithFormat:@"Start ping: %@...", contrastHost]];
    [self.ConnectTester startPingWithHost:contrastHost maxLoop:4];
    dispatch_semaphore_wait(_processSem, DISPATCH_TIME_FOREVER);
    [self _outputInfo:@"End ping"];
    [self _updateProgress];
    
    if (!self.isRuning) {
        return;
    }
    
    [self _outputInfo:[NSString stringWithFormat:@"Start traceroute: %@...", self.testHost]];
    [self.traceRouteTester doTraceRoute:self.testHost];
    dispatch_semaphore_wait(_processSem, DISPATCH_TIME_FOREVER);
    [self _outputInfo:@"End traceroute"];
    [self _updateProgress];
    
    if (!self.isRuning) {
        return;
    }
    
    __block NSString *resourceUrl = nil;
    [self _outputInfo:[NSString stringWithFormat:@"Start testing upload speed..."]];
    __weak typeof(self) weakSelf =self;
    __weak typeof(_processSem) weakProcessSem =_processSem;
    [self.upSpeedTester startUpSpeedTestWithCompletion:^(CGFloat speed, NSError *error, NSString *url) {
        if (error) {
            [weakSelf _outputInfo:@"Upload speed test results: Faliure"];
        } else {
            [weakSelf _outputInfo:[NSString stringWithFormat:@"Upload speed test results: %.2lfk/s", speed]];
            resourceUrl = url;
        }
        [weakSelf _updateProgress];
        if (weakProcessSem) {
            dispatch_semaphore_signal(weakProcessSem);
        }
    }];
    dispatch_semaphore_wait(_processSem, DISPATCH_TIME_FOREVER);
    
    if (!self.isRuning) {
        return;
    }
    
    if (resourceUrl) {
        [self _outputInfo:[NSString stringWithFormat:@"Start testing download speed..."]];
        
        __weak typeof(_processSem) weakProcessSem =_processSem;
        [self.downSpeedTester startDownSpeedTestWithUrl:resourceUrl completion:^(CGFloat speed, NSError *error) {
            if (error) {
                [weakSelf _outputInfo:@"Download speed test results: Failure"];
            } else {
                [weakSelf _outputInfo:[NSString stringWithFormat:@"Download speed test results: %.2lfk/s", speed]];
            }
            [weakSelf _updateProgress];
            if (weakProcessSem) {
                dispatch_semaphore_signal(weakProcessSem);
            }
        }];
        dispatch_semaphore_wait(_processSem, DISPATCH_TIME_FOREVER);
    }
}

- (void)_netDiagnoseDidFinish
{
    [self _outputInfo:@"End Diagnosis"];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(netDiagnoseDidFinish)]) {
            [self.delegate netDiagnoseDidFinish];
        }
    });
}

- (void)_outputInfo:(NSString *)info
{
    if (!info) {
        info = @"";
    }
    info = [info stringByAppendingString:@"\n"];
    [self.logInfo appendString:info];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(netDiagnoseOutputInfo:)]) {
            [self.delegate netDiagnoseOutputInfo:info];
        }
    });
}

- (void)_updateProgress
{
    self.currentPercent += 0.1;
    if (self.currentPercent >= 1) {
        self.currentPercent = 1;
    }
    if (self.progressBlock) {
        self.progressBlock(self.currentPercent);
    }
}

+ (NSString *)_networkType
{
    AWECloudCommandNetworkStatus status = [AWECloudCommandReachability reachabilityForInternetConnection].currentReachabilityStatus;
    if (status == AWECloudCommandReachableViaWiFi) {
        return @"wifi";
    } else if (status == AWECloudCommandReachableVia4G) {
        return @"4g";
    } else if (status == AWECloudCommandReachableVia3G) {
        return @"3g";
    } else if (status == AWECloudCommandReachableVia2G) {
        return @"2g";
    } else {
        return @"unreachable";
    }
}

- (NSString*)_carrierName
{
    CTTelephonyNetworkInfo *netinfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = [netinfo subscriberCellularProvider];
    NSString *name = [carrier carrierName];
    return name;
}

- (void)didAppendPingLog:(NSString *)log
{
    [self _outputInfo:log];
}

- (void)didFinishPing
{
    if (_processSem) {
        dispatch_semaphore_signal(_processSem);
    }
}

- (void)didAppendTraceRouteLog:(NSString *)log
{
    [self _outputInfo:log];
}

- (void)didFinishTraceRoute
{
    if (_processSem) {
        dispatch_semaphore_signal(_processSem);
    }
}

- (AWECloudCommandNetDiagnoseConnect *)ConnectTester
{
    if (!_ConnectTester) {
        _ConnectTester = [[AWECloudCommandNetDiagnoseConnect alloc] init];
        _ConnectTester.delegate = self;
    }
    return _ConnectTester;
}

- (AWECloudCommandNetDiagnoseTraceRoute *)traceRouteTester
{
    if (!_traceRouteTester) {
        _traceRouteTester = [[AWECloudCommandNetDiagnoseTraceRoute alloc] initWithMaxTTL:30 timeout:5000 maxAttempts:3 port:80];
        _traceRouteTester.delegate = self;
    }
    return _traceRouteTester;
}

- (AWECloudCommandNetDiagnoseUpSpeed *)upSpeedTester
{
    if (!_upSpeedTester) {
        _upSpeedTester = [[AWECloudCommandNetDiagnoseUpSpeed alloc] init];
    }
    return _upSpeedTester;
}

- (AWECloudCommandNetDiagnoseDownSpeed *)downSpeedTester
{
    if (!_downSpeedTester) {
        _downSpeedTester = [[AWECloudCommandNetDiagnoseDownSpeed alloc] init];
    }
    return _downSpeedTester;
}

@end
