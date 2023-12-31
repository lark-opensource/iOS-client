//
//  HeimdallrModule.h
//  Heimdallr
//
//  Created by 刘诗彬 on 2018/1/10.
//

#import <Foundation/Foundation.h>
#import "HMDModuleConfig.h"
#import "HMDCleanupConfig.h"

#define SHARED(x) + (instancetype)shared\
{\
static x *shared = nil;\
static dispatch_once_t onceToken;\
dispatch_once(&onceToken, ^{\
shared = [[x alloc] init];\
});\
return shared;\
}\

@class Heimdallr;
@protocol HMDRecordStoreObject;
@class HMDReportLimitSizeTool;

@protocol HeimdallrModule <NSObject>
@required

@property (nonatomic, weak, readonly, nullable) Heimdallr *heimdallr;
@property (atomic, strong, readonly, nullable)HMDModuleConfig *config;
@property (atomic, assign, readonly) BOOL isRunning;
@property (atomic, assign, readonly) BOOL hasExecutedTaskIndependentOfStart;

- (NSString * _Nullable)moduleName;
- (void)setupWithHeimdallr:(Heimdallr * _Nullable)heimdallr;

- (void)start;
- (void)stop;
- (void)runTaskIndependentOfStart;//启动任务，不管模块是否启动都执行

- (Class<HMDRecordStoreObject> _Nullable)storeClass;
- (void)cleanupWithConfig:(HMDCleanupConfig * _Nullable)cleanConfig;
- (void)updateConfig:(HMDModuleConfig * _Nullable)config;

@optional


- (BOOL)needSyncStart;//启动时是否应该立即开启
//本地默认初始化额外操作，方便配置全量的上报采样率等，一般只有在新用户首次启动时会被调用
- (void)prepareForDefaultStart;

- (BOOL)performanceDataSource;
- (BOOL)exceptionDataSource;
@end


@interface HeimdallrModule : NSObject<HeimdallrModule>

@property (nonatomic, weak, readonly, nullable) Heimdallr *heimdallr;
@property (atomic, strong, readonly, nullable) HMDModuleConfig *config;
@property (atomic, assign, readonly) BOOL isRunning;
@property (atomic, assign, readonly) BOOL hasExecutedTaskIndependentOfStart;
@property (nonatomic, weak, readonly, nullable) HMDReportLimitSizeTool *sizeLimitTool;

- (NSString * _Nullable)moduleName;

- (void)setupWithHeimdallr:(Heimdallr * _Nullable)heimdallr NS_REQUIRES_SUPER;
- (void)setupWithHeimdallrReportSizeLimit:(HMDReportLimitSizeTool * _Nullable)sizeLimitTool NS_REQUIRES_SUPER;
- (void)setupWithHeimdallrReportSizeLimimt:(HMDReportLimitSizeTool * _Nullable)sizeLimitTool __attribute__((deprecated("please use setupWithHeimdallrReportSizeLimit")));

- (void)start NS_REQUIRES_SUPER;
- (void)stop NS_REQUIRES_SUPER;
- (void)runTaskIndependentOfStart NS_REQUIRES_SUPER;

- (Class<HMDRecordStoreObject> _Nullable)storeClass;
- (void)cleanupWithConfig:(HMDCleanupConfig * _Nullable)cleanConfig;
- (void)updateConfig:(HMDModuleConfig * _Nullable)config NS_REQUIRES_SUPER;
@end
