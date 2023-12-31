//
//  HMDLogUploader.m
//  Heimdallr
//
//  Created by joy on 2018/9/6.
//

#import "HMDLogUploader.h"
#import "HMDMacro.h"
#include <vector>
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_DOCUMENTATION
#import <BDALog/BDAgileLog.h>
CLANG_DIAGNOSTIC_POP
#import "HMDALogProtocol.h"
#import "HMDFileUploader.h"
#import "HMDInjectedInfo+Alog.h"
#import "NSDictionary+HMDSafe.h"

// PrivateServices
#import "HMDDebugLogger.h"
#import "HMDServerStateService.h"
#import "HMDMonitorService.h"
#import "HMDURLSettings.h"
#import "HMDZipArchiveService.h"

/* Current Disaster Recovery Strategy In ALog Supspec
 * TTNet: Interface, covering interfaces called by non-user
 * Client Control: InjectedInfo - fileStopUpload, covering interfaces called by non-user
 * Slardar: return valued by HMDServerState, covering all interfaces
 */

#if defined(__GNUC__)
#define WEAK_FUNC     __attribute__((weak))
#elif defined(_MSC_VER) && !defined(_LIB)
#define WEAK_FUNC __declspec(selectany)
#else
#define WEAK_FUNC
#endif

#if RANGERSAPM
static NSString * const kEventALogUpload = @"alog_upload";
static NSString * const kEventALogUploadStart = @"alog_upload_start";
#else
static NSString * const kEventALogUpload = @"slardar_alog_upload";
static NSString * const kEventALogUploadStart = @"slardar_alog_upload_start";
#endif /* RANGERSAPM */

extern "C" {

void WEAK_FUNC alog_getZipPaths(std::vector<std::string>& _zip_path_vec) {}

void WEAK_FUNC alog_getZipPaths_instance(const char* instance_name, std::vector<std::string>& _zip_path_vec) {}

void WEAK_FUNC alog_getFilePaths_instance(const char* instance_name, long long fromTimeInterval, long long toTimeInterval, std::vector<std::string>& _filepath_vec) {}

void WEAK_FUNC alog_getFilePaths_all_instance(long long fromTimeInterval, long long toTimeInterval, std::vector<std::string>& _filepath_vec) {
    alog_getFilePaths(fromTimeInterval, toTimeInterval, _filepath_vec);
}

void WEAK_FUNC alog_flush_instance(const char* instance_name) {}

void WEAK_FUNC alog_remove_file_instance(const char* instance_name, const char* _filepath) {}
    
}


static NSString *defaultInstanceName = @"default";

@interface HMDLogUploader()

@property (nonatomic, strong) dispatch_queue_t uploadQueue;
@property (nonatomic, strong) dispatch_semaphore_t uploadSemaphore;
@property (nonatomic, assign) NSUInteger crashUploadSecond;

- (void)crashALogUploadWithEndTime:(NSTimeInterval)endTime;
- (void)exceptionALogUploadWithEndTime:(NSTimeInterval)endTime;

@end

@implementation HMDLogUploader

+ (instancetype)sharedInstance {
    static HMDLogUploader *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HMDLogUploader alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        self.uploadQueue = dispatch_queue_create("com.heimdallr.fileupload", DISPATCH_QUEUE_SERIAL);
        self.uploadSemaphore = dispatch_semaphore_create(1);
    }
    return self;
}

#pragma mark - Report

- (void)reportALogByUsersWithFetchStartTime:(NSTimeInterval)fetchStartTime
                               fetchEndTime:(NSTimeInterval)fetchEndTime
                                      scene:(NSString *)scene
                         reportALogCallback:(HMDReportALogCallback)reportALogBlock {
    [self reportALogByUsersWithFetchStartTime:fetchStartTime
                                 fetchEndTime:fetchEndTime
                                        scene:scene
                                 instanceName:defaultInstanceName
                           reportALogCallback:reportALogBlock];
}

- (void)reportALogByUsersWithFetchStartTime:(NSTimeInterval)fetchStartTime
                               fetchEndTime:(NSTimeInterval)fetchEndTime
                                      scene:(NSString *)scene
                               instanceName:(NSString *)instanceName
                         reportALogCallback:(HMDReportALogCallback)reportALogBlock {
    [self _reportALogAsyncWithScene:scene
                       instanceName:instanceName
                             byUser:YES
                     fetchStartTime:fetchStartTime
                       fetchEndTime:fetchEndTime
                           callback:reportALogBlock];
}

- (void)reportALogbyUsersWithFetchStartTime:(NSTimeInterval)fetchStartTime
                               fetchEndTime:(NSTimeInterval)fetchEndTime
                                      scene:(NSString *)scene
                         reportALogCallback:(HMDReportALogCallback)reportALogBlock {
    [self reportALogByUsersWithFetchStartTime:fetchStartTime
                                 fetchEndTime:fetchEndTime
                                        scene:scene
                           reportALogCallback:reportALogBlock];
}

- (void)reportFeedbackALogWithFetchStartTime:(NSTimeInterval)fetchStartTime
                                fetchEndTime:(NSTimeInterval)fetchEndTime
                                       scene:(NSString *)scene
                          reportALogCallback:(HMDReportALogCallback)reportALogBlock {
    [self reportFeedbackALogWithFetchStartTime:fetchStartTime
                                  fetchEndTime:fetchEndTime
                                         scene:scene
                                  instanceName:defaultInstanceName
                            reportALogCallback:reportALogBlock];
}

