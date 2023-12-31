//
//  HMDExceptionReporter.h
//  Heimdallr
//
//  Created by joy on 2018/3/26.
//

#import <Foundation/Foundation.h>
#import "HMDExceptionModuleReporter.h"
@class HMDHeimdallrConfig;
@interface HMDExceptionReporter : NSObject
+ (instancetype)sharedInstance;

- (void)addReportModule:(id<HMDExceptionReporterDataProvider>)module;
- (void)removeReportModule:(id<HMDExceptionReporterDataProvider>)module;

- (void)reportAllExceptionData;
- (void)reportExceptionDataWithExceptionTypes:(NSArray *)exceptionTypes;

- (NSArray *)allDebugRealExceptionDataWithConfig:(HMDDebugRealConfig *)config;
- (NSArray *)debugRealExceptionDataWithConfig:(HMDDebugRealConfig *)config
                               exceptionTypes:(NSArray *)exceptionTypes;

- (void)reportAllDebugRealExceptionData:(HMDDebugRealConfig *)config;
- (void)reportDebugRealExceptionData:(HMDDebugRealConfig *)config
                      exceptionTypes:(NSArray *)exceptionTypes;

- (void)cleanupExceptionDataWithConfig:(HMDDebugRealConfig *)config;
- (void)updateConfig:(HMDHeimdallrConfig *)config;

@end
