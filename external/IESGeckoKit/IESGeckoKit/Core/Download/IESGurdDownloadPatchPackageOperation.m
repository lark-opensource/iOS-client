//
//  IESGurdDownloadPatchPackageOperation.m
//  IESGeckoKit
//
//  Created by chenyuchuan on 2019/6/10.
//

#import "IESGurdDownloadPatchPackageOperation.h"

#import "IESGurdProtocolDefines.h"
#import "IESGeckoKit+Private.h"
#import "IESGeckoDefines+Private.h"
#import "IESGeckoFileMD5Hash.h"
//manager
#import "IESGurdFileBusinessManager.h"
#import "IESGurdDelegateDispatcherManager.h"
#import "IESGurdDownloader.h"
//util
#import "IESGeckoFileMD5Hash.h"
#import "IESGeckoBSPatch.h"
//category
#import "NSError+IESGurdKit.h"

#define FILE_MANAGER    [NSFileManager defaultManager]

static NSString * const kIESGurdPatchedFileSuffix = @"-patched";

@interface IESGurdBaseDownloadOperation ()
@property (nonatomic, assign) BOOL shouldRetry;
@end

@implementation IESGurdDownloadPatchPackageOperation

#pragma mark - Subclass Override

- (void)operationDidStart
{
    [super operationDidStart];
    [DELEGATE_DISPATCHER(IESGurdEventDelegate) gurdWillDownloadPackageForAccessKey:self.accessKey
                                                                           channel:self.config.channel
                                                                           isPatch:YES];
    
    __weak IESGurdDownloadPatchPackageOperation *weakSelf = self;
    IESGurdDownloadResourceCompletion completionBlock = ^(NSURL *pathURL, NSDictionary *downloadInfo, NSError *networkError) {
        [weakSelf handleDownloadResultWithPathURL:pathURL
                                     downloadInfo:downloadInfo
                                     networkError:networkError];
    };
    NSArray<NSString *> *urlList = self.config.patch.urlList;
    self.downloadInfoModel.allDownloadURLStrings = self.retryDownload ? urlList : @[ urlList.firstObject ? : @"" ];
    [IESGurdDownloader downloadPackageWithDownloadInfoModel:self.downloadInfoModel
                                                 completion:completionBlock];
}

- (BOOL)isPatch
{
    return YES;
}

#pragma mark - Private

