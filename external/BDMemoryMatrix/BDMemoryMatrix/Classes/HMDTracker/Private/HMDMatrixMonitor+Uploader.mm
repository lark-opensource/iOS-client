//
//  HMDMatrixMonitor+Uploader.m
//  BDMemoryMatrix
//
//  Created by YSurfer on 2023/9/12.
//

#import "HMDMatrixMonitor+Uploader.h"
#import "memory_logging.h"
#import <Heimdallr/NSDictionary+HMDSafe.h>
#import <Heimdallr/HMDMemoryUsage.h>
#import <Heimdallr/HMDDiskUsage.h>
#import <Heimdallr/HMDSessionTracker.h>
#import <Heimdallr/HMDTracker.h>
#import <Heimdallr/HeimdallrUtilities.h>
#import <Heimdallr/HMDUploadHelper.h>
#import <Heimdallr/HMDFileUploader.h>
#import <BDAlogProtocol/BDAlogProtocol.h>
#import <Heimdallr/HMDALogProtocol.h>
#import <Heimdallr/HMDUserDefaults.h>
#import <Heimdallr/HMDLogUploader.h>
#import <Heimdallr/NSDictionary+HMDSafe.h>
#import <Heimdallr/NSArray+HMDSafe.h>
#import <Heimdallr/HMDDynamicCall.h>

static NSString *const ExceptionScene = @"oom_matrix";///oom、crash、内存压力警告情况下上报参数(⚠️不可修改，后端会通过该字段的值分别处理数据)
static NSString *const MemoryGraphScene = @"memorygraph_matrix";
static NSString *const CustomScene = @"custom_matrix";
static NSString *const kHMDMatrixUploadedCounter = @"kHMDMatrixUploadedCounter";
const char *KALOGMemoryInstance = "KALOGMemoryInstance";
static const NSUInteger maxUploadTimes = 3;
NSString *KHMDMatrixZipFileExtension = @"dat";//matrix原始数据后缀
NSString *KHMDMatrixEnvFileExtension = @"env";//session参数数据的后缀，包含有可用内存、可用磁盘、filters等信息

@implementation HMDMatrixMonitor (Uploader)

#pragma  mark - Matrix ALog Instance Upload

- (void)uploadMatrixAlog {
    NSDictionary *latestSessionDic = [HMDSessionTracker latestSessionDicAtLastLaunch];
    NSTimeInterval uploadStartTime = [latestSessionDic hmd_doubleForKey:@"timestamp"];
    NSTimeInterval uploadEndTime = uploadStartTime + [latestSessionDic hmd_doubleForKey:@"duration"];
    NSString *matrixInstance = [[NSString alloc] initWithUTF8String:KALOGMemoryInstance];
    [[HMDLogUploader sharedInstance] reportALogByUsersWithFetchStartTime:uploadStartTime
                                                            fetchEndTime:uploadEndTime
                                                                   scene:@"LynxMatrix"
                                                            instanceName:matrixInstance
                                                      reportALogCallback:NULL];
}

#pragma mark - Get Matrix Path

+ (NSString *)matrixUploadRootPath {
    NSString *heimdallrRootPath = [HeimdallrUtilities heimdallrRootPath];
    NSString *matrixRootPath = [heimdallrRootPath stringByAppendingPathComponent:@"Matrix"];
    return matrixRootPath;
}

+ (NSString *)matrixOfExceptionUploadPath {
    return [[self matrixUploadRootPath] stringByAppendingPathComponent:@"OOM"];
}

+ (NSString *)matrixOfMemoryGraphUploadPath {
    return [[self matrixUploadRootPath] stringByAppendingPathComponent:@"MemoryGraph"];
}

+ (NSString *)matrixOfCustomUploadPath {
    return [[self matrixUploadRootPath] stringByAppendingPathComponent:@"Custom"];
}

#pragma mark - Data Report

- (void)matrixOfMemoryGraphUpload
{
    NSString *rootPath = [[self class] matrixOfMemoryGraphUploadPath];
    NSString *logType = @"memory";
    NSString *scene = MemoryGraphScene;
    [self matrixIssueReportPath:rootPath type:logType scene:scene hasEnv:1];
}

