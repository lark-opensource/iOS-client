//
//  HMDExceptionReporter.m
//  Heimdallr
//
//  Created by joy on 2018/3/26.
//

#import "HMDExceptionReporter.h"
#import "HMDHeimdallrConfig.h"
#import "HMDGeneralAPISettings.h"
#import "NSArray+HMDSafe.h"
#import "NSDictionary+HMDSafe.h"
#import "HMDNetworkReqModel.h"
#import "HMDMacroManager.h"

NSString *const kHMDExceptionReporterServerCheckerKey = @"kHMDExceptionNextAviaibleTimeIntervalKey";

@interface HMDExceptionReporter()

@property (nonatomic, strong) NSMutableDictionary *reporterMap;
@property (nonatomic, strong) NSLock *reporterMapLock;

@end

@implementation HMDExceptionReporter

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    static HMDExceptionReporter *share = nil;
    dispatch_once(&onceToken, ^{
        share = [HMDExceptionReporter new];
    });
    return share;
}

- (instancetype)init {
    if (self = [super init]) {
        self.reporterMapLock = [[NSLock alloc] init];
    }

    return self;
}

- (HMDExceptionModuleReporter *)reporterWithExceptionType:(HMDExceptionType)exceptionType
{
    return [self reporterWithExceptionType:exceptionType createIfNeed:NO];
}

- (HMDExceptionModuleReporter *)reporterWithExceptionType:(HMDExceptionType)exceptionType
                                             createIfNeed:(BOOL)createIfNeed
{
    if (exceptionType >= HMDExceptionTypeCount) {
        return nil;
    }
    [self.reporterMapLock lock];
    HMDExceptionModuleReporter *reporter = [self.reporterMap hmd_objectForKey:@(exceptionType) class:HMDExceptionModuleReporter.class];
    if (createIfNeed && !reporter) {
        if (!self.reporterMap) {
            self.reporterMap = [NSMutableDictionary dictionary];
        }
        reporter = [HMDExceptionModuleReporter reporterWithExceptionType:exceptionType];
        [self.reporterMap hmd_setObject:reporter forKey:@(exceptionType)];
    }
    [self.reporterMapLock unlock];
    return reporter;
}

- (HMDExceptionModuleReporter *)reporterWithModule:(id<HMDExceptionReporterDataProvider>)module
{
    return [self reporterWithModule:module createIfNeed:NO];
}

- (HMDExceptionModuleReporter *)reporterWithModule:(id<HMDExceptionReporterDataProvider>)module
                                      createIfNeed:(BOOL)createIfNeed
{
    HMDExceptionType type = HMDDefaultExceptionType;
    if ([module respondsToSelector:@selector(exceptionType)]) {
        type = [module exceptionType];
    }
    HMDExceptionModuleReporter *reporter = [self reporterWithExceptionType:type createIfNeed:createIfNeed];
    return reporter;
}

- (NSArray *)allReporters
{
    NSArray *result = nil;
    [self.reporterMapLock lock];
    result = self.reporterMap.allValues;
    [self.reporterMapLock unlock];
    return result;
}

- (void)enumerateAllReportersUsingBlock:(void(^)(HMDExceptionModuleReporter *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop))block {
    NSArray *reporters = [self allReporters];
    [reporters hmd_enumerateObjectsUsingBlock:block class:HMDExceptionModuleReporter.class];
}

- (void)addReportModule:(id<HMDExceptionReporterDataProvider>)module
{
    HMDExceptionModuleReporter *reporter = [self reporterWithModule:module createIfNeed:YES];
    [reporter addReportModule:module];
}

- (void)removeReportModule:(id<HMDExceptionReporterDataProvider>)module
{
    HMDExceptionModuleReporter *reporter = [self reporterWithModule:module];
    [reporter removeReportModule:module];
}

- (void)reportAllExceptionData
{
    [self enumerateAllReportersUsingBlock:^(HMDExceptionModuleReporter * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        @autoreleasepool {
            [obj reportExceptionData];
        }
    }];
}

- (void)reportExceptionDataWithExceptionTypes:(NSArray *)exceptionTypes
{
    [exceptionTypes hmd_enumerateObjectsUsingBlock:^(NSNumber *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        @autoreleasepool {
            HMDExceptionType type = obj.unsignedIntegerValue;
            HMDExceptionModuleReporter *reporter = [self reporterWithExceptionType:type];
            [reporter reportExceptionData];
        }
    } class:NSNumber.class];
}

- (NSArray *)allDebugRealExceptionDataWithConfig:(HMDDebugRealConfig *)config
{
    NSMutableArray *result = [NSMutableArray array];
    [self enumerateAllReportersUsingBlock:^(HMDExceptionModuleReporter * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        @autoreleasepool {
            NSArray *datas = [obj debugRealExceptionDataWithConfig:config];
            [result hmd_addObjects:datas];
        }
    }];
    return result;
}

- (NSArray *)debugRealExceptionDataWithConfig:(HMDDebugRealConfig *)config
                               exceptionTypes:(NSArray *)exceptionTypes
{
    NSMutableArray *result = [NSMutableArray array];
    [exceptionTypes hmd_enumerateObjectsUsingBlock:^(NSNumber *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        @autoreleasepool {
            HMDExceptionType type = obj.unsignedIntegerValue;
            HMDExceptionModuleReporter *reporter = [self reporterWithExceptionType:type];
            NSArray *datas = [reporter debugRealExceptionDataWithConfig:config];
            [result hmd_addObjects:datas];
        }
    } class:NSNumber.class];
    return result;
}

- (void)reportAllDebugRealExceptionData:(HMDDebugRealConfig *)config {
    [self enumerateAllReportersUsingBlock:^(HMDExceptionModuleReporter * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        @autoreleasepool {
            [obj reportDebugRealExceptionData:config];
        }
    }];
}

- (void)reportDebugRealExceptionData:(HMDDebugRealConfig *)config
                      exceptionTypes:(NSArray *)exceptionTypes
{
    [exceptionTypes hmd_enumerateObjectsUsingBlock:^(NSNumber *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        @autoreleasepool {
            HMDExceptionType type = obj.unsignedIntegerValue;
            HMDExceptionModuleReporter *reporter = [self reporterWithExceptionType:type];
            [reporter reportDebugRealExceptionData:config];
        }
    } class:NSNumber.class];
}

- (void)cleanupExceptionDataWithConfig:(HMDDebugRealConfig *)config
{
    [self enumerateAllReportersUsingBlock:^(HMDExceptionModuleReporter * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        @autoreleasepool {
           [obj cleanupExceptionDataWithConfig:config];
        }
    }];
}

- (void)updateConfig:(HMDHeimdallrConfig *)config
{
    BOOL needEncrypt = NO;
    if (config.apiSettings.exceptionUploadSetting) {
        needEncrypt = config.apiSettings.exceptionUploadSetting.enableEncrypt;
    } else if (config.apiSettings.allAPISetting){
        needEncrypt = config.apiSettings.allAPISetting.enableEncrypt;
    }
#if RANGERSAPM
    needEncrypt = !HMD_IS_DEBUG;
#endif
    
    [self enumerateAllReportersUsingBlock:^(HMDExceptionModuleReporter * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.needEncrypt = needEncrypt;
    }];
}

@end
