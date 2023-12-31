//
//  HMDALogUpload.m
//  AWECloudCommand
//
//  Created by fengyadong on 2018/9/18.
//

#import "HMDALogUpload.h"
#import "HMDFileUploader.h"
#import "HMDDynamicCall.h"
#import "HMDALogProtocol.h"
#import "NSArray+HMDSafe.h"
#import "HMDMacro.h"
#import "HMDCloudCommandManager.h"
#import "HMDMonitorService.h"

CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_DOCUMENTATION
#import <BDALog/BDAgileLog.h>
CLANG_DIAGNOSTIC_POP
#include <vector>
#import "HMDServiceContext.h"
// PrivateServices
#import "HMDDebugLogger.h"
#import "HMDMonitorService.h"

#if RANGERSAPM
static NSString * const kCommandALog = @"alog";
static NSString * const kEventALogUpload = @"alog_upload";
static NSString * const kEventALogUploadStart = @"alog_upload_start";
#else
static NSString * const kCommandALog = @"slardar_alog";
static NSString * const kEventALogUpload = @"slardar_alog_upload";
static NSString * const kEventALogUploadStart = @"slardar_alog_upload_start";
#endif /* RANGERSAPM */

#if defined(__GNUC__)
#define WEAK_FUNC     __attribute__((weak))
#elif defined(_MSC_VER) && !defined(_LIB)
#define WEAK_FUNC __declspec(selectany)
#else
#define WEAK_FUNC
#endif

extern "C"
{
void WEAK_FUNC alog_getFilePaths_all_instance(long long fromTimeInterval, long long toTimeInterval, std::vector<std::string>& _filepath_vec) {
    alog_getFilePaths(fromTimeInterval, toTimeInterval, _filepath_vec);
}

void WEAK_FUNC alog_remove_file_instance(const char* instance_name, const char* _filepath) {}
}

static const NSInteger maxAlogFile = 50;

@implementation HMDALogUpload

AWE_REGISTER_CLOUD_COMMAND(kCommandALog);

/// 创建用于执行指令的实例变量
+ (instancetype)createInstance {
    return [[HMDALogUpload alloc] init];
}

/// 执行自定义命令
- (void)excuteCommand:(AWECloudCommandModel *)model
           completion:(AWECloudCommandResultCompletion)completion {
    NSDictionary *extra = @{@"cid":model.commandId ?: @"unknown"};
    [HMDMonitorService trackService:kEventALogUploadStart metrics:nil dimension:nil extra:extra syncWrite:YES];
    
    long long fetchStartTime = [[model.params valueForKey:@"fetch_start_time"] longLongValue];
    long long fetchEndTime = [[model.params valueForKey:@"fetch_end_time"] longLongValue];
    
    NSMutableArray *logFiles = [NSMutableArray new];
    
    // 把缓存数据同步写入文件
    alog_flush_sync();
    
    // 获取满足要求的文件路径
    std::vector<std::string> filePathArray;
    alog_getFilePaths_all_instance(fetchStartTime, fetchEndTime, filePathArray);
    long count = filePathArray.size();
    for (int i = 0; i < count; i++) {
        std::string path = filePathArray[i];
        NSString *pathString = [NSString stringWithCString:path.c_str()
                                                  encoding:[NSString defaultCStringEncoding]];
        if (pathString) {
            [logFiles addObject:pathString];
        }
    }
    
    CloudCommandAlogUploadBlock block = [HMDCloudCommandManager sharedInstance].alogUploadBlock;
    [self _uploadLogFiles:logFiles commandModel:model originFilesCount:(NSInteger)count completion:completion userBlock:block];
}

#pragma - mark Upload file

