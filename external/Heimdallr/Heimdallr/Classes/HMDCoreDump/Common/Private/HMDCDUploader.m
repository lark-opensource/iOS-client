//
//  HMDCDUploader.m
//  Heimdallr
//
//  Created by maniackk on 2020/11/5.
//

#import <stdatomic.h>
#import "HMDMacro.h"
#import "HMDCDUploader.h"
#import "HeimdallrUtilities.h"
#import "HMDFileUploader.h"
#import "HMDALogProtocol.h"
#import "HMDCDMachO.hpp"
#import "NSDictionary+HMDSafe.h"
#import "HMDNetworkReachability.h"
#import "HMDCrashDirectory.h"
#import "HMDCrashDirectory+Path.h"
#import "HMDUserDefaults.h"
#import "HMDInjectedInfo.h"
#import "HMDFileTool.h"
// PrivateServices
#import "HMDServerStateService.h"
#import "HMDZipArchiveService.h"
#import "HMDCDConfig+Private.h"

static NSString *const kHMDCoreDumpUploadedCounter = @"kHMDCoreDumpUploadedCounter";
static const NSUInteger maxUploadTimes = 3;

@interface HMDCDUploader()

@property (nonatomic, copy, readwrite)NSString *coredumpRootPath;
@property (nonatomic, copy, readwrite)NSString *coredumpPath;
@property (nonatomic, copy)NSString *coredumpZipPath;
@property (nonatomic, strong)dispatch_queue_t coredumpQueue;
@property (nonatomic, strong) NSMutableSet *uploadingFileNames;
//@property (nonatomic, copy) NSDictionary *coredumpPathName; //@{filePath:fileName}
@property (nonatomic, strong) dispatch_semaphore_t uploadSemaphore;

@end

@implementation HMDCDUploader

- (instancetype)init {
    if (self = [super init]) {
        _uploadSemaphore = dispatch_semaphore_create(1);
        _coredumpQueue = dispatch_queue_create("com.heimdallr.coreDump", DISPATCH_QUEUE_SERIAL);
        _uploadingFileNames = [NSMutableSet set];
        _maxCDZipFileSizeMB = HMD_CD_DEFAULT_maxCDZipFileSizeMB;
        
        _coredumpRootPath = [HeimdallrUtilities.heimdallrRootPath stringByAppendingPathComponent:@"coredump"];
        createDirectoryIfNotExist(_coredumpRootPath);
        
        NSString *cdname = HMDCrashDirectory.UUID;
        if(cdname.length == 0) {
            cdname = [NSString stringWithFormat:@"%lld",(long long)([NSDate date].timeIntervalSince1970 * 1000)];
        }
        _coredumpPath = [_coredumpRootPath stringByAppendingPathComponent:cdname];
        _coredumpZipPath = [_coredumpRootPath stringByAppendingPathComponent:@"Prepared"];
    }
    return self;
}

static void createDirectoryIfNotExist(NSString * path) {
    DEBUG_ASSERT(path != nil);
    if([NSFileManager.defaultManager fileExistsAtPath:path]) return;
    hmdCheckAndCreateDirectory(path);
}

#pragma mark - public method56554

- (void)zipAndUploadCoreDump {
    static atomic_flag onceToken = ATOMIC_FLAG_INIT;
    if(atomic_flag_test_and_set_explicit(&onceToken, memory_order_relaxed)) return;
    
    dispatch_async(self.coredumpQueue, ^{
        NSDictionary<NSString *, NSString *> * coredumpPathPair = [self processCoreDump];
        for (NSString * filePath in coredumpPathPair) {
            if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
                NSTimeInterval zipTimeStart = [[NSDate date] timeIntervalSince1970];
                NSString *zipName = [NSString stringWithFormat:@"cd-%@.zip", [coredumpPathPair hmd_stringForKey:filePath]];
                NSString *zipTmpName = [NSString stringWithFormat:@"%lld.tmp",(long long)([NSDate date].timeIntervalSince1970 * 1000)];
                NSString *zipPath = [self.coredumpZipPath stringByAppendingPathComponent:zipName];
                NSString *zipTmpPath = [self.coredumpZipPath stringByAppendingPathComponent:zipTmpName];
                BOOL zipValid = [HMDZipArchiveService createZipFileAtPath:zipTmpPath withFilesAtPaths:@[filePath]];
                NSTimeInterval zipTimeEnd = [[NSDate date] timeIntervalSince1970];
                if (zipValid) {
                    if (rename(zipTmpPath.UTF8String, zipPath.UTF8String) == 0) {
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                            [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
                        });
                    }
                }
                else
                {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                        [[NSFileManager defaultManager] removeItemAtPath:zipTmpPath error:nil];
                    });
                    HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"coredump file zip fail");
                }
                HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"coredump zip time: %lg", zipTimeEnd - zipTimeStart);
            }
        }
        [self _uploadZip];
    });
}

