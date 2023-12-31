//
//  HMDMemoryGraphUploader.m
//  Heimdallr-iOS13.0
//
//  Created by fengyadong on 2020/3/2.
//

#import "HMDMemoryGraphUploader.h"
#if RANGERSAPM
#import "HMDMemoryGraphUploader+RangersAPMURLProvider.h"
#else
#import "HMDMemoryGraphUploader+HMDURLProvider.h"
#endif /* RANGERSAPM */
#import "HMDSessionTracker.h"
#import "HMDFileUploader.h"
#import "HeimdallrUtilities.h"
#import "HMDNetworkManager.h"
#import "HMDNetworkReqModel.h"
#import "HMDInjectedInfo.h"
#import "NSDictionary+HMDSafe.h"
#import "NSArray+HMDSafe.h"
#import "HMDUploadHelper.h"
#import "NSDictionary+HMDHTTPQuery.h"
#import "HMDDynamicCall.h"
#if RANGERSAPM
#import <MemoryGraphCaptureToB/AWEMemoryGraphGenerator.h>
#import "RangersAPMUploadHelper.h"
#else
#import <MemoryGraphCapture/AWEMemoryGraphGenerator.h>
#endif
#import "HMDALogProtocol.h"
#import "HMDUserDefaults.h"
#import "HMDGeneralAPISettings.h"
#import "Heimdallr+Private.h"
#import "HMDMemoryUsage.h"
#import "HMDDiskSpaceDistribution.h"
#import "pthread_extended.h"
#import "HMDMemoryGraphGenerator.h"
#import "HMDMemoryGraphConfig.h"
#import "HMDFileTool.h"
#import "HMDServiceContext.h"
// PrivateServices
#import "HMDDebugLogger.h"
#import "HMDServerStateService.h"
#import "HMDMonitorService.h"
#import "HMDURLManager.h"
#import "HMDURLSettings.h"
#import "HMDZipArchiveService.h"

#if RANGERSAPM
static NSString * const kEventMemoryGraphZip = @"memory_graph_zip";
static NSString * const kEventMemoryGraphUploadStart = @"memory_graph_upload_start";
static NSString * const kEventMemoryGraphUploadEnd = @"memory_graph_upload_end";
static NSString * const kEventMemoryGraphCheckServer = @"memory_graph_check_server";
#else
static NSString * const kEventMemoryGraphZip = @"slardar_memory_graph_zip";
static NSString * const kEventMemoryGraphUploadStart = @"slardar_memory_graph_upload_start";
static NSString * const kEventMemoryGraphUploadEnd = @"slardar_memory_graph_upload_end";
static NSString * const kEventMemoryGraphCheckServer = @"slardar_memory_graph_check_server";
#endif /* RANGERSAPM */

static NSString *const kHMDMemoryGrapthUploadedCounter = @"kHMDMemoryGrapthUploadedCounter";
static const NSUInteger maxUploadTimes = 3;
typedef void(^HMDMemoryGraphQuotaFinishBlock)(NSError *_Nullable,HMDServerState serverState);

@interface HMDMemoryGraphUploader ()<HMDInspectorDiskSpaceDistribution> {
    pthread_mutex_t _fileLock;
}

@property (nonatomic, strong) dispatch_queue_t uploadQueue;
@property (nonatomic, strong) dispatch_semaphore_t uploadSemaphore;

@end

@implementation HMDMemoryGraphUploader

- (instancetype)init {
    if (self = [super init]) {
        _uploadQueue = dispatch_queue_create("com.heimdallr.memorygraph.upload", DISPATCH_QUEUE_SERIAL);
        self.uploadSemaphore = dispatch_semaphore_create(0);
        mutex_init_normal(_fileLock);
        [[HMDDiskSpaceDistribution sharedInstance] registerModule:self];
    }
    
    return self;
}

- (void)asyncCheckAndUpload {
    dispatch_async(self.uploadQueue, ^{
        [self uploadMemoryGraphIfNeeded];
    });
}

