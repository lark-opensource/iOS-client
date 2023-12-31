//
//  HMDCPUExceptionUpload.m
//  Heimdallr
//
//  Created by zhangxiao on 2020/5/20.
//

#import "HMDCPUExceptionUpload.h"
#import "HMDDynamicCall.h"
#import "NSDictionary+HMDJSON.h"

@implementation HMDCPUExceptionUpload

AWE_REGISTER_CLOUD_COMMAND(@"cpu_exception");

+ (nonnull instancetype)createInstance {
    return [[HMDCPUExceptionUpload alloc] init];
}

- (void)excuteCommand:(nonnull AWECloudCommandModel *)model completion:(nonnull AWECloudCommandResultCompletion)completion {

    AWECloudCommandResult *result = [[AWECloudCommandResult alloc] init];
    result.fileName = @"slardar_cpu_exception.json";
    result.commandId = model.commandId;
    result.operateTimestamp = [[NSDate date] timeIntervalSince1970];
    result.mimeType = @"application/json";
    result.fileType = @"log_exception";

    if (!DC_CL(HMDCPUExceptionMonitor, sharedMonitor)) {
        result.status = AWECloudCommandStatusFail;
        result.errorMessage = @"The current version does not import CPU exception modules";
        if (completion) {
            completion(result);
        }
        return;
    }

    void (^cloudCommandCompletion)(NSDictionary *dict, BOOL success) = ^(NSDictionary *dict, BOOL success) {
        if (success) {
            result.data = [dict hmd_jsonData];
            result.status = AWECloudCommandStatusSucceed;
        } else {
            result.status = AWECloudCommandStatusFail;
            result.errorMessage = @"The current user has hit the CPU exception sample, please query in the CPU exception.";
        }
        if (completion) {
            completion(result);
        }
    };

    DC_OB(DC_CL(HMDCPUExceptionMonitor, sharedMonitor), fetchCPUExceptionOneCycleInfoWithCompletion:, [cloudCommandCompletion copy]);
}

@end
