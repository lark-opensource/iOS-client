//
//  HeimdallrModule.m
//  Pods
//
//  Created by 谢俊逸 on 2019/1/17.
//

#import "HeimdallrModule.h"
#import "Heimdallr.h"
#import "Heimdallr+Private.h"
#import "Heimdallr+Cleanup.h"
#import "HMDRecordStore.h"
#import "HMDRecordStoreObject.h"
#import "HMDMacro.h"
#import "HMDStoreIMP.h"
#import "HMDALogProtocol.h"
#import "NSObject+HMDAttributes.h"

@interface HeimdallrModule ()
@property (atomic, assign, readwrite) BOOL isRunning;
@property (atomic, strong, readwrite) HMDModuleConfig *config;
@property (atomic, assign, readwrite) BOOL hasExecutedTaskIndependentOfStart;
@end

@implementation HeimdallrModule

- (instancetype)init {
    if (self = [super init]) {
        _isRunning = NO;
    }
    return self;
}

- (void)setupWithHeimdallr:(Heimdallr *)heimdallr {
    _heimdallr = heimdallr;
}

- (void)setupWithHeimdallrReportSizeLimit:(HMDReportLimitSizeTool * _Nullable)sizeLimitTool {
    _sizeLimitTool = sizeLimitTool;
}

- (void)setupWithHeimdallrReportSizeLimimt:(HMDReportLimitSizeTool * _Nullable)sizeLimitTool {
    [self setupWithHeimdallrReportSizeLimit:sizeLimitTool];
}

- (void)start {
    NSAssert(!self.isRunning, @"Unsynchronized access will cause online CRASH.");
    self.isRunning = YES;
    HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"%@ module start", [self moduleName]);
}

- (void)runTaskIndependentOfStart {
    NSAssert(!self.hasExecutedTaskIndependentOfStart, @"Unsynchronized access will cause online CRASH.");
    self.hasExecutedTaskIndependentOfStart = YES;
}

- (void)stop {
    NSAssert(self.isRunning, @"Unsynchronized access will cause online CRASH.");
    self.isRunning = NO;
    HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"%@ module stop", [self moduleName]);
}

- (Class<HMDRecordStoreObject>)storeClass {
    return nil;
}

- (void)cleanupWithConfig:(HMDCleanupConfig *)cleanConfig {
}

- (NSString *)moduleName {
    return [[self.config class] configKey];
}

- (void)updateConfig:(HMDModuleConfig *)config {
    self.config = config;
    HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"%@ module updateConfig %@", [self moduleName], [config hmd_dataDictionary]);
}

@end