- (void)reportFeedbackALogWithFetchStartTime:(NSTimeInterval)fetchStartTime
                                fetchEndTime:(NSTimeInterval)fetchEndTime
                                       scene:(NSString *)scene
                                instanceName:(NSString *)instanceName
                          reportALogCallback:(HMDReportALogCallback)reportALogBlock {
    [self _reportALogAsyncWithScene:scene
                       instanceName:instanceName
                             byUser:YES
                     fetchStartTime:fetchStartTime
                       fetchEndTime:fetchEndTime
                           callback:reportALogBlock];
}

- (void)reportALogWithFetchStartTime:(NSTimeInterval)fetchStartTime
                        fetchEndTime:(NSTimeInterval)fetchEndTime
                               scene:(NSString *)scene {
    [self reportALogWithFetchStartTime:fetchStartTime fetchEndTime:fetchEndTime scene:scene reportALogCallback:nil];
}

- (void)reportALogWithFetchStartTime:(NSTimeInterval)fetchStartTime
                        fetchEndTime:(NSTimeInterval)fetchEndTime
                               scene:(NSString *)scene
                  reportALogCallback:(HMDReportALogCallback)reportALogBlock {
    [self reportALogWithFetchStartTime:fetchStartTime fetchEndTime:fetchEndTime scene:scene instanceName:defaultInstanceName reportALogCallback:reportALogBlock];
}

- (void)reportALogWithFetchStartTime:(NSTimeInterval)fetchStartTime
                        fetchEndTime:(NSTimeInterval)fetchEndTime
                               scene:(NSString *)scene
                        instanceName:(NSString *)instanceName
                  reportALogCallback:(nullable HMDReportALogCallback)reportALogBlock {
    [self _reportALogAsyncWithScene:scene
                       instanceName:instanceName
                             byUser:NO
                     fetchStartTime:fetchStartTime
                       fetchEndTime:fetchEndTime
                           callback:reportALogBlock];
}

- (void)_reportALogAsyncWithScene:(NSString *)scene
                     instanceName:(NSString *)instanceName
                           byUser:(BOOL)byUser
                   fetchStartTime:(NSTimeInterval)fetchStartTime
                     fetchEndTime:(NSTimeInterval)fetchEndTime
                         callback:(HMDReportALogCallback)callback {
    NSAssert(scene != nil, @"The scene can't be nil. Please pass the triggered scene parameter for alog.");
    scene = scene ?: @"unknown";
    NSTimeInterval uploadStartTime = [[NSDate date] timeIntervalSince1970];
    NSDictionary *extra = @{@"scene": scene, @"fetchStartTime": @(fetchStartTime), @"fetchEndTime": @(fetchEndTime)};
    [HMDMonitorService trackService:kEventALogUploadStart metrics:nil dimension:nil extra:extra syncWrite:YES];
    
    @weakify(self);
    dispatch_async(self.uploadQueue, ^{
        @strongify(self);
        [self _reportALogWithScene:scene
                      instanceName:instanceName
                            byUser:byUser
                    fetchStartTime:fetchStartTime
                      fetchEndTime:fetchEndTime
                   uploadStartTime:uploadStartTime
                          callback:callback];
    });
}