- (void)uploadMemoryGraphIfNeeded {
    NSString *processingPath = [HMDMemoryGraphUploader memoryGraphProcessingPath];

    if (![[NSFileManager defaultManager] fileExistsAtPath:processingPath]) {
        return;
    }
    
    [self prepareOnProcessingDirectory];
    
    NSString *preparedPath = [HMDMemoryGraphUploader memoryGraphPreparedPath];
    long long preparedSize = folderSizeAtPath(preparedPath)/(1024*1024);
    HMDMemoryGraphConfig *config = (HMDMemoryGraphConfig *)[HMDMemoryGraphGenerator sharedGenerator].config;
    if (preparedSize > config.maxPreparedFolderSizeMB) {
        [self cleanPreparedFiles];
    }
    
    [self uploadPreparedFiles];
}

- (void)cleanPreparedFiles {
    NSString *preparedPath = [HMDMemoryGraphUploader memoryGraphPreparedPath];
    if([[NSFileManager defaultManager] fileExistsAtPath:preparedPath]){
        NSArray<NSString *> *filePaths = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:preparedPath error:nil];
        for (NSString *filePath in filePaths) {
            NSString *graphDirPath = [preparedPath stringByAppendingPathComponent:filePath];
            [[NSFileManager defaultManager] removeItemAtPath:graphDirPath error:nil];
        }
    }
    NSDictionary *counterDic = @{};
    [[HMDUserDefaults standardUserDefaults] setObject:counterDic forKey:kHMDMemoryGrapthUploadedCounter];
}

static long long folderSizeAtPath(NSString* folderPath){
    NSFileManager* manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:folderPath]) return 0;
    NSEnumerator *childFilesEnumerator = [[manager subpathsAtPath:folderPath] objectEnumerator];
    NSString* fileName;
    long long folderSize = 0;
    while ((fileName = [childFilesEnumerator nextObject]) != nil){
        NSString* fileAbsolutePath = [folderPath stringByAppendingPathComponent:fileName];
        BOOL isDirectory; BOOL isExist;
        isExist = [manager fileExistsAtPath:fileAbsolutePath isDirectory:&isDirectory];
        if (isExist && !isDirectory) {
            folderSize += [[manager attributesOfItemAtPath:fileAbsolutePath error:nil] fileSize];
        }
    }
    return  folderSize;
}

- (void)prepareOnProcessingDirectory {
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *processingPath = [HMDMemoryGraphUploader memoryGraphProcessingPath];
    NSString *preparedPath = [HMDMemoryGraphUploader memoryGraphPreparedPath];
    
    //必须先创建文件夹否则文件写入一定会失败
    if (![[NSFileManager defaultManager] fileExistsAtPath:preparedPath]) {
        hmdCheckAndCreateDirectory(preparedPath);
    }
    
    NSArray<NSString *> *filePaths = [manager contentsOfDirectoryAtPath:processingPath error:nil];
    for(NSString *filePath in filePaths) {
        NSString *graphDirPath = [processingPath stringByAppendingPathComponent:filePath];
        BOOL graphValid = [AWEMemoryGraphGenerator checkIfHasGraphUnderPath:graphDirPath];
        if(!graphValid) {
            [manager removeItemAtPath:graphDirPath error:nil];
            continue;
        }
        NSString *zipPath = [[[self class] memoryGraphPreparedPath] stringByAppendingPathComponent:[filePath stringByAppendingPathExtension:kHMDMemoryGraphZipFileExtension]];
        NSString *zipTmpName = [NSString stringWithFormat:@"%lld.tmp",(long long)([NSDate date].timeIntervalSince1970 * 1000)];
        NSString *zipTmpPath = [[[self class] memoryGraphPreparedPath] stringByAppendingPathComponent:zipTmpName];
        
        NSTimeInterval zipTimeStart = [[NSDate date] timeIntervalSince1970];
        BOOL zipValid = [self safeCreateZipFileAtPath:zipTmpPath withContentsOfDirectory:graphDirPath];
        NSTimeInterval zipTimeEnd = [[NSDate date] timeIntervalSince1970];
        
        if (zipValid) {
            if (rename(zipTmpPath.UTF8String, zipPath.UTF8String) == 0) {
                [manager removeItemAtPath:graphDirPath error:nil];
            }
        }
        else {
            [manager removeItemAtPath:zipTmpPath error:nil];
            NSDictionary *extra = @{@"identifier":filePath};
            NSDictionary *metric = @{@"duration":@(zipTimeEnd - zipTimeStart)};
#if RANGERSAPM
            NSDictionary *category = @{@"status":@"HMDMemoryGraphErrorTypeGraphZipError", @"reason":@"slardar_zip_memorygraph_raw_directory_error", @"activateManner":@"online"};
#else
            NSDictionary *category = @{@"status":@(HMDMemoryGraphErrorTypeGraphZipError), @"reason":@"slardar zip memorygraph raw directory error", @"activateManner":@"online"};
#endif
            [HMDMonitorService trackService:kEventMemoryGraphZip metrics:metric dimension:category extra:extra syncWrite:YES];
            HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"Memory graph zip is not valid, path : %@", graphDirPath);
        }
    }
}