#pragma mark - private method

+ (NSString *)removableFileDirectoryPath {
    return [[HeimdallrUtilities heimdallrRootPath] stringByAppendingPathComponent:@"coredump"];
}

- (void)_uploadZip
{
    if (![HMDNetworkReachability isWifiConnected]) return;
    NSFileManager *manager = [NSFileManager defaultManager];
    BOOL isDirectory; BOOL isExist;
    isExist = [manager fileExistsAtPath:self.coredumpZipPath isDirectory:&isDirectory];
    if(isExist) {
        if(isDirectory) {
            NSArray<NSString *> *contents = [manager contentsOfDirectoryAtPath:self.coredumpZipPath error:nil];
            for (NSString *fileName in contents) {
                if ([self.uploadingFileNames containsObject:fileName]) {//uploading
                    continue;
                }
                [self _uploadCoreDumpForFileName:fileName];
            }
        } else {
            [manager removeItemAtPath:self.coredumpZipPath error:nil];
            isExist = NO;
        }
    }
    if(!isExist) hmdCheckAndCreateDirectory(self.coredumpZipPath);
}

- (void)_uploadCoreDumpForFileName:(NSString *)fileName {
    NSString *filePath = [self.coredumpZipPath stringByAppendingPathComponent:fileName];
    [self _uploadCoreDumpForPath:filePath];
}

- (void)_uploadCoreDumpForPath:(NSString *)filePath {
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        NSAssert(NO, @"coredump does not exists!!!");
        return;
    }
    
    NSString *fileName = [filePath lastPathComponent];
    if ([fileName hasSuffix:@".tmp"]) {
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
        HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"coredump zip file not valid");
        return;
    }
    
    long long fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil] fileSize];
    if (fileSize > self.maxCDZipFileSizeMB * 1024 * 1024) {
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
        HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"coredump zip file(size:%lldB) is bigger than maxCDZipFileSizeMB(size:%luMB)", fileSize, (unsigned long)self.maxCDZipFileSizeMB);
        return;
    }
    
    if (fileName) {
        [self.uploadingFileNames addObject:fileName];
    }
    
    id<HMDFileUploadProtocol> uploader = [HMDFileUploader sharedInstance];
    __weak typeof(self) weakself = self;
    if ([uploader respondsToSelector:@selector(uploadFileWithRequest:)]) {
        if (![self deleteZipFileIfNeedWithFileName:fileName]) {
            dispatch_semaphore_wait(self.uploadSemaphore, DISPATCH_TIME_FOREVER);
            [self increaseCounterWithFileName:fileName];
            if (!hmd_is_server_available(HMDReporterALog)) {
                dispatch_semaphore_signal(self.uploadSemaphore);
                return;
            }
            HMDFileUploadRequest *request = [HMDFileUploadRequest new];
            request.filePath = filePath;
            request.logType = @"coredump";
            request.scene = @"crash";
            request.commonParams = [HMDInjectedInfo defaultInfo].commonParams;
            request.finishBlock = ^(BOOL success, id jsonObject) {
                dispatch_semaphore_signal(self.uploadSemaphore);
                dispatch_async(weakself.coredumpQueue, ^{
                    NSDictionary *result = [(NSDictionary *)jsonObject hmd_dictForKey:@"result"];
                    NSInteger statusCode = [(NSDictionary *)jsonObject hmd_intForKey:@"status_code"];
                    HMDServerState serverState = hmd_update_server_checker(HMDReporterALog, result, statusCode);
                    BOOL isDropData = (serverState & HMDServerStateDropAllData) == HMDServerStateDropAllData;
                    if (success || isDropData) {
                        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
                        [weakself.uploadingFileNames removeObject:fileName];
                        [weakself cleanCounterWithFileName:fileName];
                    } else {
                        HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"coredump zip upload fail");
                    }
                });
            };
            [uploader uploadFileWithRequest:request];
        }
    }
}

