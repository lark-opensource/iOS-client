//
//  EMANetworkMonitor.m
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/9/20.
//

#import "EMANetworkMonitor.h"
#import <objc/runtime.h>
#import <ECOInfra/BDPUtils.h>
#import <ECOInfra/BDPLog.h>
#import <ECOInfra/ECOInfra-Swift.h>
#import <ECOInfra/ECONetworkGlobalConst.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>

@interface EMANetworkMonitor()

@end

@implementation EMANetworkMonitor

+ (instancetype)shared {
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

+ (NSDictionary *)getRustMetricsForTask:(NSURLSessionTask *)task {
    NSMutableDictionary *metricInfo = [NSMutableDictionary dictionary];
    HttpMetrics *rustMetric = [SwiftBridge metricsForTaskWithTask:task].lastObject;
    if (rustMetric) {
        metricInfo[@"dns"] = @((NSInteger)(rustMetric.dnsCost * 1000));
        metricInfo[@"connection"] = @((NSInteger)(rustMetric.connectionCost * 1000));
        metricInfo[@"ssl"] = @((NSInteger)(rustMetric.tlsCost * 1000));
        if (rustMetric.fetchStartDate && rustMetric.receiveHeaderDate) {
            // 如果没有对应的值，则不上报该key，不要默认补0
            metricInfo[@"ttfb"] = @([rustMetric.receiveHeaderDate timeIntervalSinceDate:rustMetric.fetchStartDate] * 1000);
        }
    }
    return metricInfo;
}

- (void)logCookiesForTask:(NSURLSessionTask *)task {
    // 记录请求头中的cookies key
    NSURLRequest *request = task.currentRequest;
    NSDictionary<NSString *,NSString *> *headers = request.allHTTPHeaderFields;
    headers = [headers bdp_dictionaryWithLowercaseKeys];
    NSString *cookies = [headers bdp_stringValueForKey:@"cookie"];
    NSArray<NSString *> *cookieKV = [cookies componentsSeparatedByString:@";"];
    NSMutableArray<NSString *> *cookieKeys = [NSMutableArray array];
    [cookieKV enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
         NSArray<NSString *> *objKV = [[obj stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] componentsSeparatedByString:@"="];
        NSString *cookieKey = objKV.firstObject;
        if (!BDPIsEmptyString(cookieKey)) {
            [cookieKeys addObject:cookieKey];
        }
    }];
    NSString *urlString = request.URL.absoluteString;
    BDPLogInfo(@"request header %@", BDPParamStr(urlString, cookieKeys));

    /** 记录响应头中的cookies key, domain, path
    "Set-Cookie" =     (
                        "lobsession_185=lobster-cbf095-219c070e-f039-40a9-9a0f-63eb4262bebb-pzgxg8; Path=/; Max-Age=604800, lobsession_185=; Path=/; Domain=feishu.cn; Expires=Wed, 17 Oct 2018 13:00:08 GMT; Max-Age=0"
                        );
    */
    if (![task.response isKindOfClass:[NSHTTPURLResponse class]]) {
        return;
    }
    NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
    NSArray<NSHTTPCookie *> *setCookieKV = [NSHTTPCookie cookiesWithResponseHeaderFields:response.allHeaderFields forURL:request.URL];
    NSMutableArray<NSString *> *setCookieKeys = [NSMutableArray array];
    [setCookieKV enumerateObjectsUsingBlock:^(NSHTTPCookie * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *cookieKey = [NSString stringWithFormat:@"name: %@, domain: %@, path: %@", obj.name, obj.domain, obj.path];
        [setCookieKeys addObject:cookieKey];
    }];
    BDPLogInfo(@"reponse header %@", BDPParamStr(urlString, setCookieKeys));
}

#pragma mark - NSURLSession 网络质量监控
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didFinishCollectingMetrics:(NSURLSessionTaskMetrics *)metrics {
    if(![ECONetworkDependency networkMonitorEnable]) {
        return;
    }
    // 该事件之后便会调用结束事件并改变任务状态，这里延迟一点来获取状态
    __weak typeof(self) wself = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (task.state == NSURLSessionTaskStateCanceling || task.state == NSURLSessionTaskStateCompleted) {
            __strong typeof(wself) self = wself;
            if (!self) {
                return;
            }
            [self logCookiesForTask:task];
        } else {
            BDPLogDebug(@"task state not ready %@", task.originalRequest.URL);
        }
    });
}

@end