- (void)uploadPreparedFiles {
    NSArray<NSString *>* pendingIdentifiers = [self fetchPendingIdentifiers];
    if(pendingIdentifiers.count <= 0) return;
    NSString *activateManner = @"online";
    [self checkServerStateWithPrepareCount:pendingIdentifiers.count activateManner:activateManner finishBlock:^(NSError *error) {
        if (!error) {
            [pendingIdentifiers enumerateObjectsUsingBlock:^(NSString * _Nonnull identifier, NSUInteger idx, BOOL * _Nonnull stop) {
                //如果zip上传失败达到maxUploadTimes，则会同时删除zip和env文件
                if (![self deleteZipFileIfNeedWithIdentifier:identifier]) {
                    //多个文件串行上报
                    [self internal_uploadIdentifier:identifier activateManner:activateManner finishBlock:^(NSError *error,HMDServerState serverState) {
                        if (!error) {
                            [self cleanCounterWithIdentifier:identifier];
                            [HMDMemoryGraphUploader cleanupIdentifier:identifier];
                        }
                        if(serverState == HMDServerStateDropAllData) {
                            *stop = YES;
                            for(NSUInteger i=idx+1;i<pendingIdentifiers.count;i++) {
                                [self cleanCounterWithIdentifier:pendingIdentifiers[i]];
                                [HMDMemoryGraphUploader cleanupIdentifier:pendingIdentifiers[i]];
                            }
                        }
                        dispatch_semaphore_signal(self.uploadSemaphore);
                    }];
                    dispatch_semaphore_wait(self.uploadSemaphore, DISPATCH_TIME_FOREVER);
                }
            }];
        }
    }];
}