- (void)_reportALogWithScene:(NSString * _Nonnull)scene
                instanceName:(NSString * _Nullable)instanceName
                      byUser:(BOOL)byUser
              fetchStartTime:(NSTimeInterval)fetchStartTime
                fetchEndTime:(NSTimeInterval)fetchEndTime
             uploadStartTime:(NSTimeInterval)uploadStartTime
                    callback:(HMDReportALogCallback _Nullable)callback {
    dispatch_semaphore_wait(self.uploadSemaphore, DISPATCH_TIME_FOREVER);
    NSTimeInterval uploadQueneWaitCost = [[NSDate date] timeIntervalSince1970] - uploadStartTime;
    
    NSString *manner = @"manual";
    NSString *uploadFileType = @".zip";
    NSDictionary *extra = @{@"instanName": instanceName ?: @"unknown", @"scene": scene, @"fetchStartTime": @(fetchStartTime), @"fetchEndTime": @(fetchEndTime)};
    
    NSAssert(instanceName != nil, @"The instanceName can't be nil. Please pass instance name parameter for alog.");
    if (!instanceName) {
        if (callback) {
            callback(NO, 0);
        }
        
        dispatch_semaphore_signal(self.uploadSemaphore);
        
        HMDAlogUploadGlobalBlock block = self.uploadGlobalBlock;
        if (block) {
            block(fetchStartTime, fetchEndTime, scene, @"", 0, HMDAlogUploadFailedInstanceNameNil);
        }
        
        NSDictionary *metrics = @{@"uploadQueneWaitCost": @(uploadQueneWaitCost)};
        NSDictionary *dimension = @{@"status": @"0", @"reason": @"alog instance not assigned", @"activateManner": manner};
        [HMDMonitorService trackService:kEventALogUpload metrics:metrics dimension:dimension extra:extra syncWrite:YES];
        HMDALOG_PROTOCOL_WARN_TAG(@"Heimdallr", @"Disables uploading files so hmd can't upload alog.");
        return;
    }
    
    // clean history zip files
    std::vector<std::string> zipPathArray;
    if ([instanceName isEqualToString:defaultInstanceName]) {
        alog_getZipPaths(zipPathArray);
    } else {
        alog_getZipPaths_instance(instanceName.UTF8String, zipPathArray);
    }
    
    long zipPathsCount = zipPathArray.size();
    for (int i = 0; i < zipPathsCount; i++) {
        std::string zipPath = zipPathArray[i];
        NSString *zipPathString = [NSString stringWithCString:zipPath.c_str()
                                                     encoding:[NSString defaultCStringEncoding]];
        
        NSError *removeError = nil;
        if (zipPathString != nil && [[NSFileManager defaultManager] fileExistsAtPath:zipPathString]) {
            [[NSFileManager defaultManager] removeItemAtPath:zipPathString error:&removeError];
            
            if (removeError != nil) {
                HMDALOG_PROTOCOL_WARN_TAG(@"Heimdallr", @"Alog history zip file delete failed. zipFileName: %@, removeError: %@", zipPathString, removeError);
            }
        } else {
            HMDALOG_PROTOCOL_WARN_TAG(@"Heimdallr", @"Alog history zip file not found. zipFileName: %@", zipPathString);
        }
    }
    
    // Don't check FileStopUpload when real users send requests.
    if (!byUser && ![HMDInjectedInfo defaultInfo].canUploadFile) {
        if (callback) {
            callback(NO, 0);
        }
        
        dispatch_semaphore_signal(self.uploadSemaphore);
        
        HMDAlogUploadGlobalBlock block = self.uploadGlobalBlock;
        if (block) {
            block(fetchStartTime, fetchEndTime, scene, instanceName, 0, HMDAlogUploadFailedFileStopUploadByHost);
        }
        
        NSDictionary *metrics = @{@"uploadQueneWaitCost": @(uploadQueneWaitCost)};
        NSDictionary *dimension = @{@"status": @"0", @"reason": @"fileStopUpload", @"activateManner": manner, @"uploadFileType": uploadFileType};
        [HMDMonitorService trackService:kEventALogUpload metrics:metrics dimension:dimension extra:extra syncWrite:YES];
        HMDALOG_PROTOCOL_WARN_TAG(@"Heimdallr", @"Disables uploading files so hmd can't upload alog.");
        return;
    }
    
    if (!hmd_is_server_available(HMDReporterALog)) {
        if (callback) {
            callback(NO, 0);
        }
        
        dispatch_semaphore_signal(self.uploadSemaphore);
        
        HMDAlogUploadGlobalBlock block = self.uploadGlobalBlock;
        if (block) {
            block(fetchStartTime, fetchEndTime, scene, instanceName, 0, HMDAlogUploadFailedServerUnavailable);
        }
        
        NSDictionary *metrics = @{@"uploadQueneWaitCost": @(uploadQueneWaitCost)};
        NSDictionary *dimension = @{@"status": @"0", @"reason": @"server_unavailable", @"activateManner": manner, @"uploadFileType": uploadFileType};
        [HMDMonitorService trackService:kEventALogUpload metrics:metrics dimension:dimension extra:extra syncWrite:YES];
        HMDALOG_PROTOCOL_WARN_TAG(@"Heimdallr", @"Server disables uploading alog file.");
        return;
    }
    
    // check allow upload by host
    HMDForbidAllowAlogUploadBlock block = self.forbidAlogUploadBlock;
    if (block && block(scene)) {
        if (callback) {
            callback(NO, 0);
        }

        dispatch_semaphore_signal(self.uploadSemaphore);
        
        HMDAlogUploadGlobalBlock block = self.uploadGlobalBlock;
        if (block) {
            block(fetchStartTime, fetchEndTime, scene, instanceName, 0, HMDAlogUploadFailedAlogStopUploadByHost);
        }
        
        NSDictionary *metrics = @{@"uploadQueneWaitCost": @(uploadQueneWaitCost)};
        NSDictionary *dimension = @{@"status": @"0", @"reason": @"forbidden_according_secne_by_host", @"activateManner": manner, @"uploadFileType": uploadFileType};
        [HMDMonitorService trackService:kEventALogUpload metrics:metrics dimension:dimension extra:extra syncWrite:YES];
        HMDALOG_PROTOCOL_WARN_TAG(@"Heimdallr", @"Alog upload is forbidden by host according to scene. scene = %@", scene);
        return;
    }
    
    NSTimeInterval fileProcessStartTime = [[NSDate date] timeIntervalSince1970];
    NSString *zipBasePath = nil;
    NSMutableArray *logFiles = [NSMutableArray new];
    // 把缓存数据写入文件
    if ([instanceName isEqualToString:defaultInstanceName]) {
        alog_flush_sync();
    } else {
        alog_flush_instance(instanceName.UTF8String);
    }
    // 获取满足要求的文件路径
    std::vector<std::string> filePathArray;
    if ([instanceName isEqualToString:defaultInstanceName]) {
        alog_getFilePaths(fetchStartTime, fetchEndTime, filePathArray);
    } else {
        alog_getFilePaths_instance(instanceName.UTF8String, fetchStartTime, fetchEndTime, filePathArray);
    }

    long count = MIN(filePathArray.size(), [self _maxUploadFileCount:scene]);
    for (int i = 0; i < count; i++) {
        std::string path = filePathArray[i];
        NSString *pathString = [NSString stringWithCString:path.c_str()
                                                  encoding:[NSString defaultCStringEncoding]];
        if (pathString) {
            [logFiles addObject:pathString];
            zipBasePath = [pathString stringByDeletingLastPathComponent];
        }
    }
    if (logFiles.count > 0) {
        // 压缩文件
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy_MM_dd_HH_mm_ss"];
        NSString *dateTime = [formatter stringFromDate:[NSDate date]];
        
        NSString *zipPath = [NSString stringWithFormat:@"%@/%@.zip", zipBasePath, dateTime];
        
        NSTimeInterval fileProcessCost = [[NSDate date] timeIntervalSince1970] - fileProcessStartTime;
        if(![[NSFileManager defaultManager] fileExistsAtPath:zipPath]) {
            BOOL zipSuccessed = [HMDZipArchiveService createZipFileAtPath:zipPath withFilesAtPaths:logFiles];
            fileProcessCost = [[NSDate date] timeIntervalSince1970] - fileProcessStartTime;
            // 压缩失败，则清理失败的zip，然后返回结果
            if (!zipSuccessed) {
                if ([[NSFileManager defaultManager] fileExistsAtPath:zipPath]) {
                    NSError *removeError = nil;
                    [[NSFileManager defaultManager] removeItemAtPath:zipPath error:&removeError];
                    if (removeError != nil) {
                        HMDALOG_PROTOCOL_WARN_TAG(@"Heimdallr", @"Alog zip file delete failed after zip failed. zipFileName: %@, removeError: %@", zipPath, removeError);
                    }
                } else {
                    HMDALOG_PROTOCOL_WARN_TAG(@"Heimdallr", @"Alog zip file not found after zip failed. zipFileName: %@", zipPath);
                }
                if (callback) {
                    callback(NO, 0);
                }
    
                dispatch_semaphore_signal(self.uploadSemaphore);
                
                HMDAlogUploadGlobalBlock block = self.uploadGlobalBlock;
                if (block) {
                    block(fetchStartTime, fetchEndTime, scene, instanceName, 0, HMDAlogUploadFailedCompressFailed);
                }
                
                NSDictionary *metrics = @{@"count": @(logFiles.count), @"uploadQueneWaitCost": @(uploadQueneWaitCost), @"fileProcessCost": @(fileProcessCost)};
                NSDictionary *dimension = @{@"status": @"0", @"reason": @"compress_failed", @"activateManner": manner, @"uploadFileType": uploadFileType};
                [HMDMonitorService trackService:kEventALogUpload metrics:metrics dimension:dimension extra:extra syncWrite:YES];
                HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"Alog file zip failed, activateManner: manual, count: %lu", logFiles.count);
                return;
            }
        } else {
            HMDALOG_PROTOCOL_WARN_TAG(@"Heimdallr", @"Alog zip file has existed. zipFileName: %@", zipPath);
        }
        
        // 启动上传
        NSTimeInterval uploadCost = [[NSDate date] timeIntervalSince1970] - uploadStartTime;
        HMDFileUploader *uploader = [HMDFileUploader sharedInstance];
        NSDictionary *commonParams = [HMDInjectedInfo defaultInfo].alogUploadCommonParams;
        if ([uploader respondsToSelector:@selector(uploadFileWithRequest:)]) {
            HMDFileUploadRequest *request = [[HMDFileUploadRequest alloc] init];
            request.filePath = zipPath;
            request.commonParams = commonParams;
            request.logType = @"alog";
            request.scene = scene;
            request.byUser = byUser;
#if RANGERSAPM
            if ([scene isEqualToString:@"crash"]) {
                request.path = [HMDURLSettings cloudCommandUploadPath];
            } else {
                request.path = [HMDURLSettings fileUploadPath];
            }
#endif
            request.finishBlock = ^(BOOL uploadSuccess, id jsonObject) {
                NSDictionary *result = [(NSDictionary *)jsonObject hmd_dictForKey:@"result"];
                NSInteger statusCode = [(NSDictionary *)jsonObject hmd_intForKey:@"status_code"];
                hmd_update_server_checker(HMDReporterALog, result, statusCode);
                
                NSString *logID;
                NSMutableDictionary *extraWithResponse = [NSMutableDictionary dictionaryWithDictionary:extra];
                if ([(NSDictionary *)jsonObject hmd_hasKey:@"X-Tt-Logid"]) {
                    logID = [(NSDictionary *)jsonObject hmd_stringForKey:@"X-Tt-Logid"];
                    [extraWithResponse hmd_setObject:logID forKey:@"X-Tt-Logid"];
                }
                
                // rate_limit_message对应value有值就算容灾
                BOOL isRateLimit = NO;
                NSString *rateLimitMsg = [result hmd_stringForKey:@"rate_limit_message"];
                if (rateLimitMsg && rateLimitMsg.length > 0) {
                    uploadSuccess = NO;
                    isRateLimit = YES;
                }
                
                if (callback) {
                    callback(uploadSuccess, logFiles.count);
                }
                
                // Unneccessary to remove file on a new thread since this request isn't running on main thread.
                NSError *removeError = nil;
                if ([[NSFileManager defaultManager] fileExistsAtPath:zipPath]) {
                    [[NSFileManager defaultManager] removeItemAtPath:zipPath error:&removeError];
                    
                    if (removeError != nil) {
                        HMDALOG_PROTOCOL_WARN_TAG(@"Heimdallr", @"Alog zip file delete failed after upload success. zipFileName: %@, removeError: %@", zipPath, removeError);
                    }
                } else {
                    HMDALOG_PROTOCOL_WARN_TAG(@"Heimdallr", @"Alog zip file not found after upload success. zipFileName: %@", zipPath);
                }
                
                //if both uploader upload success, remove the original alog files,otherwise may cause duplication problem
                if (uploadSuccess) {
                    for (NSString *path in logFiles) {
                        if ([instanceName isEqualToString:defaultInstanceName]) {
                            alog_remove_file(path.UTF8String);
                        } else {
                            alog_remove_file_instance(instanceName.UTF8String, path.UTF8String);
                        }
                    }
                }
                
                dispatch_semaphore_signal(self.uploadSemaphore);
                
                HMDAlogUploadGlobalBlock block = self.uploadGlobalBlock;
                if (block) {
                    HMDAlogUploadStatus uploadStatus = uploadSuccess ? HMDAlogUploadSuccess : (isRateLimit ? HMDAlogUploadFailedRateLimit : HMDAlogUploadFailedOthers);
                    block(fetchStartTime, fetchEndTime, scene, instanceName, logFiles.count, uploadStatus);
                }
                
                NSString *status = uploadSuccess ? @"200" : @"0";
                NSString *reason = uploadSuccess ? @"success" : (isRateLimit ? @"rateLimit" : @"upload_failed");
                NSDictionary *metrics = @{@"count": @(logFiles.count), @"uploadQueneWaitCost": @(uploadQueneWaitCost), @"fileProcessCost": @(fileProcessCost), @"uploadCost": @(uploadCost)};
                NSDictionary *dimension = @{@"status": status, @"reason": reason, @"activateManner": manner, @"uploadFileType": uploadFileType};
                [HMDMonitorService trackService:kEventALogUpload metrics:metrics dimension:dimension extra:[extraWithResponse copy] syncWrite:YES];
                if (!uploadSuccess) {
                    HMDALOG_PROTOCOL_WARN_TAG(@"Heimdallr", @"Alog file upload failed, activateManner : manual, count : %lu", logFiles.count);
                    [HMDDebugLogger printLog:@"Manually upload ALog failed"];
                }
            };
            [uploader uploadFileWithRequest:request];
        }
    } else {
        if (callback) {
            callback(NO, 0);
        }

        dispatch_semaphore_signal(self.uploadSemaphore);
        
        HMDAlogUploadGlobalBlock block = self.uploadGlobalBlock;
        if (block) {
            block(fetchStartTime, fetchEndTime, scene, instanceName, 0, HMDAlogUploadFailedAlogNotFount);
        }
        
        NSDictionary *metrics = @{@"uploadQueneWaitCost": @(uploadQueneWaitCost)};
        NSDictionary *dimension = @{@"status": @"0", @"reason": @"alog_file_not_found", @"activateManner": manner, @"uploadFileType": uploadFileType};
        [HMDMonitorService trackService:kEventALogUpload metrics:metrics dimension:dimension extra:extra syncWrite:YES];
        HMDALOG_PROTOCOL_WARN_TAG(@"Heimdallr", @"Alog file not found, activateManner: manual, count: %lu", logFiles.count);
    }
}