- (void)handleDownloadResultWithPathURL:(NSURL *)pathURL
                           downloadInfo:(NSDictionary *)downloadInfo
                           networkError:(NSError *)networkError
{
    if (self.isCancelled) {
        if (pathURL) {
            [FILE_MANAGER removeItemAtURL:pathURL error:NULL];
        }
        return;
    }
    
    if (!pathURL) {
        if (networkError.code == -999) {
            self.shouldRetry = NO;
        }
        
        id<IESGurdNetworkDelegate> networkDelegate = [IESGurdKit sharedInstance].networkDelegate;
        NSString *networkDelegateString = networkDelegate ? NSStringFromClass([networkDelegate class]) : @"Default";
        NSString *message = [NSString stringWithFormat:@"❌ Download P-package failed (Version : %llu; ErrorCode : %zd; Reason : %@; NetworkDelegate : %@)",
                             self.config.version,
                             networkError.code,
                             networkError.localizedDescription,
                             networkDelegateString];
        [self traceEventWithMessage:message hasError:YES shouldLog:YES];
        
        NSError *error = [NSError ies_errorWithCode:networkError.code
                                        description:message];
        [self handleDownloadResultWithDownloadInfo:downloadInfo
                                           succeed:NO
                                             error:error];
        return;
    }
    [self handleDownloadResultWithDownloadInfo:downloadInfo
                                       succeed:YES
                                         error:nil];
    
    __weak IESGurdDownloadPatchPackageOperation *weakSelf = self;
    dispatch_block_t block = ^{
        NSError *error = nil;
        
        NSString *patchPackagePath = pathURL.relativePath;
        NSString *downloadURLString = downloadInfo[IESGurdDownloadInfoURLKey];
        NSString *errorMessage = nil;
        if (![weakSelf checkFileMd5WithPackagePath:patchPackagePath
                                               md5:weakSelf.config.patch.md5
                                 packageTypeString:@"P-package"
                                 downloadURLString:downloadURLString
                                      errorMessage:&errorMessage]) {
            error = [NSError ies_errorWithCode:IESGurdSyncStatusDownloadCheckMd5Failed
                                   description:errorMessage];
            [weakSelf handleBusinessFailedWithType:error];
            return;
        }
        
        NSString *targetPackagePath = nil;
        if (self.config.isZstd) {
            targetPackagePath = [self createPatchedPackagePathWithError:&error];
            if (targetPackagePath.length == 0 || ![FILE_MANAGER moveItemAtPath:patchPackagePath
                                                                        toPath:targetPackagePath
                                                                         error:&error]) {
                [FILE_MANAGER removeItemAtPath:patchPackagePath error:NULL];
                [weakSelf handleBusinessFailedWithType:error];
                return;
            }
        } else {
            GURD_TIK;
            if (![weakSelf BSPatchWithPatchPackagePath:patchPackagePath
                                     targetPackagePath:&targetPackagePath
                                     downloadURLString:downloadURLString
                                                 error:&error]) {
                [weakSelf handleBusinessFailedWithType:error];
                return;
            }
            weakSelf.config.updateStatisticModel.durationZipPatch = GURD_TOK;
        }
        uint64_t downloadSize = [IESGurdFilePaths fileSizeAtPath:patchPackagePath];
        [weakSelf handleBusinessSuccessWithPackagePath:targetPackagePath
                                          downloadSize:downloadSize
                                          downloadInfo:downloadInfo];
    };
    [IESGurdFileBusinessManager asyncExecuteBlock:block
                                        accessKey:self.accessKey
                                          channel:self.config.channel];
}

- (BOOL)BSPatchWithPatchPackagePath:(NSString *)patchPackagePath
                  targetPackagePath:(NSString **)targetPackagePath
                  downloadURLString:(NSString *)downloadURLString
                              error:(NSError **)error
{
    NSString *patchedPackagePath = nil;
    if (![self innerBSPatchWithPatchPackagePath:patchPackagePath
                              targetPackagePath:&patchedPackagePath
                                          error:error]) {
        return NO;
    }
    
    NSString *errorMessage = nil;
    if (![self checkFileMd5WithPackagePath:patchedPackagePath
                                       md5:self.config.package.md5
                         packageTypeString:@"BSP-package"
                         downloadURLString:downloadURLString
                              errorMessage:&errorMessage]) {
        *error = [NSError ies_errorWithCode:IESGurdSyncStatusBSPatchCheckMd5Failed
                                description:errorMessage];
        return NO;
    }
    
    if (![self updateBackupPackageWithPatchedPackagePath:patchedPackagePath
                                                   error:error]) {
        return NO;
    }
    
    *targetPackagePath = patchedPackagePath;
    return YES;
}

- (BOOL)innerBSPatchWithPatchPackagePath:(NSString *)patchPackagePath
                       targetPackagePath:(NSString **)targetPackagePath
                                   error:(NSError **)error
{
    NSError *createPathError = nil;
    NSString *patchedPackagePath = [self createPatchedPackagePathWithError:&createPathError];
    if (patchedPackagePath.length == 0) {
        [FILE_MANAGER removeItemAtPath:patchPackagePath error:NULL];
        
        *error = createPathError;
        return NO;
    }

    NSString *backupPath = [IESGurdFileBusinessManager oldFilePathForAccessKey:self.accessKey
                                                                       channel:self.config.channel];
    NSString *errorMessage = nil;
    if (IESGurdBSPatch(backupPath, patchedPackagePath, patchPackagePath, &errorMessage)) {
        *targetPackagePath = patchedPackagePath;
        
        NSString *message = [NSString stringWithFormat:@"✅ BSP successfully (Version : %llu)", self.config.version];
        [self traceEventWithMessage:message hasError:NO shouldLog:NO];
        return YES;
    }
    
    NSString *message = [NSString stringWithFormat:@"❌ BSP failed (Version : %llu; Reason : %@; BackupPackageSize : %@; BackupPackagePath : %@; P-package Size : %@)",
                         self.config.version,
                         errorMessage ? : @"unknown",
                         [IESGurdFilePaths fileSizeStringAtPath:backupPath],
                         [IESGurdFilePaths briefFilePathWithFullPath:backupPath],
                         [IESGurdFilePaths fileSizeStringAtPath:patchPackagePath]];
    [self traceEventWithMessage:message hasError:YES shouldLog:YES];
    
    [FILE_MANAGER removeItemAtPath:patchedPackagePath error:NULL];
    [FILE_MANAGER removeItemAtPath:patchPackagePath error:NULL];
    
    *error = [NSError ies_errorWithCode:IESGurdSyncStatusBSPatchFailed
                            description:message];
    return NO;
}

