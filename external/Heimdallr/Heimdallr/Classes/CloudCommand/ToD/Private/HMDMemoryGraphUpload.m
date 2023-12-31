//
//	HMDMemoryGraphUpload.m
// 	Heimdallr
// 	
// 	Created by Hayden on 2020/3/6. 
//

#import "HMDMemoryGraphUpload.h"
#import "HMDDebugRealConfig.h"
#import "HMDNetworkReachability.h"
#import "HMDDynamicCall.h"
#import "NSDictionary+HMDSafe.h"
// PrivateServices
#import "HMDServerStateService.h"

@interface HMDMemoryGraphUpload ()

@property (nonatomic, strong) HMDDebugRealConfig *debugRealConfig;

@end

@implementation HMDMemoryGraphUpload

AWE_REGISTER_CLOUD_COMMAND(@"slardar_memory_log");

/// 创建用于执行指令的实例变量
+ (instancetype)createInstance {
    return [[HMDMemoryGraphUpload alloc] init];
}

/// 执行自定义命令
- (void)excuteCommand:(AWECloudCommandModel *)model
           completion:(AWECloudCommandResultCompletion)completion {
    AWECloudCommandResult *result = [[AWECloudCommandResult alloc] init];
    result.fileName = @"slardar_memory_graph.zip";
    result.commandId = model.commandId;
    result.operateTimestamp = [[NSDate date] timeIntervalSince1970];
    result.mimeType = @"application/zip";
    result.fileType = @"slardar_memory_graph";
    
    // memory graph 模块未启动
    if (!DC_CL(HMDMemoryGraphGenerator, sharedGenerator)) {
        result.status = AWECloudCommandStatusFail;
        result.errorMessage = @"The current version does not integrate the MemoryGraph module.";
        if (completion) {
            completion(result);
        }
        return;
    }
    
    self.debugRealConfig = [[HMDDebugRealConfig alloc] initWithParams:model.params];
    
    if(self.debugRealConfig.isNeedWifi && ![HMDNetworkReachability isWifiConnected]) {
        result.status = AWECloudCommandStatusFail;
        result.errorMessage = @"The user is not in Wi-Fi environment.";
        if (completion) {
            completion(result);
        }
        return;
    }
    
    void(^cloudBlock)(NSError *, NSString *, NSDictionary *) = ^(NSError *error, NSString *zipPath, NSDictionary *additionalUploadParams) {
        if (!hmd_is_server_available(HMDReporterMemoryGraph)) {
            return;
        }
        if (error) {
            result.status = AWECloudCommandStatusFail;
            result.errorMessage = error.localizedFailureReason;
        }
        else {
            result.data = [NSData dataWithContentsOfFile:zipPath];
            result.additionalUploadParams = additionalUploadParams;
        }
        
        NSString *identifier;
        if (zipPath) {
            identifier = [[zipPath lastPathComponent] stringByDeletingPathExtension];
        }
        
        if (completion) {
            if (identifier) {
                [result setUploadSuccessedBlock:^{
                    // 清理已上传的文件
                    DC_CL(HMDMemoryGraphUploader, cleanupIdentifier:, identifier);
                }];
                [result setUploadFailedBlock:^(NSError * _Nonnull error) {
                    DC_CL(HMDMemoryGraphUploader, cleanupIdentifier:, identifier);
                }];
            }
            completion(result);
        }
    };
    
    NSString *remainingMemoryString = [model.params hmd_stringForKey:@"remainingMemory"];
    NSUInteger remainingMemory = remainingMemoryString ? [remainingMemoryString integerValue] : 100;
    DC_OB(DC_CL(HMDMemoryGraphGenerator, sharedGenerator), cloudCommandGenerateWithRemainingMemory:completeBlock:, remainingMemory, [cloudBlock copy]);
}

@end