- (NSArray <NSString *>*)fetchPendingIdentifiers {
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *preparedPath = [[self class] memoryGraphPreparedPath];
    NSString *curSessionID = [HMDSessionTracker sharedInstance].eternalSessionID;
    
    NSMutableArray *pendingIdentifiers = [NSMutableArray array];
    NSMutableArray *invalidFilePaths = [NSMutableArray array];
    
    if([manager fileExistsAtPath:preparedPath]){
        NSArray<NSString *> *filePaths = [manager contentsOfDirectoryAtPath:preparedPath error:nil];
        for(NSString *filePath in filePaths){
            if ([filePath hasSuffix:@".tmp"]) {
                NSString *path = [preparedPath stringByAppendingPathComponent:filePath];
                [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
                HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"memorygraph zip file not valid");
                continue;
            }
            
            NSString *identifier = [filePath stringByDeletingPathExtension];
            if ([pendingIdentifiers containsObject:identifier]) {
                continue;
            }
            
            //这里仅上报历史数据，不能包括本次启动期间的数据，否则可能会导致其中的某个文件被非预期的清理掉
            if ([identifier hasPrefix:curSessionID]) {
                continue;
            }
            
            NSString *envFilePath;
            NSString *zipFilePath;
            if ([filePath.pathExtension isEqualToString:kHMDMemoryGraphZipFileExtension] ) {
                zipFilePath = filePath;
                envFilePath = [preparedPath stringByAppendingPathComponent:[[zipFilePath stringByDeletingPathExtension] stringByAppendingPathExtension:kHMDMemoryGraphEnvFileExtension]];
                if ([manager fileExistsAtPath:envFilePath]) {
                    [pendingIdentifiers hmd_addObject:identifier];
                } else {
                    [invalidFilePaths hmd_addObject:[preparedPath stringByAppendingPathComponent:zipFilePath]];
                }
            } else if ([filePath.pathExtension isEqualToString:kHMDMemoryGraphEnvFileExtension] ) {
                envFilePath = filePath;
                zipFilePath = [preparedPath stringByAppendingPathComponent:[[envFilePath stringByDeletingPathExtension] stringByAppendingPathExtension:kHMDMemoryGraphZipFileExtension]];
                if ([manager fileExistsAtPath:zipFilePath]) {
                    [pendingIdentifiers hmd_addObject:identifier];
                } else {
                    [invalidFilePaths hmd_addObject:[preparedPath stringByAppendingPathComponent:envFilePath]];
                }
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
    
    return [pendingIdentifiers copy];
}

- (void)uploadIdentifier:(NSString *)identifier
          activateManner:(NSString *)activateManner
         needCheckServer:(BOOL)checkServer
             finishBlock:(HMDMemoryGraphFinishBlock)finishBlock {
    dispatch_block_t block = ^(){
        dispatch_async(self.uploadQueue, ^{
            [self internal_uploadIdentifier:identifier activateManner:activateManner finishBlock:^(NSError * _Nullable err,HMDServerState serverState) {
                dispatch_semaphore_signal(self.uploadSemaphore);
                if (finishBlock) finishBlock(err);
            }];
            dispatch_semaphore_wait(self.uploadSemaphore, DISPATCH_TIME_FOREVER);
        });
    };
    if (checkServer) {
        [self checkServerStateWithPrepareCount:1 activateManner:activateManner finishBlock:^(NSError * _Nullable error) {
            if (!error) {
                block();
            }else {
                if (finishBlock) {
                    finishBlock(error);
                }
            }
        }];
    }else {
        block();
    }
}

//内部方法，上报之前需要check服务端状态获得上报许可
- (void)internal_uploadIdentifier:(NSString *)identifier
                   activateManner:(nonnull NSString *)activateManner
                      finishBlock:(HMDMemoryGraphQuotaFinishBlock)finishBlock {
    if (!hmd_is_server_available(HMDReporterMemoryGraph)) {
        return;
    }
    
    NSString *preparedPath = [[self class] memoryGraphPreparedPath];
    NSString *zipFilePath = [preparedPath stringByAppendingPathComponent:[identifier stringByAppendingPathExtension:kHMDMemoryGraphZipFileExtension]];
    
    pthread_mutex_lock(&_fileLock);
    if(![[NSFileManager defaultManager] fileExistsAtPath:zipFilePath]) {
        NSError *error = [NSError errorWithDomain:@"MemoryGraph" code:HMDMemoryGraphErrorTypeGraphZipFileMissing userInfo:@{NSLocalizedFailureReasonErrorKey:@"slardar memorygraph zip file missing", NSLocalizedDescriptionKey:@"slardar memorygraph zip file missing"}];
        if (finishBlock) {
            finishBlock(error,HMDServerStateUnknown);
        }
        HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"%@, identifier : %@", error.localizedFailureReason, identifier);
        return;
    }
    
    NSDictionary *finalEnvParams = [HMDMemoryGraphUploader checkEnvParamsWithIdentifier:identifier];
    
    if(!finalEnvParams) {
        NSError *error = [NSError errorWithDomain:@"MemoryGraph" code:HMDMemoryGraphErrorTypeEnvFileInvalidMissing userInfo:@{NSLocalizedFailureReasonErrorKey:@"slardar memorygraph env file missing", NSLocalizedDescriptionKey:@"slardar memorygraph env file missing"}];
        if (finishBlock) {
            finishBlock(error,HMDServerStateUnknown);
        }
        HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"%@, identifier : %@", error.localizedFailureReason, identifier);
        return;
    }
    
    NSDictionary<NSFileAttributeKey, id> *zipAttributeDic = [[NSFileManager defaultManager] attributesOfItemAtPath:zipFilePath error:nil];
    hmd_MemoryBytes memoryBytes = hmd_getMemoryBytes();
    // zip文件进入内存后，会被copy到body中，所有需要有2倍的内存空间，需要满足加载zip文件后，至少还有100MB的可用内存空间才可以上传
    if ((zipAttributeDic && [zipAttributeDic fileSize] * 2 + 100 * HMD_MEMORY_MB > memoryBytes.availabelMemory)
        // 获取文件大小失败，直接验证可用内存至少还有250MB才能上传
        || (!zipAttributeDic && memoryBytes.availabelMemory < 250 * HMD_MEMORY_MB)) {
        
        NSError *error = [NSError errorWithDomain:@"MemoryGraph" code:HMDMemoryGraphErrorTypeNoMemorySpace userInfo:@{NSLocalizedFailureReasonErrorKey:@"slardar no memory space for memorygraph uploading", NSLocalizedDescriptionKey:@"slardar no memory space for memorygraph uploading"}];
        if (finishBlock) {
            finishBlock(error,HMDServerStateUnknown);
        }
        HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"%@, identifier : %@", error.localizedFailureReason, identifier);
        return;
    }
    NSDictionary *data = [finalEnvParams objectForKey:@"data"];
    NSDictionary *extra = @{@"identifier":identifier ?: @"unkonwn"};
    NSDictionary *category = @{@"activateManner":activateManner ?: @"unkonwn"};
    NSTimeInterval uploadTimeStart = [[NSDate date] timeIntervalSince1970];
    
    HMDFileUploadRequest *request = [HMDFileUploadRequest new];
    request.filePath = zipFilePath;
    request.logType = @"slardar_memory_graph";
    request.scene = activateManner;
    request.commonParams = [finalEnvParams copy];
    request.path = [HMDURLSettings memoryGraphUploadPath];
    request.finishBlock = ^(BOOL success,id jsonObject) {
        NSTimeInterval uploadTimeEnd = [[NSDate date] timeIntervalSince1970];
        NSError *error = nil;
        if (!success) {
            error = [NSError errorWithDomain:@"MemoryGraph" code:HMDMemoryGraphErrorTypeEnvUploadFail userInfo:@{NSLocalizedFailureReasonErrorKey:@"slardar file upload failed", NSLocalizedDescriptionKey:@"slardar file upload failed"}];
            [self deleteZipFileIfNeedWithIdentifier:identifier];
        }
        
        NSString *reasonStr = error ? error.localizedFailureReason : @"success";
        NSNumber *status = error ? [NSNumber numberWithInteger:error.code] : @(0);
        NSString *http_header_logid = [(NSDictionary *)jsonObject hmd_stringForKey:@"http_header_logid"];
        NSDictionary *categoryDic = @{@"status":status.stringValue, @"reason":reasonStr, @"activateManner":activateManner ?: @"unkonwn", @"http_header_logid":http_header_logid ?: @"0"};
        NSDictionary *metric = @{@"duration":@(uploadTimeEnd - uploadTimeStart)};
        [HMDMonitorService trackService:kEventMemoryGraphUploadEnd metrics:metric dimension:categoryDic extra:extra syncWrite:YES];
        NSDictionary *result = [(NSDictionary *)jsonObject hmd_dictForKey:@"result"];
        NSInteger statusCode = [(NSDictionary *)jsonObject hmd_intForKey:@"status_code"];
        HMDServerState serverState = hmd_update_server_checker(HMDReporterMemoryGraph, result, statusCode);
        if(finishBlock) finishBlock(error,serverState);
        if (success) {
            HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"Memory graph upload success");
            [HMDDebugLogger printLog:@"Upload MemoryGraph file successfully!"];
        }
        else {
            HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"Memory graph upload failed, identifier : %@, data : %@", identifier, data);
            [HMDDebugLogger printLog:@"Upload MemoryGraph file failed."];
        }
    };
    
    //记录上报次数
    [self increaseCounterWithIdentifier:identifier];
    
    HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"Memory graph uploading start");
    [HMDMonitorService trackService:kEventMemoryGraphUploadStart metrics:nil dimension:category extra:extra syncWrite:YES];
    [HMDDebugLogger printLog:@"MemoryGraph file is uploading..."];
    
    [[HMDFileUploader sharedInstance] uploadFileWithRequest:request];
    pthread_mutex_unlock(&_fileLock);
}

