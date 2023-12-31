//
//  HMDAppExitReasonDetector+LogUpload.m
//  Heimdallr
//
//  Created by Ysurfer on 2023/3/3.
//
#import "HMDFileTool.h"
#import "HMDDynamicCall.h"
#import "HMDSessionTracker.h"
#import "HMDALogProtocol.h"
#import "HeimdallrUtilities.h"
#import "HMDFileWriter.hpp"
#import "HMDMemoryLogInfo.hpp"
#import "HMDMacro.h"
#import <objc/runtime.h>
#import "HMDFileUploader.h"
#import "NSDictionary+HMDJSON.h"
#import "NSDictionary+HMDSafe.h"
#import "HMDAppExitReasonDetector+LogUpload.h"
// PrivateServices
#import "HMDServerStateService.h"
#import "HMDURLSettings.h"
#import "HMDZipArchiveService.h"

NSString * const HMD_OOM_LogZipDirectory = @"oom_log_zip";
NSString * const HMD_OOM_LogDirectory = @"oom_log";
static dispatch_queue_t _uploadQueue = nil;
static dispatch_semaphore_t _uploadSemaphore = dispatch_semaphore_create(1);

@implementation HMDAppExitReasonDetector (LogUpload)

+ (BOOL)shouldUploadMemoryLog {
    return YES;
}

+ (NSString *)memoryLogPreparedPath {
    NSString *path = [[HeimdallrUtilities heimdallrRootPath] stringByAppendingPathComponent:kHMD_OOM_DirectoryName];
    NSString *preparedPath = [path stringByAppendingPathComponent:HMD_OOM_LogZipDirectory];
    return preparedPath;
}

+ (NSString *)memoryLogProcessingPath {
    NSString *path = [[HeimdallrUtilities heimdallrRootPath] stringByAppendingPathComponent:kHMD_OOM_DirectoryName];
    NSString *processingPath = [path stringByAppendingPathComponent:HMD_OOM_LogDirectory];
    return processingPath;
}

+ (void)cleanupIdentifier:(NSString *)zipFilePath {
    NSFileManager *manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:zipFilePath]) {
        [manager removeItemAtPath:zipFilePath error:nil];
    }
}

+ (void)uploadMemoryInfoAsync {
    _uploadQueue = dispatch_queue_create("com.heimdallr.memory.loginfo.upload",DISPATCH_QUEUE_SERIAL);
    dispatch_async(_uploadQueue, ^{
        [self uploadLastMemoryInfoScene];
    });
}

+ (void)uploadLastMemoryInfoScene {
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *preparedPath = [self memoryLogPreparedPath];
    NSString *processingPath = [self memoryLogProcessingPath];
    
    NSString *internalSessionID = [HMDSessionTracker currentSession].eternalSessionID;
    if (internalSessionID == nil) {
        return;
    }
    //必须先创建文件夹否则文件写入一定会失败
    if (![[NSFileManager defaultManager] fileExistsAtPath:preparedPath]) {
        hmdCheckAndCreateDirectory(preparedPath);
    }
    NSArray<NSString *> *filePaths = [manager contentsOfDirectoryAtPath:processingPath error:nil];
    for(NSString *filePath in filePaths) {
        if ([filePath isEqualToString:internalSessionID]) {
            continue;
        }
        NSString *oomLogPath = [processingPath stringByAppendingPathComponent:filePath];
        NSMutableArray *logFiles = [NSMutableArray new];
        [logFiles addObject:oomLogPath];
        NSString *zipPath = [NSString stringWithFormat:@"%@/%@.zip",preparedPath,filePath];

        BOOL zipSuccessed = [HMDZipArchiveService createZipFileAtPath:zipPath withFilesAtPaths:logFiles];
        [manager removeItemAtPath:oomLogPath error:nil];
        // 压缩失败，则清理失败的zip，然后返回结果
        if (!zipSuccessed) {
            if ([[NSFileManager defaultManager] fileExistsAtPath:zipPath]) {
                [[NSFileManager defaultManager] removeItemAtPath:zipPath error:nil];
            }
            
            NSDictionary *category = @{@"status":@(0),@"reason":@"compress_failed"};
            DC_OB(DC_CL(HMDTTMonitor, heimdallrTTMonitor), hmdTrackService:metric:category:extra:syncWrite:, @"slardar_memory_loginfo_upload", nil, category, nil, YES);
            
            HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"memory loginfo file zip failed");
            return;
        }
    }
    
    [self uploadPreparedFiles];
}

