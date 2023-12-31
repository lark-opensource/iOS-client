//
//  Heimdallr+RoleStateChange.m
//  Heimdallr
//
//  Created by zhouyang11 on 2023/8/24.
//

#import "Heimdallr+RoleStateChange.h"
#import "HMDExceptionReporter.h"
#import "HMDExceptionReporterDataProvider.h"
#import "Heimdallr+Private.h"
#import "HeimdallrModule.h"
#import "HMDDynamicCall.h"
#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP

@implementation Heimdallr (RoleStateChange)

- (void)roleStateChangeAndCleanData {
    if (!self.initializationCompleted) {
        return;
    }
    
    dispatch_on_heimdallr_queue(true, ^{
        [self cleanUserExceptionCache];
        /*
        [self triggerExceptionUpload];
        id<HeimdallrModule> crashTracker = [self moduleWithName:@"crash"];
        DC_OB(crashTracker, uploadCrashLogImmediately:, nil);
         */
    });
     
}

- (void)triggerExceptionUpload {
    [[HMDExceptionReporter sharedInstance] reportExceptionDataWithExceptionTypes:@[@(HMDDefaultExceptionType),
                                                                                   @(HMDCPUExceptionType),
                                                                                   @(HMDCaptureBacktraceExceptionType),
                                                                                   @(HMDMetricKitExceptionType),
                                                                                   @(HMDUIFrozenExceptionType),
                                                                                   @(HMDFDExceptionType)]];
    
    [[HMEngine sharedEngine] triggerFlushAndUploadManuallyWithModuleId:@"collect"];
}

- (void)cleanUserExceptionCache {

    id<HeimdallrModule> userExceptionModule = [self moduleWithName:@"user_exception"];
    if ([userExceptionModule conformsToProtocol:@protocol(HMDExceptionReporterDataProvider)] && [userExceptionModule respondsToSelector:@selector(dropExceptionDataIgnoreHermas)]) {
        [(id<HMDExceptionReporterDataProvider>)userExceptionModule dropExceptionDataIgnoreHermas];
    }
    
    [[HMEngine sharedEngine] cleanAllCacheManuallyWithModuleId:@"ios_custom_exception"];
}

@end