- (void)matrixOfCustomUpload
{
    NSString *rootPath = [[self class] matrixOfCustomUploadPath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *fileArray = [fileManager contentsOfDirectoryAtPath:rootPath error:nil];
    NSString *sessionID = [HMDSessionTracker sharedInstance].eternalSessionID;
    for (int i = 0;i < fileArray.count; i++) {
        if (![fileArray[i] isEqualToString:sessionID]) {
            NSString *eventPath = [rootPath stringByAppendingPathComponent:fileArray[i]];
            NSString *logType = @"memory";
            NSString *scene = CustomScene;
            [self matrixIssueReportPath:eventPath type:logType scene:scene hasEnv:1];
        }
    }
}

- (void)matrixOfExceptionUpload
{
    NSString *rootPath = [[self class] matrixOfExceptionUploadPath];
    NSString *logType = @"memory";
    NSString *scene = ExceptionScene;
    [self matrixIssueReportPath:rootPath type:logType scene:scene hasEnv:1];
}

- (NSMutableDictionary *)checkEnvParamsWithIdentifier:(NSString *)identifier fileRootPath:(NSString *)rootPath {
    NSString *envFilePath = [rootPath stringByAppendingPathComponent:[identifier stringByAppendingPathExtension:KHMDMatrixEnvFileExtension]];
    if (![[NSFileManager defaultManager] fileExistsAtPath:envFilePath]) {
        return nil;
    }
    NSDictionary *envParams = [[NSDictionary alloc] initWithContentsOfFile:envFilePath];
    return [envParams mutableCopy];
}

- (void)increaseCounterWithIdentifier:(NSString *)identifier {
    NSMutableDictionary *counterDic = [self zipFileCounterDic];
    NSNumber *uploadedCount = [counterDic objectForKey:identifier];
    if (uploadedCount) {
        NSUInteger count = [uploadedCount unsignedIntegerValue] + 1;
        [counterDic setValue:@(count) forKey:identifier];
    }
    else {
        [counterDic setValue:@(1) forKey:identifier];
    }
    [[HMDUserDefaults standardUserDefaults] setObject:counterDic forKey:kHMDMatrixUploadedCounter];
}

- (BOOL)deleteZipFileIfNeedWithIdentifier:(NSString *)identifier filePath:rooPath {
    BOOL shouldDelete = NO;
    NSMutableDictionary *counterDic = [self zipFileCounterDic];
    NSNumber *uploadedCount = [counterDic objectForKey:identifier];
    if (uploadedCount && [uploadedCount unsignedIntegerValue] >= maxUploadTimes) {
        shouldDelete = YES;
        [counterDic removeObjectForKey:identifier];
        [[HMDUserDefaults standardUserDefaults] setObject:counterDic forKey:kHMDMatrixUploadedCounter];
        dispatch_async(dispatch_queue_create(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [[self class] cleanupIdentifier:identifier fileRootPath:rooPath];
        });
        HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"Matrix upload failed exceed max times : %lu, identifier : %@", maxUploadTimes, identifier);
    }
    
    return shouldDelete;
}

- (NSMutableDictionary *)zipFileCounterDic {
    NSMutableDictionary *zipFileCounterDic;
    NSDictionary *dic = [[HMDUserDefaults standardUserDefaults] dictForKey:kHMDMatrixUploadedCounter];
    if (dic) {
        zipFileCounterDic = [NSMutableDictionary dictionaryWithDictionary:dic];
    }
    else {
        zipFileCounterDic = [NSMutableDictionary dictionary];
    }
    
    return zipFileCounterDic;
}

+ (void)cleanupIdentifier:(NSString *)identifier fileRootPath:(NSString *)fileRootPath {
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *envFilePath = [fileRootPath stringByAppendingPathComponent:[identifier stringByAppendingPathExtension:KHMDMatrixEnvFileExtension]];
    NSString *zipFilePath = [fileRootPath stringByAppendingPathComponent:[identifier stringByAppendingPathExtension:KHMDMatrixZipFileExtension]];
    if ([manager fileExistsAtPath:zipFilePath]) {
        [manager removeItemAtPath:zipFilePath error:nil];
    }
    if ([manager fileExistsAtPath:envFilePath]) {
        [manager removeItemAtPath:envFilePath error:nil];
    }
}