- (long)_maxUploadFileCount:(NSString *)scene {
#if RANGERSAPM
    // 崩溃最多上报两个文件，为了控制量级
    return [scene isEqualToString:@"crash"] ? 2 : LONG_MAX;
#else
    return LONG_MAX;
#endif
}

#pragma mark - Upload

- (void)uploadLastFeedbackAlogBeforeTime:(NSTimeInterval)endTime {
    [self uploadLastFeedbackAlogBeforeTime:endTime
                              instanceName:defaultInstanceName];
}

- (void)uploadLastFeedbackAlogBeforeTime:(NSTimeInterval)endTime
                            instanceName:(NSString *)instanceName {
    [self _uploadLastALogAsyncBeforeTime:endTime instanceName:instanceName byUser:YES];
}

- (void)uploadLastAlogBeforeTime:(NSTimeInterval)endTime {
    [self uploadLastAlogBeforeTime:endTime instanceName:defaultInstanceName];
}

- (void)uploadLastAlogBeforeTime:(NSTimeInterval)endTime
                    instanceName:(NSString *)instanceName {
    [self _uploadLastALogAsyncBeforeTime:endTime instanceName:instanceName byUser:NO];
}

- (void)_uploadLastALogAsyncBeforeTime:(NSTimeInterval)endTime
                          instanceName:(NSString * _Nullable)instanceName
                                byUser:(BOOL)byUser {
    NSTimeInterval uploadStartTime = [[NSDate date] timeIntervalSince1970];
    NSDictionary *extra = @{@"endTime":@(endTime)};
    [HMDMonitorService trackService:kEventALogUploadStart metrics:nil dimension:nil extra:extra syncWrite:YES];
    
    @weakify(self);
    dispatch_async(self.uploadQueue, ^{
        @strongify(self);
        [self _uploadLastALogBeforeTime:endTime
                                  scene:@"upload"
                                 manner:@"manual"
                           instanceName:instanceName
                                 byUser:byUser
                        uploadStartTime:uploadStartTime];
    });
}

