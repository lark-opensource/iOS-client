//
//  BDPRequestMetric.m
//  Timor
//
//  Created by 傅翔 on 2019/7/15.
//

#import "BDPRequestMetrics.h"
#import "BDPRequestMetrics+Private.h"

@implementation BDPRequestMetrics

+ (instancetype)metricsFromTransactionMetrics:(NSURLSessionTaskTransactionMetrics *)metrics {
    if (!metrics) {
        return nil;
    }
    BDPRequestMetrics *bdpMetrics = [[BDPRequestMetrics alloc] init];
    [bdpMetrics updateWithMetrics:metrics];
    return bdpMetrics;
}

- (void)updateWithMetrics:(NSURLSessionTaskTransactionMetrics *)metrics {
    self.dns = MAX(([metrics.domainLookupEndDate timeIntervalSince1970] - [metrics.domainLookupStartDate timeIntervalSince1970]) * 1000, 0);
    self.tcp = MAX(([metrics.secureConnectionStartDate timeIntervalSince1970] - [metrics.connectStartDate timeIntervalSince1970]) * 1000, 0);
    self.ssl = MAX(([metrics.secureConnectionEndDate timeIntervalSince1970] - [metrics.secureConnectionStartDate timeIntervalSince1970]) * 1000, 0);
    self.send = MAX(([metrics.requestEndDate timeIntervalSince1970] - [metrics.requestStartDate timeIntervalSince1970]) * 1000, 0);
    self.wait = MAX(([metrics.responseStartDate timeIntervalSince1970] - [metrics.requestEndDate timeIntervalSince1970]) * 1000, 0);
    self.reuseConnect = metrics.isReusedConnection;
    self.receive = MAX(([metrics.responseEndDate timeIntervalSince1970] - [metrics.responseStartDate timeIntervalSince1970]) * 1000, 0);
    self.requestTime = MAX((metrics.responseEndDate.timeIntervalSince1970 - metrics.requestStartDate.timeIntervalSince1970) * 1000, 0);
}

@end
