//
//  CJPayHybridPerformanceMonitor.m
//  Pods
//
//  Created by wangxinhua on 2022/10/17.
//

#import "CJPayHybridPerformanceMonitor.h"
#import "CJPaySDKMacro.h"

@implementation CJPayHybridPerformanceModel

- (long)hybridContainerPrepareTime {
    return @((self.pageStartedTime - self.callAPITime) * 1000).longValue;
}

- (long)hybridContainerCreatedFinishedTime {
    return @((self.createFinishdedTime - self.callAPITime) * 1000).longValue;
}

- (long)hybridStartURLLoadTime {
    return @((self.startLoadURLTime - self.callAPITime) * 1000).longValue;
}

- (long)hybridPageStartedTime {
    return @((self.pageStartedTime - self.callAPITime) * 1000).longValue;
}

- (long)hybridPageLoadFinishedTime {
    return @((self.pageLoadFinishedTime - self.callAPITime) * 1000).longValue;
}

@end

@interface CJPayHybridPerformanceMonitor()

@property (nonatomic, copy) NSString *urlStr;
@property (nonatomic, strong) CJPayHybridPerformanceModel *performanceModel;

@end

@implementation CJPayHybridPerformanceMonitor

- (instancetype)initWith:(NSString *)urlStr {
    return [self initWith:urlStr callAPITime:0];
}

- (instancetype)initWith:(NSString *)urlStr callAPITime:(NSTimeInterval)callAPITime {
    self = [super init];
    if (self) {
        self.urlStr = urlStr;
        self.performanceModel = [CJPayHybridPerformanceModel new];
        self.performanceModel.callAPITime = callAPITime;
    }
    return self;
}

- (void)trackPerformanceStage:(CJPayHybridPerformanceStage)stage defaultTimeStamp:(NSTimeInterval)timeStamp {
    CJPayLogInfo(@"webview_monitor: stage: %ld, timestamp: %f, url: %@", (long)stage, timeStamp, self.urlStr);
    switch (stage) {
        case CJPayHybridPerformanceStageCallAPI:
            self.performanceModel.callAPITime = timeStamp < 1 ? CFAbsoluteTimeGetCurrent() : timeStamp;
            break;
        case CJPayHybridPerformanceStageInitFinished:
            self.performanceModel.createFinishdedTime = timeStamp < 1 ? CFAbsoluteTimeGetCurrent() : timeStamp;
            break;
        case CJPayHybridPerformanceStageStartLoadURL:
            self.performanceModel.startLoadURLTime = timeStamp < 1 ? CFAbsoluteTimeGetCurrent() : timeStamp;
            break;
        case CJPayHybridPerformanceStagePageStarted:{
            BOOL isFirstPageStartedTime = self.performanceModel.pageStartedTime < 1;
            if (isFirstPageStartedTime) {
                self.performanceModel.pageStartedTime = timeStamp < 1 ? CFAbsoluteTimeGetCurrent() : timeStamp;
            }
        }
            break;
        case CJPayHybridPerformanceStagePageFinished:{
            BOOL isFirstFinished = self.performanceModel.pageLoadFinishedTime < 1;
            if (isFirstFinished) {
                self.performanceModel.pageLoadFinishedTime = timeStamp < 1 ? CFAbsoluteTimeGetCurrent() : timeStamp;
                [self p_uploadPerformaceFirstPageStartedLog];
            }
        }
            break;
            
        default:
            break;
    }
}

- (void)p_uploadPerformaceFirstPageStartedLog {
    static BOOL isFirstInitWeb = YES; // 近似计算，拿第一个webview初始化时间
    
    NSMutableDictionary *mutableDic = [NSMutableDictionary new];
    [mutableDic cj_setObject:@([self.performanceModel hybridContainerPrepareTime]) forKey:@"init_time"];
    [mutableDic cj_setObject:@([self.performanceModel hybridContainerCreatedFinishedTime]) forKey:@"on_create_time"];
    [mutableDic cj_setObject:@([self.performanceModel hybridStartURLLoadTime]) forKey:@"load_url_time"];
    [mutableDic cj_setObject:@([self.performanceModel hybridPageStartedTime]) forKey:@"on_page_started_time"];
    [mutableDic cj_setObject:@([self.performanceModel hybridPageLoadFinishedTime]) forKey:@"on_page_finished_time"];
    
    if (Check_ValidString(self.urlStr)) {
        NSURL *url = [NSURL URLWithString:[self.urlStr cj_safeURLString]];
        [mutableDic cj_setObject:url.host forKey:@"host"];
        [mutableDic cj_setObject:url.path forKey:@"path"];
    }
    
    [mutableDic cj_setObject:CJString(self.kernelTypeStr) forKey:@"kernel_type"];
    [mutableDic cj_setObject:@(isFirstInitWeb) forKey:@"is_first"];
    isFirstInitWeb = NO;
    
    [CJTracker event:@"wallet_rd_h5_init_time" params:[mutableDic copy]];
}

@end