- (void)checkServerStateWithPrepareCount:(NSUInteger)prepareCount
                          activateManner:(NSString *)activateManner
                             finishBlock:(HMDMemoryGraphFinishBlock)finishBlock {
    NSString *requestURL = [HMDURLManager URLWithProvider:self forAppID:[HMDInjectedInfo defaultInfo].appID];
    if (requestURL == nil) {
        NSError *error = [NSError errorWithDomain:@"MemoryGraph" code:HMDMemoryGraphErrorTypeEnvUploadFail userInfo:@{NSLocalizedFailureReasonErrorKey:@"slardar memory upload check url is missing", NSLocalizedDescriptionKey:@"slardar memory upload check url is missing"}];
        if (finishBlock) {
            finishBlock(error);
        }
        return;
    }
    NSMutableDictionary *headerField = [NSMutableDictionary dictionary];
    [headerField hmd_setObject:@"application/json; encoding=utf-8" forKey:@"Content-Type"];
    [headerField hmd_setObject:@"application/json" forKey:@"Accept"];
#if RANGERSAPM
    headerField = [NSMutableDictionary dictionaryWithDictionary:[RangersAPMUploadHelper headerFieldsForAppID:[HMDInjectedInfo defaultInfo].appID withCustomHeaderFields:headerField]];
#endif
    
    NSMutableDictionary *queryParams = [NSMutableDictionary dictionaryWithDictionary:[HMDUploadHelper sharedInstance].headerInfo];
    [queryParams addEntriesFromDictionary:[HMDInjectedInfo defaultInfo].commonParams];
    [queryParams hmd_setObject:@(prepareCount) forKey:@"prepare_upload_count"];
    NSString *queryString = [queryParams hmd_queryString];
    requestURL = [NSString stringWithFormat:@"%@?%@", requestURL, queryString];
    
    HMDNetworkReqModel *reqModel = [HMDNetworkReqModel new];
    reqModel.requestURL = requestURL;
    reqModel.method = @"GET";
    reqModel.headerField = headerField.copy;
    reqModel.needEcrypt = [self shouldEncrypt];
    [[HMDNetworkManager sharedInstance] asyncRequestWithModel:reqModel callback:^(NSError *error, id jsonObj) {
        NSError *checkError = nil;
        NSDictionary *maybeDictionary = jsonObj;
        
        NSString * logid = [maybeDictionary hmd_stringForKey:@"x-tt-logid"];
        NSNumber *statusCode = [maybeDictionary hmd_objectForKey:@"status_code" class:NSNumber.class];
        
        BOOL shouldUpload = [[maybeDictionary hmd_dictForKey:@"result"] hmd_boolForKey:@"should_upload"];
        
        if (error) {
            checkError = error;
        }else if(!shouldUpload){
            checkError = [NSError errorWithDomain:@"MemoryGraph" code:HMDMemoryGraphErrorTypeHitServerLimit userInfo:@{NSLocalizedFailureReasonErrorKey:@"slardar memory upload check fail", NSLocalizedDescriptionKey:@"slardar memory upload check fail"}];
            [HMDDebugLogger printLog:@"Upload MemoryGraph -- server check failed."];
            statusCode = [NSNumber numberWithInteger:checkError.code];
        }
        
        if (finishBlock) {
            finishBlock(checkError);
        }
        
        NSString *reasonStr = checkError ? (checkError.localizedFailureReason?:@"fail") : @"success";
        NSDictionary *category = @{@"status":[statusCode stringValue]?:@"unkonwn", @"reason":reasonStr, @"activateManner":activateManner ?: @"unkonwn", @"logid":logid?:@"unkonwn"};
        NSDictionary *metric = @{@"count":@(prepareCount)};
        [HMDMonitorService trackService:kEventMemoryGraphCheckServer metrics:metric dimension:category extra:nil syncWrite:YES];
        
        if (error) {
            HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"Memory graph upload check http error : %@", error);
        } else if (!shouldUpload) {
            HMDALOG_PROTOCOL_WARN_TAG(@"Heimdallr", @"Memory graph upload check failed with prepare count : %lu", prepareCount);
        }
    }];
}