- (void)_uploadLastALogBeforeTime:(NSTimeInterval)endTime
                            scene:(NSString * _Nonnull)scene
                           manner:(NSString * _Nonnull)manner
                     instanceName:(NSString * _Nonnull)instanceName
                           byUser:(BOOL)byUser
                  uploadStartTime:(NSTimeInterval)uploadStartTime {
    dispatch_semaphore_wait(self.uploadSemaphore, DISPATCH_TIME_FOREVER);
    NSTimeInterval uploadQueneWaitCost = [[NSDate date] timeIntervalSince1970] - uploadStartTime;
    
    NSString *uploadFileType = @".alog";
    NSDictionary *extra = @{@"instanName": instanceName ?: @"unknown", @"scene":scene, @"fetchEndTime":@(endTime)};
    
    if (!instanceName) {
        dispatch_semaphore_signal(self.uploadSemaphore);
        
        HMDAlogUploadGlobalBlock block = self.uploadGlobalBlock;
        if (block) {
            block(endTime, endTime, scene, @"", 0, HMDAlogUploadFailedInstanceNameNil);
        }
        
        NSDictionary *dimension = @{@"status": @"0", @"reason": @"alog instance not assigned", @"activateManner": manner};
        [HMDMonitorService trackService:@"slardar_alog_upload" metrics:nil dimension:dimension extra:extra syncWrite:YES];
        HMDALOG_PROTOCOL_WARN_TAG(@"Heimdallr", @"Disables uploading files so hmd can't upload alog.");
        return;
    }
    
    // Don't check FileStopUpload when real users send requests.
    if (!byUser && ![HMDInjectedInfo defaultInfo].canUploadFile) {
        dispatch_semaphore_signal(self.uploadSemaphore);
        
        HMDAlogUploadGlobalBlock block = self.uploadGlobalBlock;
        if (block) {
            block(endTime, endTime, scene, instanceName, 0, HMDAlogUploadFailedFileStopUploadByHost);
        }
        
        NSDictionary *metrics = @{@"uploadQueneWaitCost": @(uploadQueneWaitCost)};
        NSDictionary *dimension = @{@"status": @"0", @"reason": @"fileStopUpload", @"activateManner": manner, @"uploadFileType": uploadFileType};
        [HMDMonitorService trackService:kEventALogUpload metrics:metrics dimension:dimension extra:extra syncWrite:YES];
        HMDALOG_PROTOCOL_WARN_TAG(@"Heimdallr", @"Disables uploading files so hmd can't upload alog.");
        return;
    }
    
    if (!hmd_is_server_available(HMDReporterALog)) {
        dispatch_semaphore_signal(self.uploadSemaphore);
        
        HMDAlogUploadGlobalBlock block = self.uploadGlobalBlock;
        if (block) {
            block(endTime, endTime, scene, instanceName, 0, HMDAlogUploadFailedServerUnavailable);
        }
        
        NSDictionary *metrics = @{@"uploadQueneWaitCost": @(uploadQueneWaitCost)};
        NSDictionary *dimension = @{@"status": @"0", @"reason": @"server_unavailable", @"activateManner": manner, @"uploadFileType": uploadFileType};
        [HMDMonitorService trackService:kEventALogUpload metrics:metrics dimension:dimension extra:extra syncWrite:YES];
        HMDALOG_PROTOCOL_WARN_TAG(@"Heimdallr", @"Server disables uploading alog file.");
        return;
    }
    
    // check allow upload by host
    HMDForbidAllowAlogUploadBlock block = self.forbidAlogUploadBlock;
    if (block && block(scene)) {
        dispatch_semaphore_signal(self.uploadSemaphore);
        
        HMDAlogUploadGlobalBlock block = self.uploadGlobalBlock;
        if (block) {
            block(endTime, endTime, scene, instanceName, 0, HMDAlogUploadFailedAlogStopUploadByHost);
        }
        
        NSDictionary *metrics = @{@"uploadQueneWaitCost": @(uploadQueneWaitCost)};
        NSDictionary *dimension = @{@"status": @"0", @"reason": @"forbidden_according_secne_by_host", @"activateManner": manner, @"uploadFileType": uploadFileType};
        [HMDMonitorService trackService:kEventALogUpload metrics:metrics dimension:dimension extra:extra syncWrite:YES];
        HMDALOG_PROTOCOL_WARN_TAG(@"Heimdallr", @"Alog upload is forbidden by host according to scene. scene = %@", scene);
        return;
    }
    
    NSTimeInterval fileProcessStartTime = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval fetchEndTime = endTime;
    // fetch all alog files end to crashTime, the first one is the newest
    NSTimeInterval fetchStartTime = 0;
    // 把缓存数据写入文件
    if ([instanceName isEqualToString:defaultInstanceName]) {
        alog_flush_sync();
    } else {
        alog_flush_instance(instanceName.UTF8String);
    }
    // 获取满足要求的文件路径
    std::vector<std::string> filePathArray;
    if ([instanceName isEqualToString:defaultInstanceName]) {
        alog_getFilePaths(fetchStartTime, fetchEndTime, filePathArray);
    } else {
        alog_getFilePaths_instance(instanceName.UTF8String, fetchStartTime, fetchEndTime, filePathArray);
    }
    NSTimeInterval fileProcessCost = [[NSDate date] timeIntervalSince1970] - fileProcessStartTime;
    
    if (filePathArray.size() == 0) {
        dispatch_semaphore_signal(self.uploadSemaphore);
        
        HMDAlogUploadGlobalBlock block = self.uploadGlobalBlock;
        if (block) {
            block(endTime, endTime, scene, instanceName, 0, HMDAlogUploadFailedAlogNotFount);
        }
        
        NSDictionary *metrics = @{@"uploadQueneWaitCost": @(uploadQueneWaitCost), @"fileProcessCost": @(fileProcessCost)};
        NSDictionary *dimension = @{@"status": @"0", @"reason": @"alog_file_not_found", @"activateManner": manner, @"uploadFileType": uploadFileType};
        [HMDMonitorService trackService:kEventALogUpload metrics:metrics dimension:dimension extra:extra syncWrite:YES];
        HMDALOG_PROTOCOL_WARN_TAG(@"Heimdallr", @"Alog file not found.");
        return;
    }
    
    std::string newestPath = filePathArray.front();
    NSString *alogPath = [NSString stringWithCString:newestPath.c_str()
                                            encoding:[NSString defaultCStringEncoding]];
    if (alogPath == nil) {
        dispatch_semaphore_signal(self.uploadSemaphore);
        
        HMDAlogUploadGlobalBlock block = self.uploadGlobalBlock;
        if (block) {
            block(endTime, endTime, scene, instanceName, 0, HMDAlogUploadFailedAlogNotFount);
        }
        
        NSDictionary *metrics = @{@"uploadQueneWaitCost": @(uploadQueneWaitCost), @"fileProcessCost": @(fileProcessCost)};
        NSDictionary *dimension = @{@"status": @"0", @"reason": @"alog_file_not_found", @"activateManner": manner, @"uploadFileType": uploadFileType};
        [HMDMonitorService trackService:kEventALogUpload metrics:metrics dimension:dimension extra:extra syncWrite:YES];
        HMDALOG_PROTOCOL_WARN_TAG(@"Heimdallr", @"Alog file not found.");
        return;
    }
    
    NSTimeInterval uploadCost = [[NSDate date] timeIntervalSince1970] - uploadStartTime;
    NSDictionary *commonParams = [HMDInjectedInfo defaultInfo].alogUploadCommonParams;
    [self _uploadALogFileAtPath:alogPath
                          scene:scene
                         manner:manner
                   instanceName:instanceName
                         byUser:byUser
                   commonParams:commonParams
                     retryCount:0
            uploadQueneWaitCost:uploadQueneWaitCost
                fileProcessCost:fileProcessCost
                     uploadCost:uploadCost
                        endTime:endTime];
}

