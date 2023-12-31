//
//  HMDEMUploader.m
//  AWECloudCommand
//
//  Created by maniackk on 2021/6/4.
//

#import "HMDEMUploader.h"
#import "HMDFileUploader.h"
#import "NSDictionary+HMDSafe.h"
#import "HeimdallrUtilities.h"
#include "HMDEMMacro.h"
#import "HMDALogProtocol.h"
#import "HMDUserDefaults.h"
#import "HMDUploadHelper.h"
#import "Heimdallr.h"
#import "HMDFileTool.h"
#import "HMDSessionTracker.h"
// PrivateServices
#import "HMDServerStateService.h"
#import "HMDURLSettings.h"
#import "HMDZipArchiveService.h"

static NSString *const kHMDEvilMethodUploadedCounter = @"kHMDEvilMethodUploadedCounter";
static const NSUInteger maxUploadTimes = 3;

@interface HMDEMUploader()

@property (nonatomic, copy, readwrite)NSString *EMRootPath;
@property (nonatomic, copy)NSString *EMZipPath;
@property (nonatomic, strong)dispatch_queue_t emUploadQueue;
@property (nonatomic, strong) NSMutableSet *uploadingFileNames;
@property (nonatomic, strong) NSMutableDictionary *EMPathName; //@{filePath:fileName}
@property (nonatomic, strong) dispatch_semaphore_t uploadSemaphore;

@end

@implementation HMDEMUploader

- (instancetype)init
{
    self = [super init];
    if (self) {
        _uploadSemaphore = dispatch_semaphore_create(1);
        _emUploadQueue = dispatch_queue_create("com.heimdallr.evilmethodupload", DISPATCH_QUEUE_SERIAL);
        _uploadingFileNames = [NSMutableSet set];
        _EMPathName = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)zipAndUploadEMData {
    if (![Heimdallr shared].enableWorking) return;
    dispatch_async(self.emUploadQueue, ^{
        NSFileManager *manager = [NSFileManager defaultManager];
        BOOL isDirectory; BOOL isExist;
        isExist = [manager fileExistsAtPath:self.EMRootPath isDirectory:&isDirectory];
        if (isExist && isDirectory) {
            NSString *sessionID = [[HMDSessionTracker sharedInstance] eternalSessionID];
            NSArray<NSString *> *contents = [manager contentsOfDirectoryAtPath:self.EMRootPath error:nil];
            for (NSString *fileName in contents) {
                if ([fileName hasPrefix:sessionID]) {
                    continue;
                }
                NSString *filePath = [self.EMRootPath stringByAppendingPathComponent:fileName];
                BOOL fileIsDirectory, fileIsExist;
                fileIsExist = [manager fileExistsAtPath:filePath isDirectory:&fileIsDirectory];
                if (fileIsExist && !fileIsDirectory)
                {
                    [self.EMPathName hmd_setObject:fileName forKey:filePath];
                }
            }
        }
        [self _ZipFile];
    });
}

- (void)_ZipFile {
    for (NSString *filePath in self.EMPathName) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            NSString *zipName = [NSString stringWithFormat:@"em-%@.zip", [self.EMPathName hmd_stringForKey:filePath]];
            NSString *zipTmpName = [NSString stringWithFormat:@"%lld.tmp",(long long)([NSDate date].timeIntervalSince1970 * 1000)];
            NSString *zipPath = [self.EMZipPath stringByAppendingPathComponent:zipName];
            NSString *zipTmpPath = [self.EMZipPath stringByAppendingPathComponent:zipTmpName];
            BOOL zipValid = [HMDZipArchiveService createZipFileAtPath:zipTmpPath withFilesAtPaths:@[filePath]];
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
            }
        }
    }
    [self _uploadZip];
}

- (void)_uploadZip {
    NSFileManager *manager = [NSFileManager defaultManager];
    BOOL isDirectory; BOOL isExist;
    isExist = [manager fileExistsAtPath:self.EMZipPath isDirectory:&isDirectory];
    if(isExist) {
        if(isDirectory) {
            NSArray<NSString *> *contents = [manager contentsOfDirectoryAtPath:self.EMZipPath error:nil];
            for (NSString *fileName in contents) {
                if ([self.uploadingFileNames containsObject:fileName]) {//uploading
                    continue;
                }
                [self _uploadEMDataForFileName:fileName];
            }
        } else {
            [manager removeItemAtPath:self.EMZipPath error:nil];
            isExist = NO;
        }
    }
    if(!isExist) hmdCheckAndCreateDirectory(self.EMZipPath);
}

- (void)_uploadEMDataForFileName:(NSString *)fileName {
    NSString *filePath = [self.EMZipPath stringByAppendingPathComponent:fileName];
    [self _uploadEMDataForPath:filePath];
}

