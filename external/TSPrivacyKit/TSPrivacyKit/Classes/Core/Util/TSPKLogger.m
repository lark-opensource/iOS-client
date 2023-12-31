//
//  TSPKLogger.m
//  TSPrivacyKit-Pods-AwemeCore
//
//  Created by bytedance on 2022/1/11.
//

#import "TSPKLogger.h"
#import <ByteDanceKit/ByteDanceKit.h>
#import "TSPKConfigs.h"
#import <PNSServiceKit/PNSServiceCenter.h>
#import <PNSServiceKit/PNSLoggerProtocol.h>
#import <PNSServiceKit/PNSLogUploaderProtocol.h>

@implementation TSPKLogger

+ (Class<PNSLoggerProtocol>)logger
{
    static Class<PNSLoggerProtocol> logger;
    if (!logger) {
        logger = PNS_GET_CLASS(PNSLoggerProtocol);
    }
    return logger;
}

+ (void)logWithTag:(NSString *)tag message:(id)logObj {
    NSString *json;
    if([logObj isKindOfClass:[NSDictionary class]] || [logObj isKindOfClass:[NSArray class]]){
        json = [logObj btd_jsonStringEncoded];
    }else if([logObj isKindOfClass:[NSString class]]){
        json = logObj;
    }else{
        //TODO: invalid object need to convert to string
    }
    
    if (!BTD_isEmptyString(json)) {
        [[self logger] setLogWithFileName:[NSString stringWithFormat:@"TSPKLogger"]
                                 funcName:[NSString stringWithFormat:@"logWithTag:message:"]
                                      tag:tag
                                     line:37
                                    level:PNSLogLevelInfo
                                   format:[NSString stringWithFormat:@"%@", json]];
    }
}

static NSInteger tTSPKReportCount = 0;

+ (void)reportALogWithoutDelay {
    [self reportALogWithDelayDecision:NO];
}

+ (void)reportALog {
    [self reportALogWithDelayDecision:YES];
}

+ (void)reportALogWithDelayDecision:(BOOL)needDelay {
    BOOL enable = [[TSPKConfigs sharedConfig] enableUploadAlog];
    if (!enable) {
        return;
    }
    
    NSInteger maxCount = [[TSPKConfigs sharedConfig] maxUploadCount];
    if (tTSPKReportCount >= maxCount) {
        return;
    }
    tTSPKReportCount = tTSPKReportCount + 1;
    
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval range = [[TSPKConfigs sharedConfig] timeRangeToUploadAlog];
    
    if (needDelay) {
        NSTimeInterval delay = [[TSPKConfigs sharedConfig] timeDelayToUploadAlog];
        NSTimeInterval endTime = now + delay;
        NSTimeInterval startTime = endTime - range;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) , ^{
            [self reportWithStartTime:startTime endTime:endTime];
        });
    } else {
        NSTimeInterval endTime = now;
        NSTimeInterval startTime = endTime - range;
        [self reportWithStartTime:startTime endTime:endTime];
    }
}

+ (void)reportWithStartTime:(NSTimeInterval)startTime
                    endTime:(NSTimeInterval)endTime {
    [PNS_GET_INSTANCE(PNSLogUploaderProtocol) reportALogWithStartTime:startTime endTime:endTime];
    [self logWithTag:@"PrivacyCommonInfo" message:@"upload alog success"];
}

@end