- (void)_uploadALogFileAtPath:(NSString * _Nonnull)alogPath
                        scene:(NSString * _Nonnull)scene
                       manner:(NSString * _Nonnull)manner
                 instanceName:(NSString * _Nonnull)instanceName
                       byUser:(BOOL)byUser
                 commonParams:(NSDictionary * _Nonnull)commonParams
                   retryCount:(NSUInteger)retryCount
          uploadQueneWaitCost:(NSTimeInterval)uploadQueneWaitCost
              fileProcessCost:(NSTimeInterval)fileProcessCost
                   uploadCost:(NSTimeInterval)uploadCost
                      endTime:(NSTimeInterval) endTime{
    NSString *uploadFileType = @".alog";
    NSDictionary *extra = @{@"instanName": instanceName, @"scene": scene};
    
    // must check again since there is retry strategy
    if (!hmd_is_server_available(HMDReporterALog)) {
        dispatch_semaphore_signal(self.uploadSemaphore);
        
        HMDAlogUploadGlobalBlock block = self.uploadGlobalBlock;
        if (block) {
            block(endTime, endTime, scene, instanceName, 0, HMDAlogUploadFailedServerUnavailable);
        }
        
        NSDictionary *metrics = @{@"uploadQueneWaitCost": @(uploadQueneWaitCost), @"fileProcessCost": @(fileProcessCost), @"uploadCost": @(uploadCost)};
        NSDictionary *dimension = @{@"status": @"0", @"reason": @"server_unavailable", @"activateManner": manner, @"uploadFileType": uploadFileType};
        [HMDMonitorService trackService:kEventALogUpload metrics:metrics dimension:dimension extra:extra syncWrite:YES];
        HMDALOG_PROTOCOL_WARN_TAG(@"Heimdallr", @"Server disables uploading alog file.");
        return;
    }
    
    HMDFileUploader *uploader = [HMDFileUploader sharedInstance];
    if ([uploader respondsToSelector:@selector(uploadFileWithRequest:)]) {
        HMDFileUploadRequest *request = [[HMDFileUploadRequest alloc] init];
        request.filePath = alogPath;
        request.commonParams = commonParams;
        request.logType = @"alog";
        request.scene = scene;
        request.byUser = byUser;
        request.finishBlock = ^(BOOL success, id jsonObject) {
            NSDictionary *result = [(NSDictionary *)jsonObject hmd_dictForKey:@"result"];
            NSInteger statusCode = [(NSDictionary *)jsonObject hmd_intForKey:@"status_code"];
            hmd_update_server_checker(HMDReporterALog, result, statusCode);
            
            NSString *logID;
            NSMutableDictionary *extraWithResponse = [NSMutableDictionary dictionaryWithDictionary:extra];
            if ([(NSDictionary *)jsonObject hmd_hasKey:@"X-Tt-Logid"]) {
                logID = [(NSDictionary *)jsonObject hmd_stringForKey:@"X-Tt-Logid"];
                [extraWithResponse hmd_setObject:logID forKey:@"X-Tt-Logid"];
            }
            
            BOOL isRateLimit = NO;
            NSString *rateLimitMsg = [result hmd_stringForKey:@"rate_limit_message"];
            if (rateLimitMsg && rateLimitMsg.length > 0) {
                success = NO;
                isRateLimit = YES;
            }
            
            // release semaphore in case blocking external calling thread
            dispatch_semaphore_signal(self.uploadSemaphore);
            
            if (success) {
                //remove the original alog files,otherwise may cause duplication problem
                if ([instanceName isEqualToString:defaultInstanceName]) {
                    alog_remove_file(alogPath.UTF8String);
                } else {
                    alog_remove_file_instance(instanceName.UTF8String, alogPath.UTF8String);
                }
                
                HMDAlogUploadGlobalBlock block = self.uploadGlobalBlock;
                if (block) {
                    block(endTime, endTime, scene, instanceName, 1, HMDAlogUploadSuccess);
                }
                
                NSDictionary *metrics = @{@"uploadQueneWaitCost": @(uploadQueneWaitCost), @"fileProcessCost": @(fileProcessCost), @"uploadCost": @(uploadCost)};
                NSDictionary *dimension = @{@"status": @"200", @"reason": @"success", @"activateManner": manner, @"uploadFileType": uploadFileType};
                [HMDMonitorService trackService:kEventALogUpload metrics:metrics dimension:dimension extra:[extraWithResponse copy] syncWrite:YES];
            } else {
                if (!isRateLimit && retryCount <= 3) {
                    //失败10s后重试
                    @weakify(self);
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), self.uploadQueue, ^{
                        @strongify(self);
                        dispatch_semaphore_wait(self.uploadSemaphore, DISPATCH_TIME_FOREVER);
                        [self _uploadALogFileAtPath:alogPath
                                              scene:scene
                                             manner:manner
                                       instanceName:instanceName
                                             byUser:byUser
                                       commonParams:commonParams
                                         retryCount:retryCount + 1
                                uploadQueneWaitCost:uploadQueneWaitCost
                                    fileProcessCost:fileProcessCost
                                         uploadCost:uploadCost
                                            endTime:endTime];
                    });
                } else {
                    
                    HMDAlogUploadGlobalBlock block = self.uploadGlobalBlock;
                    if (block) {
                        HMDAlogUploadStatus uploadStatus = isRateLimit ? HMDAlogUploadFailedRateLimit : HMDAlogUploadFailedOthers;
                        block(endTime, endTime, scene, instanceName, 1, uploadStatus);
                    }
                    
                    NSString *reason = isRateLimit ? @"rateLimit" : @"upload_failed";
                    NSDictionary *metrics = @{@"uploadQueneWaitCost": @(uploadQueneWaitCost), @"fileProcessCost": @(fileProcessCost), @"uploadCost": @(uploadCost)};
                    NSDictionary *dimension = @{@"status": @"0", @"reason": reason, @"activateManner": manner, @"uploadFileType": uploadFileType};
                    [HMDMonitorService trackService:kEventALogUpload metrics:metrics dimension:dimension extra:[extraWithResponse copy] syncWrite:YES];
                }
                HMDALOG_PROTOCOL_WARN_TAG(@"Heimdallr", @"Alog file upload failed, activateManner : crash, retryCount : %lu", retryCount);
            }
        };
        [uploader uploadFileWithRequest:request];
    }
}

