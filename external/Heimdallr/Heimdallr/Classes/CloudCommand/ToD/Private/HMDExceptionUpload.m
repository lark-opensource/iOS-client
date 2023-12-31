//
//  HMDExceptionUpload.m
//  AWECloudCommand
//
//  Created by fengyadong on 2018/8/31.
//

#import "HMDExceptionUpload.h"
#import "HMDDebugRealConfig.h"
#import "HMDExceptionReporter.h"
#import "HMDUploadHelper.h"
#import "HMDNetworkReachability.h"

#import "HMDInjectedInfo.h"
#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP

@interface HMDExceptionUpload()

@property (nonatomic, strong) HMDDebugRealConfig *debugRealConfig;

@end

@implementation HMDExceptionUpload

AWE_REGISTER_CLOUD_COMMAND(@"slardar_exception");

/// 创建用于执行指令的实例变量
+ (instancetype)createInstance {
    return [[HMDExceptionUpload alloc] init];
}

/// 执行自定义命令
- (void)__attribute__((annotate("oclint:suppress[block captured instance self]")))
excuteCommand:(AWECloudCommandModel *)model
completion:(AWECloudCommandResultCompletion)completion {
    
    if (hermas_enabled()) {
        [self RefactorExcuteCommand:model completion:completion];
    } else {
        [self oldExcuteCommand:model completion:completion];
    }
}

/// 执行自定义命令
- (void)__attribute__((annotate("oclint:suppress[block captured instance self]")))
oldExcuteCommand:(AWECloudCommandModel *)model
completion:(AWECloudCommandResultCompletion)completion {
    AWECloudCommandResult *result = [[AWECloudCommandResult alloc] init];
    result.fileName = @"slardar_exception.json";
    result.commandId = model.commandId;
    result.operateTimestamp = [[NSDate date] timeIntervalSince1970];
    result.mimeType = @"application/json";
    result.fileType = @"log_exception";
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
    
    NSArray *allExceptionData = [NSArray array];
    NSArray *exceptionData = [NSArray array];
    exceptionData = [[HMDExceptionReporter sharedInstance] allDebugRealExceptionDataWithConfig:self.debugRealConfig];
    
    if(exceptionData) {
        allExceptionData = [allExceptionData arrayByAddingObjectsFromArray:exceptionData];
    }
    
    NSData *data = nil;
    if (allExceptionData.count > 0) {
        NSMutableDictionary *jsonObj = [NSMutableDictionary dictionaryWithCapacity:2];
        [jsonObj setValue:allExceptionData forKey:@"data"];
        [jsonObj setValue:[HMDUploadHelper sharedInstance].headerInfo forKey:@"header"];
        
        NSError *error;
        
        data = [NSJSONSerialization dataWithJSONObject:jsonObj options:NSJSONWritingPrettyPrinted error:&error];
    }
    
    if (completion) {
        if (data) {
            result.data = data;
        }
        [result setUploadSuccessedBlock:^{
            [[HMDExceptionReporter sharedInstance] cleanupExceptionDataWithConfig:self.debugRealConfig];
            if (exceptionData.count > 0) {
                [self excuteCommand:model completion:completion];
            }
        }];
        [result setUploadFailedBlock:^(NSError * _Nonnull error) {
            static NSUInteger retryCount = 0;
            retryCount++;
            if (retryCount < 4 && exceptionData.count > 0) {
                [self excuteCommand:model completion:completion];
            }
        }];
        if(exceptionData.count == 0) {
            result.status = AWECloudCommandStatusSucceed;
        }
        completion(result);
    }
}

/// 执行自定义命令
- (void)__attribute__((annotate("oclint:suppress[block captured instance self]")))
RefactorExcuteCommand:(AWECloudCommandModel *)model
completion:(AWECloudCommandResultCompletion)completion {
    AWECloudCommandResult *result = [[AWECloudCommandResult alloc] init];
    result.fileName = @"slardar_exception.json";
    result.commandId = model.commandId;
    result.operateTimestamp = [[NSDate date] timeIntervalSince1970];
    result.mimeType = @"application/json";
    result.fileType = @"log_exception";
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
    [self fetchExcptionDataWithCallback:^(NSArray *res, FinishBlock FinishBlock) {
        NSArray *allExceptionData = [NSArray array];
        NSArray *exceptionData = [NSArray arrayWithArray:res];
        
        if(exceptionData) {
            allExceptionData = [allExceptionData arrayByAddingObjectsFromArray:exceptionData];
        }
        
        NSData *data = nil;
        if (allExceptionData.count > 0) {
            NSMutableDictionary *jsonObj = [NSMutableDictionary dictionaryWithCapacity:2];
            [jsonObj setValue:allExceptionData forKey:@"data"];
            [jsonObj setValue:[HMDUploadHelper sharedInstance].headerInfo forKey:@"header"];
            
            NSError *error;
            
            data = [NSJSONSerialization dataWithJSONObject:jsonObj options:NSJSONWritingPrettyPrinted error:&error];
        }
        
        if (completion) {
            if (data) {
                result.data = data;
            }
            [result setUploadSuccessedBlock:^{
                if (FinishBlock) FinishBlock(YES);
                if (exceptionData.count > 0) {
                    [self excuteCommand:model completion:completion];
                }
            }];
            [result setUploadFailedBlock:^(NSError * _Nonnull error) {
                if (FinishBlock) FinishBlock(NO);
                static NSUInteger retryCount = 0;
                retryCount++;
                if (retryCount < 4 && exceptionData.count > 0) {
                    [self excuteCommand:model completion:completion];
                }
            }];
            if(exceptionData.count == 0) {
                result.status = AWECloudCommandStatusSucceed;
            }
            completion(result);
        }
    }];
    
}


- (void)fetchExcptionDataWithCallback:(void(^)(NSArray *, FinishBlock FinishBlock))callback {
    
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
    param.moduleId = @"collect";
    param.aid = [HMDInjectedInfo defaultInfo].appID;
    param.condition = andConditions;
    
    [[HMEngine sharedEngine] searchWithParam:param callback:^(NSArray<NSString *> * _Nonnull result, FinishBlock FinishBlock) {
        if (callback) {
            callback(result, FinishBlock);
        }
    }];
    
}

- (NSString *)eventTypeWithCloudCommandUploadType: (NSString *)uploadType {
    if ([uploadType isEqualToString:@"enable_anr_monitor"]) return @"lag";
    if ([uploadType isEqualToString:@"enable_oom_monitor"]) return @"oom";
    if ([uploadType isEqualToString:@"enable_exception_monitor"]) return @"exception";
    return nil;
}

@end