+ (void)cleanupIdentifier:(NSString *)identifier {
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *preparedPath = [self memoryGraphPreparedPath];
    NSString *envFilePath = [preparedPath stringByAppendingPathComponent:[identifier stringByAppendingPathExtension:kHMDMemoryGraphEnvFileExtension]];
    if ([manager fileExistsAtPath:envFilePath]) {
        [manager removeItemAtPath:envFilePath error:nil];
    }
    
    NSString *zipFilePath = [preparedPath stringByAppendingPathComponent:[identifier stringByAppendingPathExtension:kHMDMemoryGraphZipFileExtension]];
    if ([manager fileExistsAtPath:zipFilePath]) {
        [manager removeItemAtPath:zipFilePath error:nil];
    }
}

- (BOOL)safeCreateZipFileAtPath:(NSString *)path withContentsOfDirectory:(NSString *)directory {
    pthread_mutex_lock(&_fileLock);
    BOOL zipSuccessed = [HMDZipArchiveService createZipFileAtPath:path withContentsOfDirectory:directory];
    pthread_mutex_unlock(&_fileLock);
    return zipSuccessed;
}

#pragma mark - Util

+ (NSString *)memoryGraphRootPath {
    NSString *heimdallrRootPath = [HeimdallrUtilities heimdallrRootPath];
    NSString *memoryGraphRootPath = [heimdallrRootPath stringByAppendingPathComponent:@"MemoryGraph"];
    
    return memoryGraphRootPath;
}