- (void)uploadAlogIfCrashed {
    self.shouldUploadAlogIfCrashed = YES;
}

- (void)uploadAlogIfCrashedWithTime:(NSUInteger)second {
    self.shouldUploadAlogIfCrashed = YES;
    if (second > 0) {
        self.crashUploadSecond = second;
    }
}

#pragma mark - Private Dynamic Methods

- (void)crashALogUploadWithEndTime:(NSTimeInterval)endTime {
    NSTimeInterval uploadStartTime = [[NSDate date] timeIntervalSince1970];
    
    @weakify(self);
    dispatch_async(self.uploadQueue, ^{
        @strongify(self);
        NSString *scene = @"crash";
        NSString *manner = @"crash";
        
        if (![HMDInjectedInfo defaultInfo].canUploadCrash) {
            NSDictionary *dimension = @{@"status": @"0", @"reason": @"crashStopUpload", @"activateManner": manner};
            NSDictionary *extra = @{@"scene": scene, @"fetchEndTime": @(endTime)};
            [HMDMonitorService trackService:kEventALogUpload metrics:nil dimension:dimension extra:extra syncWrite:YES];
            HMDALOG_PROTOCOL_WARN_TAG(@"Heimdallr", @"Disables uploading crash so hmd can't upload alog.");
            return;
        }
        
        if (self.crashUploadSecond > 0) {
            NSTimeInterval fetchStartTime = endTime - self.crashUploadSecond;
            [self _reportALogAsyncWithScene:scene
                               instanceName:defaultInstanceName
                                     byUser:NO
                             fetchStartTime:fetchStartTime
                               fetchEndTime:endTime
                                   callback:nil];
            
        } else {
            [self _uploadLastALogBeforeTime:endTime
                                      scene:scene
                                     manner:manner
                               instanceName:defaultInstanceName
                                     byUser:NO
                            uploadStartTime:uploadStartTime];
        }
    });
}

- (void)exceptionALogUploadWithEndTime:(NSTimeInterval)endTime {
    NSTimeInterval uploadStartTime = [[NSDate date] timeIntervalSince1970];
    
    @weakify(self);
    dispatch_async(self.uploadQueue, ^{
        @strongify(self);
        NSString *scene = @"exception";
        NSString *manner = @"exception";
        
        if (![HMDInjectedInfo defaultInfo].canUploadException) {
            NSDictionary *dimension = @{@"status": @"0", @"reason": @"exceptionStopUpload", @"activateManner": manner};
            NSDictionary *extra = @{@"scene": scene, @"fetchEndTime": @(endTime)};
            [HMDMonitorService trackService:kEventALogUpload metrics:nil dimension:dimension extra:extra syncWrite:YES];
            HMDALOG_PROTOCOL_WARN_TAG(@"Heimdallr", @"Disables uploading exception so hmd can't upload alog.");
            return;
        }
        
        [self _uploadLastALogBeforeTime:endTime
                                  scene:scene
                                 manner:manner
                           instanceName:defaultInstanceName
                                 byUser:NO
                        uploadStartTime:uploadStartTime];
    });
}

@end