- (void)cleanCounterWithIdentifier:(NSString *)identifier {
    NSMutableDictionary *counterDic = [self zipFileCounterDic];
    [counterDic removeObjectForKey:identifier?:@""];
    [[HMDUserDefaults standardUserDefaults] setObject:counterDic forKey:kHMDMatrixUploadedCounter];
}

- (NSArray <NSString *>*)fetchPendingMatrixIdentifiers:(NSString *)preparedUploadPath {
    NSFileManager *manager = [NSFileManager defaultManager];
    NSMutableArray *pendingIdentifiers = [NSMutableArray array];
    NSMutableArray *invalidFilePaths = [NSMutableArray array];
    if ([manager fileExistsAtPath:preparedUploadPath]) {
        NSArray<NSString *> *filePaths = [manager contentsOfDirectoryAtPath:preparedUploadPath error:nil];
        for (NSString *filePath in filePaths) {
            NSString *identifier = [filePath stringByDeletingPathExtension];
            if ([pendingIdentifiers containsObject:identifier]) {
                continue;
            }
            NSString *envFilePath = nil;
            NSString *zipFilePath = nil;
            if ([filePath.pathExtension isEqualToString:KHMDMatrixZipFileExtension]) {
                zipFilePath = filePath;
                envFilePath = [preparedUploadPath stringByAppendingPathComponent:[identifier stringByAppendingPathExtension:KHMDMatrixEnvFileExtension]];
                if ([manager fileExistsAtPath:envFilePath]) {
                    [pendingIdentifiers hmd_addObject:identifier];
                } else {
                    [invalidFilePaths hmd_addObject: [preparedUploadPath stringByAppendingPathComponent:filePath]];
                }
            } else if ([filePath.pathExtension isEqualToString:KHMDMatrixEnvFileExtension]) {
                envFilePath = filePath;
                zipFilePath = [preparedUploadPath stringByAppendingPathComponent:[identifier stringByAppendingPathExtension:KHMDMatrixZipFileExtension]];
                if ([manager fileExistsAtPath:zipFilePath]) {
                    [pendingIdentifiers hmd_addObject:identifier];
                } else {
                    [invalidFilePaths hmd_addObject:[preparedUploadPath stringByAppendingPathComponent:filePath]];
                }
            }
        }
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            for (NSString *filePath in invalidFilePaths) {
                if ([manager fileExistsAtPath:filePath]) {
                    [manager removeItemAtPath:filePath error:nil];
                }
            }
        });
    }
    return [pendingIdentifiers copy];
}

- (void)uploadFileByPath:(NSString*)rootPath objectIdentifier:(NSString*)identifier type:(NSString*)type scene:(NSString *)scene byUser:(BOOL)byUser params:(NSString *)params callback:(void (^)(BOOL succeed,NSDictionary *)) callback {
    NSMutableDictionary *body = [NSMutableDictionary dictionary];
    [body setValue:[HMDUploadHelper sharedInstance].headerInfo forKey:@"header"];
    
    NSMutableDictionary *envParams = [self checkEnvParamsWithIdentifier:identifier fileRootPath:rootPath];
    if (params != nil) {
        [envParams addEntriesFromDictionary:@{@"fileUuid":params}];
    }
    if (envParams) {
        [body setValue:envParams forKey:@"data"];
    } else {
        [body setValue:@{} forKey:@"data"];
    }
    
    HMDFileUploadRequest *request = [[HMDFileUploadRequest alloc] init];
    request.filePath = [rootPath stringByAppendingPathComponent:[identifier stringByAppendingPathExtension:KHMDMatrixZipFileExtension]];
    request.logType = type;
    request.scene = scene;
    request.commonParams = [body copy];
    request.byUser = byUser;
    request.path = @"/monitor/collect/c/ios_memory_matrix";
    request.finishBlock = ^(BOOL success, id jsonObject) {
        if (!success) {
            [self deleteZipFileIfNeedWithIdentifier:identifier filePath:rootPath];
            HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"Memory data upload failed");
        } else {
            HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"Memory data upload succeed");
        }
        if (callback) {
            callback(success,(NSDictionary *)jsonObject);
        }
    };
    
    [self increaseCounterWithIdentifier:identifier];
    
    [[HMDFileUploader sharedInstance] uploadFileWithRequest:request];
}

