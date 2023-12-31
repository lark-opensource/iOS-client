//
//  TTVideoEngine+Tracker.m
//  TTVideoEngine
//
//  Created by haocheng on 2021/1/11.
//

#import "TTVideoEngine+Tracker.h"

@implementation TTVideoEngine (Tracker)

+ (Class<TTVideoEngineReporterProtocol>)reportHelperClass {
    static Class MediaClass;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (MediaClass == nil) {
            MediaClass = NSClassFromString(@"TTVideoEngineReportHelper");
        }
    });
    return MediaClass;
}

+ (void)setAutoTraceReportOpen:(BOOL)isOpen {
    id<TTVideoEngineReporterProtocol> reportManager = [[TTVideoEngine reportHelperClass] sharedManager];
    if (reportManager) {
        reportManager.enableAutoReportLog = isOpen;
    }
}

@end
