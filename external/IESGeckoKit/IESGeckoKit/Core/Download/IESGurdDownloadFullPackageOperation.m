//
//  IESGurdDownloadFullPackageOperation.m
//  IESGeckoKit
//
//  Created by chenyuchuan on 2019/6/10.
//

#import "IESGurdDownloadFullPackageOperation.h"

#import "IESGeckoKit+Private.h"
#import "IESGurdProtocolDefines.h"
//manager
#import "IESGurdFileBusinessManager.h"
#import "IESGurdDelegateDispatcherManager.h"
#import "IESGurdDownloader.h"
//util
#import "IESGeckoFileMD5Hash.h"
//category
#import "NSError+IESGurdKit.h"

#define FILE_MANAGER    [NSFileManager defaultManager]

@implementation IESGurdDownloadFullPackageOperation

#pragma mark - Subclass Override

- (void)operationDidStart
{
    [super operationDidStart];
    [DELEGATE_DISPATCHER(IESGurdEventDelegate) gurdWillDownloadPackageForAccessKey:self.accessKey
                                                                           channel:self.config.channel
                                                                           isPatch:NO];
    
    __weak IESGurdDownloadFullPackageOperation *weakSelf = self;
    IESGurdDownloadResourceCompletion completionBlock = ^(NSURL *pathURL, NSDictionary *downloadInfo, NSError *networkError) {
        [weakSelf handleDownloadResultWithPathURL:pathURL
                                     downloadInfo:downloadInfo
                                     networkError:networkError];
    };
    NSArray<NSString *> *urlList = self.config.package.urlList;
    self.downloadInfoModel.allDownloadURLStrings = self.retryDownload ? urlList : @[ urlList.firstObject ? : @"" ];
    [IESGurdDownloader downloadPackageWithDownloadInfoModel:self.downloadInfoModel
                                                     completion:completionBlock];
}

- (BOOL)isPatch
{
    return NO;
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
        id<IESGurdNetworkDelegate> networkDelegate = [IESGurdKit sharedInstance].networkDelegate;
        NSString *networkDelegateString = networkDelegate ? NSStringFromClass([networkDelegate class]) : @"Default";
        NSString *errorDescription = networkError.localizedDescription ? : @"";
        NSString *message = [NSString stringWithFormat:@"❌ Download F-package failed (Version : %llu; ErrorCode : %zd; Reason : %@; NetworkDelegate : %@)",
                             self.config.version,
                             networkError.code,
                             errorDescription,
                             networkDelegateString ? : @"Default"];
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
    
    __weak IESGurdDownloadFullPackageOperation *weakSelf = self;
    dispatch_block_t block = ^{
        NSError *error = nil;
        
        NSString *tempPackagePath = pathURL.relativePath;
        if (![weakSelf checkFileMd5WithPackagePath:tempPackagePath
                                               md5:weakSelf.config.package.md5
                                 downloadURLString:downloadInfo[IESGurdDownloadInfoURLKey]
                                             error:&error]) {
            [weakSelf handleBusinessFailedWithType:error];
            return;
        }
        
        NSString *packagePath = [weakSelf createPackagePathWithError:&error];
        if (packagePath.length == 0) {
            [weakSelf handleBusinessFailedWithType:error];
            return;
        }
        
        if (![weakSelf moveFileWithTempPackagePath:tempPackagePath
                                        targetPath:packagePath
                                             error:&error]) {
            [weakSelf handleBusinessFailedWithType:error];
            return;
        }
        
        uint64_t downloadSize = [IESGurdFilePaths fileSizeAtPath:packagePath];
        [weakSelf handleBusinessSuccessWithPackagePath:packagePath
                                          downloadSize:downloadSize
                                          downloadInfo:downloadInfo];
    };
    [IESGurdFileBusinessManager asyncExecuteBlock:block
                                        accessKey:self.accessKey
                                          channel:self.config.channel];
}

- (BOOL)checkFileMd5WithPackagePath:(NSString *)packagePath
                                md5:(NSString *)md5
                  downloadURLString:(NSString *)downloadURLString
                              error:(NSError **)error
{
    NSString *message = nil;
    if ([self checkFileMd5WithPackagePath:packagePath
                                      md5:md5
                        packageTypeString:@"F-package"
                        downloadURLString:downloadURLString
                             errorMessage:&message]) {
        return YES;
    }
    *error = [NSError ies_errorWithCode:IESGurdSyncStatusDownloadCheckMd5Failed
                            description:message];
    return NO;
}

- (NSString *)createPackagePathWithError:(NSError **)error
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
            NSString *message = [NSString stringWithFormat:@"❌ Create F-package path failed (Version : %llu; Reason : desPath doesn't exist，%@)",
                                 config.version, createError.localizedDescription ? : @"unknown"];
            [self traceEventWithMessage:message hasError:YES shouldLog:YES];
            
            *error = [NSError ies_errorWithCode:IESGurdSyncStatusMoveToNilDestinationPath
                                    description:message];
        }
        return path;
    }
    
    if (config.packageType == 1) {
        [IESGurdFileBusinessManager createBackupSingleFilePathIfNeeded];
        return [IESGurdFilePaths backupSingleFilePathForMd5:config.package.md5];
    }
    
    NSString *message = [NSString stringWithFormat:@"Unknown package type : %zd", config.packageType];
    [self traceEventWithMessage:message hasError:YES shouldLog:YES];
    
    *error = [NSError ies_errorWithCode:IESGurdSyncStatusMoveToNilDestinationPath
                            description:message];
    return nil;
}

- (BOOL)moveFileWithTempPackagePath:(NSString *)tempPackagePath
                         targetPath:(NSString *)targetPath
                              error:(NSError **)error
{
    if ([FILE_MANAGER fileExistsAtPath:targetPath]) {
        [FILE_MANAGER removeItemAtPath:targetPath error:NULL];
    }
    NSError *fileError = nil;
    if ([FILE_MANAGER moveItemAtPath:tempPackagePath toPath:targetPath error:&fileError]) {
        [FILE_MANAGER removeItemAtPath:tempPackagePath error:NULL];
        return YES;
    }
    BOOL sourceFileExists = [FILE_MANAGER fileExistsAtPath:tempPackagePath];
    NSString *message = [NSString stringWithFormat:@"❌ Move F-package failed (Version : %llu; Reason : %@; SrcPath %@; DesPath : %@)",
                         self.config.version,
                         fileError.localizedDescription,
                         sourceFileExists ? @"exists" : @"does not exist",
                         [IESGurdFilePaths briefFilePathWithFullPath:targetPath]];
    [self traceEventWithMessage:message hasError:YES shouldLog:YES];
    
    [FILE_MANAGER removeItemAtPath:tempPackagePath error:NULL];
    
    *error = [NSError ies_errorWithCode:IESGurdSyncStatusAchievePackageZipFailed
                            description:message];
    return NO;
}

@end

#undef FILE_MANAGER
