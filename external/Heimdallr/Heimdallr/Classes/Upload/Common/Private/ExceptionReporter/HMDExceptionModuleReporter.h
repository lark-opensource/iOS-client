//
//  HMDExceptionModuleReporter.h
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/6/10.
//

#import <Foundation/Foundation.h>
#import "HMDExceptionReporterDataProvider.h"
// PrivateServices
#import "HMDServerStateDefinition.h"
#import "HMDURLProvider.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDExceptionModuleReporter : NSObject

@property (nonatomic,assign) BOOL needEncrypt;

@property (nonatomic, assign) HMDReporter reporterType;

+ (instancetype)reporterWithExceptionType:(HMDExceptionType)exceptionType;

- (void)addReportModule:(id<HMDExceptionReporterDataProvider>)module;

- (void)removeReportModule:(id<HMDExceptionReporterDataProvider>)module;

- (void)reportExceptionData;

- (NSArray *)debugRealExceptionDataWithConfig:(HMDDebugRealConfig *)config;

- (void)reportDebugRealExceptionData:(HMDDebugRealConfig *)config;

- (void)cleanupExceptionDataWithConfig:(HMDDebugRealConfig *)config;

// 子类需要重写该方法
- (id<HMDURLProvider> _Nullable)moduleURLProvier;

@end

NS_ASSUME_NONNULL_END