- (void)_uploadEMDataForPath:(NSString *)filePath {
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        NSAssert(NO, @"EvilMethod Data does not exists!!!");
        return;
    }
    
    NSString *fileName = [filePath lastPathComponent];
    if ([fileName hasSuffix:@".tmp"]) {
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
        HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"EvilMethod zip file not valid");
        return;
    }
    
    long long fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil] fileSize];
    if (fileSize > KMaxEMZipFileSizeMB * 1024 * 1024) {
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
        HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"EvilMethod zip file(size:%lldB) is bigger than maxCDZipFileSizeMB(size:%dMB)", fileSize, KMaxEMZipFileSizeMB);
        return;
    }
    
    if (fileName) {
        [self.uploadingFileNames addObject:fileName];
        if(hmd_log_enable()) {
            HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"EvilMethod upload file %@ size %lldB", fileName, fileSize);
        }
    }
    
    HMDFileUploadRequest *request = [HMDFileUploadRequest new];
    request.filePath = filePath;
    request.logType = @"lag_drop_frame";
    request.scene = @"evil_method";
    request.commonParams = @{@"data":@{@"event_type":@"lag_drop_frame"}, @"header":[[HMDUploadHelper sharedInstance].headerInfo copy], @"file":@"123456789"};
    request.path = [HMDURLSettings evilMethodUploadPath];
    request.finishBlock = ^(BOOL success, id jsonObject) {
        dispatch_semaphore_signal(self.uploadSemaphore);
        dispatch_async(self.emUploadQueue, ^{
            NSDictionary *result = [(NSDictionary *)jsonObject hmd_dictForKey:@"result"];
            NSInteger statusCode = [(NSDictionary *)jsonObject hmd_intForKey:@"status_code"];
            HMDServerState serverState = hmd_update_server_checker(HMDReporterEvilMethod, result, statusCode);
            BOOL isDropData = (serverState & HMDServerStateDropAllData) == HMDServerStateDropAllData;
            if (success || isDropData) {
                [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
                [self.uploadingFileNames removeObject:fileName];
                [self cleanCounterWithFileName:fileName];
            }
            else {
                HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"EvilMethod zip upload fail");
            }
        });
    };
    
    if (![self deleteZipFileIfNeedWithFileName:fileName])
    {
        dispatch_semaphore_wait(self.uploadSemaphore, DISPATCH_TIME_FOREVER);
        [self increaseCounterWithFileName:fileName];
        if (!hmd_is_server_available(HMDReporterEvilMethod)) {
            dispatch_semaphore_signal(self.uploadSemaphore);
            return;
        }
        [[HMDFileUploader sharedInstance] uploadFileWithRequest:request];
    }
}

#pragma mark - Counter

- (NSMutableDictionary *)zipFileCounterDic {
    NSMutableDictionary *zipFileCounterDic;
    NSDictionary *dic = [[HMDUserDefaults standardUserDefaults] objectForKeyCompatibleWithHistory:kHMDEvilMethodUploadedCounter];
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
        [[HMDUserDefaults standardUserDefaults] setObject:counterDic forKey:kHMDEvilMethodUploadedCounter];
        dispatch_async(dispatch_queue_create(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSString *filePath = [self.EMZipPath stringByAppendingPathComponent:fileName];
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
        });
        HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"evil method data upload failed exceed max times : %lu, identifier : %@", maxUploadTimes, fileName);
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
    
    [[HMDUserDefaults standardUserDefaults] setObject:counterDic forKey:kHMDEvilMethodUploadedCounter];
}

- (void)cleanCounterWithFileName:(NSString *)fileName {
    NSMutableDictionary *counterDic = [self zipFileCounterDic];
    [counterDic removeObjectForKey:fileName?:@""];
    [[HMDUserDefaults standardUserDefaults] setObject:counterDic forKey:kHMDEvilMethodUploadedCounter];
}


#pragma mark - get method

- (NSString *)EMRootPath {
    if (!_EMRootPath) {
        _EMRootPath = [[HeimdallrUtilities heimdallrRootPath] stringByAppendingPathComponent:@"EvilMethodTrace"];
        if (![[NSFileManager defaultManager] fileExistsAtPath:_EMRootPath]) {
            hmdCheckAndCreateDirectory(_EMRootPath);
        }
    }
    return _EMRootPath;
}

- (NSString *)EMZipPath {
    if (!_EMZipPath) {
        _EMZipPath = [self.EMRootPath stringByAppendingPathComponent:@"Prepared"];
        if (![[NSFileManager defaultManager] fileExistsAtPath:_EMZipPath]) {
            hmdCheckAndCreateDirectory(_EMZipPath);
        }
    }
    return _EMZipPath;
}

@end