+ (NSString *)memoryGraphProcessingPath {
    NSString *memoryGraphRootPath = [self memoryGraphRootPath];
    NSString *processingPath = [memoryGraphRootPath stringByAppendingPathComponent:@"Processing"];
    
    return processingPath;
}

+ (NSString *)memoryGraphPreparedPath {
    NSString *memoryGraphRootPath = [self memoryGraphRootPath];
    NSString *preparedPath = [memoryGraphRootPath stringByAppendingPathComponent:@"Prepared"];
    
    return preparedPath;
}

+ (NSDictionary *)checkEnvParamsWithIdentifier:(NSString*)identifier {
    NSString *preparedPath = [self memoryGraphPreparedPath];
    NSString *envFilePath = [preparedPath stringByAppendingPathComponent:[identifier stringByAppendingPathExtension:kHMDMemoryGraphEnvFileExtension]];
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:envFilePath]) {
        return nil;
    }
    
    NSDictionary *envParams = [[NSDictionary alloc] initWithContentsOfFile:envFilePath];
    NSMutableDictionary *finalEnvParams = [NSMutableDictionary dictionaryWithDictionary:envParams];
    NSMutableDictionary *data = [finalEnvParams objectForKey:@"data"];
    
    NSArray<NSString *>* parts = [identifier componentsSeparatedByString:@"_"];
    if (parts.count == 2) {
        NSString *sessionID = parts[0];
        [data hmd_setObject:sessionID forKey:@"internal_session_id"];
    }
    [finalEnvParams hmd_setObject:[data copy] forKey:@"data"];
    
    return finalEnvParams.copy;
}

#pragma mark - Counter

- (NSMutableDictionary *)zipFileCounterDic {
    NSMutableDictionary *zipFileCounterDic;
    NSDictionary *dic = [[HMDUserDefaults standardUserDefaults] dictForKey:kHMDMemoryGrapthUploadedCounter];
    if (dic) {
        zipFileCounterDic = [NSMutableDictionary dictionaryWithDictionary:dic];
    }
    else {
        zipFileCounterDic = [NSMutableDictionary dictionary];
    }
    
    return zipFileCounterDic;
}

- (BOOL)deleteZipFileIfNeedWithIdentifier:(NSString *)identifier {
    BOOL shouldDelete = NO;
    NSMutableDictionary *counterDic = [self zipFileCounterDic];
    NSNumber *uploadedCount = [counterDic objectForKey:identifier];
    if (uploadedCount && [uploadedCount unsignedIntegerValue] >= maxUploadTimes) {
        shouldDelete = YES;
        [counterDic removeObjectForKey:identifier];
        [[HMDUserDefaults standardUserDefaults] setObject:counterDic forKey:kHMDMemoryGrapthUploadedCounter];
        dispatch_async(dispatch_queue_create(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [[self class] cleanupIdentifier:identifier];
        });
        HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"Memory graph upload failed exceed max times : %lu, identifier : %@", maxUploadTimes, identifier);
    }
    
    return shouldDelete;
}

- (void)cleanCounterWithIdentifier:(NSString *)identifier {
    NSMutableDictionary *counterDic = [self zipFileCounterDic];
    [counterDic removeObjectForKey:identifier?:@""];
    [[HMDUserDefaults standardUserDefaults] setObject:counterDic forKey:kHMDMemoryGrapthUploadedCounter];
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
    
    [[HMDUserDefaults standardUserDefaults] setObject:counterDic forKey:kHMDMemoryGrapthUploadedCounter];
}

#pragma - mark HMDInspectorDiskSpaceDistribution

+ (NSString *)removableFileDirectoryPath {
    return [self memoryGraphRootPath];
}

- (BOOL)removeFileImmediately:(NSArray *)pathArr {
    pthread_mutex_lock(&_fileLock);
    BOOL success = YES;
    for (NSString *path in pathArr) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            success = success & [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
        }
    }
    pthread_mutex_unlock(&_fileLock);
    
    return success;
}

@end
