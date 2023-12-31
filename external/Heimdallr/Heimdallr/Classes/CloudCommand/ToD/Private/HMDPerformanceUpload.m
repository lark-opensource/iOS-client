//
//  HMDPerformanceUpload.m
//  Pods
//
//  Created by fengyadong on 2018/8/23.
//

#import "HMDPerformanceUpload.h"
#import "HMDDebugRealConfig.h"
#import "HMDPerformanceReporterManager.h"
#import "HMDUploadHelper.h"
#import <AWECloudCommand/AWECloudCommandMacros.h>
#import "HMDNetworkReachability.h"
#import "HMDInjectedInfo.h"
#import "Heimdallr+Private.h"
#import "HMDGCD.h"


#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP

NSString *const kEnableCloudCommandPerformanceMonitor = @"performance_monitor";

@interface HMDPerformanceUpload()

@property (nonatomic, strong) HMDDebugRealConfig *debugRealConfig;
@property (nonatomic, strong) dispatch_queue_t operationQueue;

@end

@implementation HMDPerformanceUpload

AWE_REGISTER_CLOUD_COMMAND(@"slardar_performance");

/// 创建用于执行指令的实例变量
+ (instancetype)createInstance {
    return [[HMDPerformanceUpload alloc] init];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _operationQueue = dispatch_queue_create("com.heimdallr.cloudcommand.performanceupload", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

/// 执行自定义命令
- (void)__attribute__((annotate("oclint:suppress[block captured instance self]")))
excuteCommand:(AWECloudCommandModel *)model
completion:(AWECloudCommandResultCompletion)completion {
    if (hermas_enabled()) {
        // 重构后，走 Hermas 查询逻辑
        [self refactorExecuteCommand:model completion:completion];
    } else {
        [self oldExecuteCommand:model completion:completion];
    }
}


- (void)__attribute__((annotate("oclint:suppress[block captured instance self]")))
oldExecuteCommand:(AWECloudCommandModel *)model
completion:(AWECloudCommandResultCompletion)completion {
    AWECloudCommandResult *result = [[AWECloudCommandResult alloc] init];
    result.fileName = @"slardar_performance.json";
    result.commandId = model.commandId;
    result.operateTimestamp = [[NSDate date] timeIntervalSince1970];
    result.mimeType = @"application/json";
    result.fileType = @"log_performance";
    result.status = AWECloudCommandStatusInProgress;
    
    self.debugRealConfig = [[HMDDebugRealConfig alloc] initWithParams:model.params];
    
    if(self.debugRealConfig.isNeedWifi && ![HMDNetworkReachability isWifiConnected]) {
        result.status = AWECloudCommandStatusFail;
        result.errorMessage = @"The user is not in Wi-Fi environment.";
        if (completion) {
            completion(result);
        }
        return;
    }
    
    NSData *data = nil;
    NSArray *performanceData = [NSArray array];
    
    performanceData = [[HMDPerformanceReporterManager sharedInstance] allDebugRealPeformanceDataWithConfig:self.debugRealConfig];
    
    if (performanceData.count > 0) {
        NSMutableDictionary *jsonObj = [NSMutableDictionary dictionaryWithCapacity:2];
        [jsonObj setValue:performanceData forKey:@"data"];
        [jsonObj setValue:[HMDUploadHelper sharedInstance].headerInfo forKey:@"header"];
        
        NSError *error;
        
        data = [NSJSONSerialization dataWithJSONObject:jsonObj options:NSJSONWritingPrettyPrinted error:&error];
    }
    
    if (completion) {
        if (data) {
            result.data = data;
        }
        [result setUploadSuccessedBlock:^{
            [[HMDPerformanceReporterManager sharedInstance] cleanupWithConfig:self.debugRealConfig];
            if (performanceData.count > 0) {
                if([NSThread isMainThread]) {
                    hmd_safe_dispatch_async(self.operationQueue, ^{
                        [self excuteCommand:model completion:completion];
                    });
                } else {
                    [self excuteCommand:model completion:completion];
                }
            }
        }];
        [result setUploadFailedBlock:^(NSError * _Nonnull error) {
            static NSUInteger retryCount = 0;
            retryCount++;
            if (retryCount < 4 && performanceData.count > 0) {
                if([NSThread isMainThread]) {
                    hmd_safe_dispatch_async(self.operationQueue, ^{
                        [self excuteCommand:model completion:completion];
                    });
                } else {
                    [self excuteCommand:model completion:completion];
                }
            }
        }];
        if(performanceData.count == 0) {
            result.status = AWECloudCommandStatusSucceed;
        }
        completion(result);
    }
}

/// 执行自定义命令
- (void)__attribute__((annotate("oclint:suppress[block captured instance self]")))
refactorExecuteCommand:(AWECloudCommandModel *)model
completion:(AWECloudCommandResultCompletion)completion {
       AWECloudCommandResult *result = [[AWECloudCommandResult alloc] init];
       result.fileName = @"slardar_performance.json";
       result.commandId = model.commandId;
       result.operateTimestamp = [[NSDate date] timeIntervalSince1970];
       result.mimeType = @"application/json";
       result.fileType = @"log_performance";
       result.status = AWECloudCommandStatusInProgress;
       
       self.debugRealConfig = [[HMDDebugRealConfig alloc] initWithParams:model.params];
       
       if(self.debugRealConfig.isNeedWifi && ![HMDNetworkReachability isWifiConnected]) {
           result.status = AWECloudCommandStatusFail;
           result.errorMessage = @"The user is not in Wi-Fi environment.";
           if (completion) {
               completion(result);
           }
           return;
       }
       
       [self fetchPerformanceDataWithCallback:^(NSArray * res, FinishBlock finishBlock) {
           NSData *data = nil;
           NSArray *performanceData = [NSArray arrayWithArray:res];
           
           if (performanceData.count > 0) {
               NSMutableDictionary *jsonObj = [NSMutableDictionary dictionaryWithCapacity:2];
               [jsonObj setValue:performanceData forKey:@"data"];
               [jsonObj setValue:[HMDUploadHelper sharedInstance].headerInfo forKey:@"header"];
               
               NSError *error;
               
               data = [NSJSONSerialization dataWithJSONObject:jsonObj options:NSJSONWritingPrettyPrinted error:&error];
           }
           
           if (completion) {
               if (data) {
                   result.data = data;
               }
               [result setUploadSuccessedBlock:^{
                   if (finishBlock) finishBlock(YES);
                   if (performanceData.count > 0) {
                       if([NSThread isMainThread]) {
                           hmd_safe_dispatch_async(self.operationQueue, ^{
                               [self excuteCommand:model completion:completion];
                           });
                       } else {
                           [self excuteCommand:model completion:completion];
                       }
                   }
               }];
               [result setUploadFailedBlock:^(NSError * _Nonnull error) {
                   if (finishBlock) finishBlock(NO);
                   static NSUInteger retryCount = 0;
                   retryCount++;
                   if (retryCount < 4 && performanceData.count > 0) {
                       if([NSThread isMainThread]) {
                           hmd_safe_dispatch_async(self.operationQueue, ^{
                               [self excuteCommand:model completion:completion];
                           });
                       } else {
                           [self excuteCommand:model completion:completion];
                       }
                   }
               }];
               if(performanceData.count == 0) {
                   result.status = AWECloudCommandStatusSucceed;
               }
               completion(result);
           }
       }];
}

- (void)fetchPerformanceDataWithCallback:(void(^)(NSArray *, FinishBlock FinishBlock))callback {
    
    HMSearchAndCondition *andConditions = [[HMSearchAndCondition alloc] init];
    
    // 回捞开始时间
    HMSearchCondition *start_time_condition = [[HMSearchCondition alloc] init];
    start_time_condition.key = @"timestamp";
    start_time_condition.threshold = self.debugRealConfig.fetchStartTime * 1000;
    start_time_condition.judgeType = HMConditionJudgeGreater;
    [andConditions addCondition:start_time_condition];
    
    // 回捞结束时间
    HMSearchCondition *end_time_condition = [[HMSearchCondition alloc] init];
    end_time_condition.key = @"timestamp";
    end_time_condition.threshold = self.debugRealConfig.fetchEndTime * 1000;
    end_time_condition.judgeType = HMConditionJudgeLess;
    [andConditions addCondition:end_time_condition];
    
    HMSearchParam *param = [[HMSearchParam alloc] init];
    param.moduleId = @"batch";
    param.aid = [HMDInjectedInfo defaultInfo].appID;
    param.condition = andConditions;
    param.userInfo = self.debugRealConfig;
    
    [[HMEngine sharedEngine] searchWithParam:param callback:^(NSArray<NSString *> * _Nonnull result, FinishBlock FinishBlock) {
        if (callback) {
            callback(result, FinishBlock);
        }
    }];

}

@end
