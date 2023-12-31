//
//  TTGameExpDiagnosisService.m
//  TTNetworkManager
//
//  Created by zhangzeming on 2021/6/28.
//  Copyright © 2021 bytedance. All rights reserved.
//


#import "TTGameExpDiagnosisService.h"
#import "TTExpDiagnosisRequestProtocol.h"
#import "TTExpDiagnosisService.h"
#import "TTNetworkManagerLog.h"

@interface TTGameExpDiagnosisService ()

@property (atomic, assign) BOOL isMonitoring;
@property (atomic, strong) NSObject<TTExpDiagnosisRequestProtocol>* request;

@end

@implementation TTGameExpDiagnosisService

+ (instancetype)shareInstance {
    static id singleton = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [[self alloc] init];
    });
    return singleton;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.isMonitoring = NO;
        self.request = nil;
    }
    return self;
}

- (void)monitorBegin:(NSString*)target
           extraInfo:(NSString*)extraInfo {
    if (self.isMonitoring) {
        return;
    }
    self.request = [[TTExpDiagnosisService shareInstance] createRequestWithReqestType:DIAGNOSE_V2_TARGET
                                                                               target:target
                                                                        netDetectType:(TTExpNetDetectType)0
                                                                            timeoutMs:std::numeric_limits<int64_t>::max()
                                                                             callback:^(NSString *report) {
        // Do nothing.
        LOGD(@"report: %@", report);
    }];
    [self.request start];
    [self.request doExtraCommand:@"extra_info" extraMessage:extraInfo];
    self.isMonitoring = YES;
    
}

- (void)monitorEnd {
    [self monitorEnd:nil];
}

- (void)monitorEnd:(NSString*)extraInfo {
    if (!self.isMonitoring) {
        return;
    }
    if (extraInfo != nil) {
        [self.request doExtraCommand:@"extra_info" extraMessage:extraInfo];
    }
    [self.request doExtraCommand:@"finish" extraMessage:@""];
    self.isMonitoring = NO;
}

- (void)doDiagnosisDuringGaming:(NSString*)extraMessage {
    if (!self.isMonitoring) {
        return;
    }
    [self.request doExtraCommand:@"diagnosis" extraMessage:extraMessage];
}

@end