- (void)_uploadLogFiles:(NSArray *)logFiles
           commandModel:(AWECloudCommandModel *)model
       originFilesCount:(NSInteger)originCount
             completion:(AWECloudCommandResultCompletion)completion
              userBlock:(CloudCommandAlogUploadBlock)userBlock
{
    AWECloudCommandResult *result = [[AWECloudCommandResult alloc] init];
    
    result.commandId = model.commandId;
    result.operateTimestamp = [[NSDate date] timeIntervalSince1970];
    
    long long fetchStartTime = [[model.params valueForKey:@"fetch_start_time"] longLongValue];
    long long fetchEndTime = [[model.params valueForKey:@"fetch_end_time"] longLongValue];
    
    if (logFiles.count > 0) {
        NSMutableArray<AWECloudCommandMultiData *> *dataArr = [NSMutableArray new];
        int indexOffset = (int)originCount - (int)logFiles.count;
        
        for (int i = 0; i < logFiles.count && dataArr.count < maxAlogFile; i++) {
            @autoreleasepool {
                NSString *filePath = logFiles[i];
                if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
                    NSData *logData = [NSData dataWithContentsOfFile:filePath];
                    NSString *fileName = [filePath pathComponents].lastObject;
                    NSString *fileFullName = [NSString stringWithFormat:@"%d-%@", (i+indexOffset), fileName];
                    AWECloudCommandMultiData *multiData = [AWECloudCommandMultiData new];
                    multiData.data = logData;
                    multiData.fileName = fileFullName;
                    multiData.fileType = @"log_agile";
                    multiData.mimeType = @"application/octet-stream";
                    [dataArr addObject:multiData];
                }
            }
        }
        
        result.isMultiData = YES;
        result.multiDataArray = [dataArr copy];
        if (logFiles.count > dataArr.count) {
            result.status = AWECloudCommandStatusInProgress;
        }
        else {
            result.status = AWECloudCommandStatusSucceed;
        }
    } else {
        if (originCount) {
            result.status = AWECloudCommandStatusFail;
#if RANGERSAPM
            result.errorMessage = @"客户端未查询到日志文件";
#else
            result.errorMessage = @"Alog path translate failed";
#endif
            
            NSDictionary *category = @{@"status":@"0",@"reason":@"alog_path_translate_failed", @"activateManner":@"cloud_control"};
            NSDictionary *metric = @{@"totalCount":@(originCount)};
            NSDictionary *extra = @{@"fetchStartTime":@(fetchStartTime), @"fetchEndTime":@(fetchEndTime), @"cid":model.commandId ?: @"unknown"};
            [HMDMonitorService trackService:kEventALogUpload metrics:metric dimension:category extra:extra syncWrite:YES];
            HMDALOG_PROTOCOL_WARN_TAG(@"Heimdallr", @"Alog path translate faile, activateManner : cloud_control, count : %ld", originCount);
        }
        else {
            result.status = AWECloudCommandStatusFail;
#if RANGERSAPM
            result.errorMessage = @"客户端未查询到日志文件";
#else
            result.errorMessage = @"Alog not found";
#endif
            
            NSDictionary *category = @{@"status":@"0",@"reason":@"alog_not_found", @"activateManner":@"cloud_control"};
            [HMDMonitorService trackService:kEventALogUpload metrics:nil dimension:category extra:nil syncWrite:YES];
            HMDALOG_PROTOCOL_WARN_TAG(@"Heimdallr", @"Alog path translate faile, activateManner : cloud_control, count : %ld", originCount);
        }
    }
    
    // 上传回调
    if (completion) {
        static NSUInteger retryCount = 0;
        NSInteger fileUploadedCount = result.multiDataArray.count;
        [result setUploadSuccessedBlock:^{
            [HMDDebugLogger printLog:@"ALog is uploaded successfully!"];
            retryCount = 0;
            
            if (fileUploadedCount < logFiles.count) {
                NSMutableArray *needUploadFiles = [NSMutableArray arrayWithArray:logFiles];
                [needUploadFiles removeObjectsInRange:NSMakeRange(0, fileUploadedCount)];
                [self _uploadLogFiles:needUploadFiles commandModel:model originFilesCount:originCount completion:completion userBlock:userBlock];
            }
            else {
                for (NSString *path in logFiles) {
                    alog_remove_file(path.UTF8String);
                }
                
                NSDictionary *category = @{@"status":@"200",@"reason":@"success", @"activateManner":@"cloud_control"};
                NSDictionary *metric = @{@"totalCount":@(logFiles.count)};
                NSDictionary *extra = @{@"fetchStartTime":@(fetchStartTime), @"fetchEndTime":@(fetchEndTime), @"cid":model.commandId ?: @"unknown"};
                [HMDMonitorService trackService:kEventALogUpload metrics:metric dimension:category extra:extra syncWrite:YES];
                
                if (userBlock) {
                    userBlock(fetchStartTime, fetchEndTime, originCount, (int)AWECloudCommandStatusSucceed, nil);
                }
            }
        }];
        [result setUploadFailedBlock:^(NSError * _Nonnull error) {
            [HMDDebugLogger printLog:[NSString stringWithFormat:@"Upload ALog failed, reason : %@", error.localizedDescription]];
            retryCount++;
            if (retryCount < 3) {
                [self _uploadLogFiles:logFiles commandModel:model originFilesCount:originCount completion:completion userBlock:userBlock];
            } else {
                retryCount = 0;
                
                NSDictionary *category = @{@"status":@(error.code).stringValue,@"reason":error.localizedDescription ?: @"unknown", @"activateManner":@"cloud_control"};
                NSDictionary *metric = @{@"totalCount":@(logFiles.count), @"filesCount":@(fileUploadedCount)};
                NSDictionary *extra = @{@"fetchStartTime":@(fetchStartTime), @"fetchEndTime":@(fetchEndTime), @"cid":model.commandId ?: @"unknown"};
                [HMDMonitorService trackService:kEventALogUpload metrics:metric dimension:category extra:extra syncWrite:YES];
                HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"Alog file upload failed, reason : %@, activateManner : cloud_control, count : %lu", error.localizedDescription, logFiles.count);
                
                if (userBlock) {
                    userBlock(fetchStartTime, fetchEndTime, originCount, (int)AWECloudCommandStatusFail, error.localizedDescription ?: @"unknown");
                }
            }
        }];
        completion(result);
    }
}

@end