- (NSDictionary *)processCoreDump {
    NSFileManager *manager = [NSFileManager defaultManager];
    BOOL isDirectory; BOOL isExist;
    isExist = [manager fileExistsAtPath:self.coredumpRootPath isDirectory:&isDirectory];
    
    if(isExist && !isDirectory) {
        [manager removeItemAtPath:self.coredumpRootPath error:nil];
        isExist = NO;
    }
    
    if(!isExist) {
        hmdCheckAndCreateDirectory(self.coredumpRootPath);
        return @{};
    }
    
    NSMutableDictionary *coredumpPathName = [NSMutableDictionary dictionary];
    
    NSArray<NSString *> *contents = [manager contentsOfDirectoryAtPath:self.coredumpRootPath error:nil];
    for (NSString *fileName in contents) {
        NSString *filePath = [self.coredumpRootPath stringByAppendingPathComponent:fileName];
        BOOL fileIsDirectory; BOOL fileIsExist;
        fileIsExist = [manager fileExistsAtPath:filePath isDirectory:&fileIsDirectory];
        if (fileIsExist && !fileIsDirectory)
        {
            if ([fileName hasSuffix:@".tmp"]) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [manager removeItemAtPath:filePath error:nil];
                });
            }
            else
            {
                [coredumpPathName hmd_setSafeObject:fileName forKey:filePath];
            }
        }
    }
    
    return coredumpPathName.copy;
}

#pragma mark - Counter

- (NSMutableDictionary *)zipFileCounterDic {
    NSMutableDictionary *zipFileCounterDic;
    NSDictionary *dic = [[HMDUserDefaults standardUserDefaults] objectForKeyCompatibleWithHistory:kHMDCoreDumpUploadedCounter];
    if (dic) {
        zipFileCounterDic = [NSMutableDictionary dictionaryWithDictionary:dic];
    }
    else {
        zipFileCounterDic = [NSMutableDictionary dictionary];
    }
    return zipFileCounterDic;
}

- (BOOL)deleteZipFileIfNeedWithFileName:(NSString *)fileName {
    BOOL shouldDelete = NO;
    NSMutableDictionary *counterDic = [self zipFileCounterDic];
    NSNumber *uploadedCount = [counterDic objectForKey:fileName];
    if (uploadedCount && [uploadedCount unsignedIntegerValue] >= maxUploadTimes) {
        shouldDelete = YES;
        [counterDic removeObjectForKey:fileName?:@""];
        [[HMDUserDefaults standardUserDefaults] setObject:counterDic forKey:kHMDCoreDumpUploadedCounter];
        dispatch_async(dispatch_queue_create(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSString *filePath = [self.coredumpZipPath stringByAppendingPathComponent:fileName];
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
        });
        HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"core dump upload failed exceed max times : %lu, identifier : %@", maxUploadTimes, fileName);
    }
    
    return shouldDelete;
}

- (void)increaseCounterWithFileName:(NSString *)fileName {
    NSMutableDictionary *counterDic = [self zipFileCounterDic];
    NSNumber *uploadedCount = [counterDic objectForKey:fileName];
    if (uploadedCount) {
        NSUInteger count = [uploadedCount unsignedIntegerValue] + 1;
        [counterDic setValue:@(count) forKey:fileName];
    }
    else {
        [counterDic setValue:@(1) forKey:fileName];
    }
    
    [[HMDUserDefaults standardUserDefaults] setObject:counterDic forKey:kHMDCoreDumpUploadedCounter];
}

- (void)cleanCounterWithFileName:(NSString *)fileName {
    NSMutableDictionary *counterDic = [self zipFileCounterDic];
    [counterDic removeObjectForKey:fileName?:@""];
    [[HMDUserDefaults standardUserDefaults] setObject:counterDic forKey:kHMDCoreDumpUploadedCounter];
}

#pragma mark - get method

- (NSString *)coredumpZipPath
{
    if (!_coredumpZipPath) {
        _coredumpZipPath = [self.coredumpRootPath stringByAppendingPathComponent:@"Prepared"];
    }
    return _coredumpZipPath;
}

//- (NSDictionary *)coredumpPathName
//{
//    if (!_coredumpPathName) {
//        _coredumpPathName = [self processCoreDump];
//    }
//    return _coredumpPathName;
//}


@end
