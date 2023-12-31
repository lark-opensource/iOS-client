//
//	HMDDefaultURLSettings.m
// 	Heimdallr
// 	
// 	Created by Hayden on 2020/4/29. 
//

#import "HMDURLSettings.h"
#import "HMDURLSettingsProtocol.h"

NSString * const _Nonnull HMDCrashUploadURLDefaultPath =
    @"/service/2/app_log_exception/";

@implementation HMDURLSettings

#pragma mark - Hosts

+ (NSArray<NSString *> *)defaultHosts {
    NSArray<NSString *> *hosts = nil;
    Class cls = [self _URLHostSettingsClass];
    if ([cls respondsToSelector:@selector(defaultHosts)]) {
        hosts = [cls defaultHosts];
    }
    return hosts;
}

+ (NSArray<NSString *> *)configFetchDefaultHosts {
    NSArray<NSString *> *hosts = nil;
    Class cls = [self _URLHostSettingsClass];
    if ([cls respondsToSelector:@selector(configFetchDefaultHosts)]) {
        hosts = [cls configFetchDefaultHosts];
    }
    return hosts;
}

+ (NSArray<NSString *> *)crashUploadDefaultHosts {
    return [self defaultHosts];
}

+ (NSArray<NSString *> *)exceptionUploadDefaultHosts {
    return [self defaultHosts];
}

+ (NSArray<NSString *> *)userExceptionUploadDefaultHosts {
    return [self defaultHosts];
}

+ (NSArray<NSString *> *)performanceUploadDefaultHosts {
    return [self defaultHosts];
}

+ (NSArray<NSString *> *)fileUploadDefaultHosts {
    return [self defaultHosts];
}

+ (NSArray<NSString *> *)customHostsForAppID:(NSString *)appID {
    return nil;
}

+ (void)registerCustomHosts:(NSArray<NSString *> *)hosts forAppID:(NSString *)appID {}

+ (void)registerCustomHost:(NSString *)host forAppID:(NSString *)appID {}

+ (Class<HMDURLHostSettings>)_URLHostSettingsClass {
    Class cls = NSClassFromString(@"HMDDomesticURLSettings");
    if (!cls) {
        cls = NSClassFromString(@"HMDOverseasURLSettings");
    }
#if DEBUG
    Class domesticCls = NSClassFromString(@"HMDDomesticURLSettings");
    Class overseasCls = NSClassFromString(@"HMDOverseasURLSettings");
    NSAssert(!(domesticCls && overseasCls), @"You cannot integrate both HMDDomestic and HMDOverseas subspecs，HMDDomestic is for Chinese product and HMDOverseas is for overseas product.");
    NSAssert(cls, @"You must integrate only one of subspecs between HMDDomestic and HMDOverseas，HMDDomestic is for Chinese product and HMDOverseas is for overseas product.");
#endif
    return cls;
}

#pragma mark - Paths

+ (NSString *)configFetchPath {
    return @"/monitor/appmonitor/v4/batch_settings";
}

+ (NSString *)crashUploadPath {
    return HMDCrashUploadURLDefaultPath;
}

+ (NSString *)crashEventUploadPath {
    return @"/monitor/collect/c/crash_client_event";
}

+ (NSString *)exceptionUploadPath {
    return @"/collect/";
}

+ (NSString *)exceptionUploadPathWithMultipleHeader {
    return @"/collect_with_multiple_header/";
}

+ (NSString *)userExceptionUploadPath {
    return @"/monitor/collect/c/ios_custom_exception/";
}

+ (NSString *)userExceptionUploadPathWithMultipleHeader {
    return @"/monitor/collect/c/ios_custom_exception_with_multiple_header/";
}

+ (NSString *)performanceUploadPath {
    return @"/monitor/collect/batch/";
}

+ (NSString *)highPriorityUploadPath {
    return @"/monitor/collect/batch/high_priority/";
}

+ (NSString *)fileUploadPath {
    return @"/monitor/collect/c/logcollect/";
}

+ (NSString *)memoryGraphUploadPath {
    return @"/monitor/collect/c/ios_memory_dump_file";
}

+ (NSString *)memoryGraphUploadCheckPath {
    return @"/monitor/collect/c/ios_memory_upload_check";
}

+ (NSString *)tracingUploadPath {
    return @"/monitor/collect/c/trace_collect";
}

+ (NSString *)tracingUploadPathWithMultipleHeader {
    return @"/monitor/collect/c/trace_collect_with_multiple_header";
}

+ (NSString *)evilMethodUploadPath {
    return @"/monitor/collect/c/ios_lag_drop_frame";
}

+ (NSString *)quotaStateCheckPath {
    return @"/monitor/collect/quota_status";
}

+ (NSString *)classCoverageUploadPath {
    return @"/monitor/collect/c/code_coverage";
}

+ (NSString *)cloudCommandUploadPath {
    return @"/monitor/collect/c/cloudcontrol/file/";
}

+ (NSString *)cloudCommandDownloadPath {
    return @"/monitor/collect/c/cloudcontrol/get";
}

+ (NSString *)memoryInfoUploadPath {
    return @"monitor/collect/c/memory_usage_trend_log";
}

+ (NSString *)sessionUploadPath {
    return nil;
}

+ (NSString *)registerServicePath {
    return nil;
}

@end