+ (void)uploadPreparedFiles {
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *rootPath = [self memoryLogPreparedPath];
    if ([manager fileExistsAtPath:rootPath]) {
        NSArray<NSString *> *filePaths = [manager contentsOfDirectoryAtPath:rootPath error:nil];
        [filePaths enumerateObjectsUsingBlock:^(NSString * _Nonnull identifier, NSUInteger idx, BOOL * _Nonnull stop) {
            dispatch_semaphore_wait(_uploadSemaphore, DISPATCH_TIME_FOREVER);
            NSString *zipFilePath = [rootPath stringByAppendingPathComponent:identifier];
            [self uploadMemoryInfoAtPath:zipFilePath scene:@"memory_log_info" retryCount:0 byUser:NO];
        }];
    }
}

+ (void)uploadMemoryInfoAtPath:(NSString *)zipPath scene:(NSString *)scene retryCount:(NSUInteger)retryCount byUser:(BOOL)byUser {
#if RANGERSAPM
    return;
#else
    HMDFileUploader* uploader = [HMDFileUploader sharedInstance];
    if ([uploader respondsToSelector:@selector(uploadFileWithRequest:)]) {
        HMDFileUploadRequest *request = [HMDFileUploadRequest new];
        request.filePath = zipPath;
        request.logType = @"memoryLog";
        request.scene = scene;
        request.byUser = byUser;
        request.path = [HMDURLSettings memoryInfoUploadPath];
        request.finishBlock = ^(BOOL uploadSuccess, id jsonObject) {
            if ([jsonObject isKindOfClass:[NSDictionary class]]) {
                dispatch_semaphore_signal(_uploadSemaphore);
                
                if (uploadSuccess) {
                    NSString *reasonStr = @"uploadSuccess";
                    NSDictionary *category = @{@"status" : reasonStr};
                    DC_OB(DC_CL(HMDTTMonitor, heimdallrTTMonitor), hmdTrackService:metric:category:extra:syncWrite:, @"slardar_memory_loginfo_upload", nil, category, nil, YES);
                    HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"memory loginfo upload success");
                    [HMDAppExitReasonDetector cleanupIdentifier:zipPath];
                } else {
                    if (retryCount <= 3) {
                        //失败10s后重试
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), _uploadQueue, ^{
                            dispatch_semaphore_wait(_uploadSemaphore, DISPATCH_TIME_FOREVER);
                            [self uploadMemoryInfoAtPath:zipPath scene:scene retryCount:retryCount+1 byUser:byUser];
                        });
                    } else {
                        [HMDAppExitReasonDetector cleanupIdentifier:zipPath];
                        NSDictionary *category = @{@"status":@(0),@"reason":@"upload_failed"};
                        DC_OB(DC_CL(HMDTTMonitor, heimdallrTTMonitor), hmdTrackService:metric:category:extra:syncWrite:, @"slardar_memory_loginfo_upload", nil, category, nil, YES);
                        HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"memory loginfo upload failed");
                    }
                }
            }
        };
        [uploader uploadFileWithRequest:request];
    }
#endif
}

+ (void)deleteLastMemoryInfo {
    NSString *lastSessionID = [HMDSessionTracker sharedInstance].lastTimeEternalSessionID;
    if (lastSessionID == nil) {
        return;
    }
    NSString *processingPath = [self memoryLogProcessingPath];
    NSFileManager *manager = [NSFileManager defaultManager];
    NSArray<NSString *> *filePaths = [manager contentsOfDirectoryAtPath:processingPath error:nil];
    for(NSString *filePath in filePaths) {
        if ([filePath isEqualToString:lastSessionID]) {
            NSString *oomLogPath = [processingPath stringByAppendingPathComponent:filePath];
            [manager removeItemAtPath:oomLogPath error:nil];
            break;
        }
    }
}

@end