//只针对单文件
- (BOOL)updateBackupPackageWithPatchedPackagePath:(NSString *)patchedPackagePath error:(NSError **)error
{
    if (![patchedPackagePath hasSuffix:kIESGurdPatchedFileSuffix]) {
        return YES;
    }
    //删除旧的包
    NSString *backupPath = [IESGurdFileBusinessManager oldFilePathForAccessKey:self.accessKey
                                                                       channel:self.config.channel];
    [FILE_MANAGER removeItemAtPath:backupPath error:NULL];
    
    //重命名新包去掉-patch后缀
    NSString *patchedBackupPath = [IESGurdFilePaths backupSingleFilePathForMd5:self.config.package.md5];
    NSError *fileError = nil;
    if ([FILE_MANAGER moveItemAtPath:patchedPackagePath toPath:patchedBackupPath error:&fileError]) {
        return YES;
    }
    
    [FILE_MANAGER removeItemAtPath:patchedPackagePath error:NULL];
    
    NSString *message = [NSString stringWithFormat:@"❌ File rename failed (Version : %llu; Reason : %@)",
                         self.config.version, fileError.localizedDescription];
    [self traceEventWithMessage:message hasError:YES shouldLog:YES];
    
    *error = [NSError ies_errorWithCode:IESGurdSyncStatusRenamePatchedPackageFailed
                            description:message];
    return NO;
}

- (NSString *)createPatchedPackagePathWithError:(NSError **)error
{
    IESGurdResourceModel *config = self.config;
    
    if (config.packageType == 0) {
        NSError *createError = nil;
        NSString *path = [IESGurdFileBusinessManager createInactivePackagePathForAccessKey:self.accessKey
                                                                                   channel:config.channel
                                                                                   version:config.version
                                                                                       md5:config.package.md5
                                                                                    isZstd:config.isZstd
                                                                                     error:&createError];
        if (path.length == 0) {
            NSString *message = [NSString stringWithFormat:@"❌ Create BSP-package path failed (Version : %llu; Reason : DesPath doesn't exist，%@)",
                                 config.version, createError.localizedDescription ? : @"unknown"];
            [self traceEventWithMessage:message hasError:YES shouldLog:YES];
            
            *error = [NSError ies_errorWithCode:IESGurdSyncStatusMoveToNilDestinationPath
                                    description:message];
        }
        return path;
    }
    
    if (config.packageType == 1) {
        [IESGurdFileBusinessManager createBackupSingleFilePathIfNeeded];
        NSString *backupPath = [IESGurdFilePaths backupSingleFilePathForMd5:config.package.md5];
        return [backupPath stringByAppendingString:kIESGurdPatchedFileSuffix];
    }
    
    NSString *message = [NSString stringWithFormat:@"Unknown package type : %zd", config.packageType];
    [self traceEventWithMessage:message hasError:YES shouldLog:YES];
    
    *error = [NSError ies_errorWithCode:IESGurdSyncStatusMoveToNilDestinationPath
                            description:message];
    return nil;
}

@end

#undef FILE_MANAGER
