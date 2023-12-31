//
//  BDHybridCoreReporter.m
//  IESWebViewMonitor
//
//  Created by bytedance on 2020/9/14.
//

#import "BDHybridCoreReporter.h"
#import <Heimdallr/HMDTTMonitor.h>
#import <BDAlogProtocol/BDAlogProtocol.h>
#import "BDMonitorThreadManager.h"

#define BDHybridMonitorTag @"BDHybridMonitor"
#define BDHybridMonitor_InfoLog(format, ...)  BDALOG_PROTOCOL_INFO_TAG(BDHybridMonitorTag, format, ##__VA_ARGS__)

NSString * const kBDMonitorReportNativeBase = @"nativeBase";
NSString * const kBDMonitorReportClientParams = @"nativeInfo";
NSString * const kBDMonitorReportURL = @"url";

@interface BDHybridCoreReporterFilter : NSObject

@property (nonatomic, strong) NSString *aid;
@property (nonatomic, strong) NSArray<NSString *> *serviceList;
@property (nonatomic, assign) BOOL clearAllServiceWithAid;

@end

@implementation BDHybridCoreReporterFilter

- (BOOL)canFilterWithDic:(NSDictionary *)dic forService:(NSString *)service {
    if (!dic || ![dic isKindOfClass:NSDictionary.class] || service.length<=0) {
        return NO;
    }
    if (self.aid.length <= 0) {
        return NO;
    }
    
    BOOL aimedAid = [self isAimedAid:dic];
    if (!aimedAid) {
        return NO;
    } else {
        if (self.clearAllServiceWithAid) {
            return YES;
        } else {
            BOOL aimedService = [self isAimedService:service];
            return aimedService;
        }
    }
    
    return YES;
}

- (BOOL)isAimedAid:(NSDictionary *)dic {
    NSString *vAid = dic[@"virtual_aid"];
    if (vAid.length <= 0) {
        NSDictionary *nativeBase = dic[@"nativeBase"];
        if (nativeBase && [nativeBase isKindOfClass:NSDictionary.class]) {
            vAid = nativeBase[@"virtual_aid"];
        }
    }
    
    if (vAid.length > 0 && [vAid isEqualToString:self.aid]) {
        return YES;
    } else if (vAid.length <= 0 && [self.aid isEqualToString:@"default"]) {
        return YES;
    } else {
        return NO;
    }
     
    return NO;
}

- (BOOL)isAimedService:(NSString *)service {
    if (service.length<=0) {
        return NO;
    }
    for (NSString *serviceItem in self.serviceList) {
        if ([service isEqualToString:serviceItem]) {
            return YES;
        }
    }
    return NO;
}

@end

@interface BDHybridCoreReporter()

@property (nonatomic, strong) NSMutableArray<BDMonitorReportBlock> *reportBlockList;
@property (nonatomic, strong) NSMutableArray<BDHybridCoreReporterFilter *> *filterList;

@property (nonatomic, assign) BOOL kHMDReportSwitch;

@end

@implementation BDHybridCoreReporter

+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    static BDHybridCoreReporter *instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[BDHybridCoreReporter alloc] init];
        instance.filterList = [[NSMutableArray alloc] init];
        instance.kHMDReportSwitch = YES;
    });
    return instance;
}

-(BOOL)shouldReport:(NSDictionary *)record {
    if ([record isKindOfClass:[NSDictionary class]]) {
        NSString *url = nil;
        NSDictionary *nativeBase = record[kBDMonitorReportNativeBase];
        if ([nativeBase isKindOfClass:[NSDictionary class]]) {
            url = nativeBase[kBDMonitorReportURL];
        }
        if (!url.length
            && [record[kBDMonitorReportClientParams] isKindOfClass:[NSDictionary class]]) {
            url = record[kBDMonitorReportClientParams][kBDMonitorReportURL];
        }
        if (url && ![url containsString:@"waitfix"]) {
            return YES;
        }
    }
    return NO;
}

#pragma mark - public

- (void)addGlobalReportBlock:(BDMonitorReportBlock)reportBlock {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        self.reportBlockList = [NSMutableArray array];
    });
    [self.reportBlockList addObject:[reportBlock copy]];
}

- (void)filterReportWithAid:(NSString *)aid serviceList:(NSArray *)serviceList {
    [BDMonitorThreadManager dispatchAsyncHandlerForceOnMonitorThread:^{
        BDHybridCoreReporterFilter *filter = [[BDHybridCoreReporterFilter alloc] init];
        filter.aid = aid;
        filter.serviceList = serviceList;
        [self.filterList addObject:filter];
    }];
}

- (void)filterReportWithAid:(NSString *)aid {
    [BDMonitorThreadManager dispatchAsyncHandlerForceOnMonitorThread:^{
        BDHybridCoreReporterFilter *filter = [[BDHybridCoreReporterFilter alloc] init];
        filter.aid = aid;
        filter.clearAllServiceWithAid = YES;
        [self.filterList addObject:filter];
    }];
}

// 过滤所有上报
- (void)filterAllReport {
    [self filterReportWithAid:@"default"];
}

- (void)setHMDReportSwitch:(BOOL)isOn {
    self.kHMDReportSwitch = isOn;
}

- (NSArray *)alogFilterList {
    return @[
        @"jsbPerf"
        , @"monitor_custom_service"
        , @"monitor_custom_sample_service"
    ];
}

- (BOOL)isFilterForService:(NSString *)service {
    NSArray *filterList = [self alogFilterList];
    for (NSString *filterItem in filterList) {
        if ([service containsString:filterItem]) {
            return YES;
        }
    }
    return NO;
}

// report single dic item
- (void)reportSingleDic:(NSDictionary *)dic forService:(NSString *)service {
    if (![dic isKindOfClass:[NSDictionary class]]) {
        return;
    }
    NSDictionary *dicCpy = [dic copy];
    if ([service hasSuffix:@"_hybrid_monitor_custom_service"]
        || [service hasSuffix:@"_hybrid_monitor_custom_sample_service"]
        || [self shouldReport:dicCpy]) {
        if (self.reportBlockList.count > 0) {
            for (BDMonitorReportBlock block in self.reportBlockList) {
                block(service,dicCpy);
            }
        }
        if (self.kHMDReportSwitch) {
            BOOL canReport = YES;
            if (self.filterList.count > 0) {
                for (BDHybridCoreReporterFilter *filter in self.filterList) {
                    if ([filter canFilterWithDic:dicCpy forService:service]) {
                        canReport = NO;
                        break;
                    }
                }
            }
            
            if (canReport) {
                [[HMDTTMonitor defaultManager] hmdTrackService:service
                                                        metric:nil
                                                      category:nil
                                                         extra:dicCpy];
            }
            
            if (![self isFilterForService:service]) {
                BDHybridMonitor_InfoLog(@"service:%@",service?:@"");
            }
        }
    }
}


@end