- (void)matrixIssueReportPath:(NSString *)rootPath type:(NSString *)type scene:(NSString *)scene hasEnv:(bool)hasEnvFile {
    dispatch_async(self.uploadQueue,^{
        NSFileManager *manager = [NSFileManager defaultManager];
        __weak typeof(self) weakself = self;
        if (![manager fileExistsAtPath:rootPath]) {
            return;
        }
        NSArray<NSString *> *fileIdentifiers = nil;///无后缀的fileName
        if (hasEnvFile) {
            NSArray<NSString *>* pendingIdentifiers = [self fetchPendingMatrixIdentifiers:rootPath];
            if (pendingIdentifiers.count <= 0) {
                return;
            } else {
                fileIdentifiers = [pendingIdentifiers copy];
            }
        } else {
            NSArray<NSString *> *filePaths = [manager contentsOfDirectoryAtPath:rootPath error:nil];
            if (filePaths.count == 0) {
                [manager removeItemAtPath:rootPath error:NULL];
                return;
            } else {
                NSMutableArray* pendingIdentifiers = [NSMutableArray array];
                for (NSString *filePath in filePaths) {
                    NSString *identifier = [filePath stringByDeletingPathExtension];
                    [pendingIdentifiers hmd_addObject:identifier];
                }
                fileIdentifiers = [pendingIdentifiers copy];
            }
        }
        
        [fileIdentifiers enumerateObjectsUsingBlock:^(NSString * _Nonnull identifier, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *params = nil;
            if ([scene isEqualToString:MemoryGraphScene]) {
                params = [identifier stringByDeletingPathExtension];//file_uuid
            }
            if (![self deleteZipFileIfNeedWithIdentifier:identifier filePath:rootPath]) {
                [self uploadFileByPath:rootPath objectIdentifier:identifier type:type scene:scene byUser:NO params:[params copy] callback:^(BOOL success, NSDictionary *jsonObject) {
                    NSString *reasonStr = success ? @"uploadSuccess" : @"uploadFail";
                    NSString *http_header_logid = [jsonObject hmd_stringForKey:@"http_header_logid"];
                    NSDictionary *category = @{@"status" : reasonStr, @"http_header_logid":http_header_logid ?: @"0"};
                    if ([scene isEqualToString:@"oom_matrix"]) {
                        DC_OB(DC_CL(HMDTTMonitor, heimdallrTTMonitor), hmdTrackService:metric:category:extra:syncWrite:, @"slardar_oom_matrix_upload", nil, category, nil, YES);
                    } else if ([scene isEqualToString:@"memorygraph_matrix"]) {
                        DC_OB(DC_CL(HMDTTMonitor, heimdallrTTMonitor), hmdTrackService:metric:category:extra:syncWrite:, @"slardar_memory_matrix_upload", nil, category, nil, YES);
                    } else {
                        DC_OB(DC_CL(HMDTTMonitor, heimdallrTTMonitor), hmdTrackService:metric:category:extra:syncWrite:, @"slardar_custom_matrix_upload", nil, category, nil, YES);
                    }
                    if (success) {
                        [weakself cleanCounterWithIdentifier:identifier];
                        [HMDMatrixMonitor cleanupIdentifier:identifier fileRootPath:rootPath];
                    }
                    dispatch_semaphore_signal(weakself.uploadSemaphore);
                }];
                dispatch_semaphore_wait(self.uploadSemaphore, DISPATCH_TIME_FOREVER);
            }
        }];
    });
}

#pragma mark - Remove All Pending Files
+ (void)removeAllFiles {
    NSString *filePath = [self matrixUploadRootPath];
    NSFileManager *manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:filePath]) {
        [manager removeItemAtPath:filePath error:nil];
    }
}

@end
