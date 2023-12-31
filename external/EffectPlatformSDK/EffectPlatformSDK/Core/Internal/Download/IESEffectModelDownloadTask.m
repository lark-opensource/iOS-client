//
//  IESEffectModelDownloadTask.m
//  EffectPlatformSDK
//
//  Created by zhangchengtao on 2020/3/9.
//

#import "IESEffectModelDownloadTask.h"
#import <EffectPlatformSDK/IESEffectModel.h>
#import <EffectPlatformSDK/IESFileDownloader.h>
#import <EffectPlatformSDK/IESEffectLogger.h>
#import <EffectPlatformSDK/IESManifestManager.h>
#import <EffectPlatformSDK/NSError+IESEffectManager.h>
#import <EffectPlatformSDK/NSFileManager+IESEffectManager.h>
#import <FileMD5Hash/FileHash.h>
#import <SSZipArchive/SSZipArchive.h>
#import <EffectPlatformSDK/IESEffectPlatformRequestManager.h>

@implementation IESEffectModelDownloadTask

- (instancetype)initWithEffectModel:(IESEffectModel *)effectModel destination:(NSString *)destination {
    if (self = [super initWithFileMD5:effectModel.md5 destination:destination]) {
        _effectModel = effectModel;
    }
    return self;
}

// Clean up
- (BOOL)p_cleanUpWithDestination:(NSString *)destination
                       unzipPath:(NSString *)unzipPath
                           error:(NSError **)error {
    BOOL isDirectory = NO;
    if ([[NSFileManager defaultManager] fileExistsAtPath:destination isDirectory:&isDirectory]) {
        if (![[NSFileManager defaultManager] removeItemAtPath:destination error:error]) {
            return NO;
        }
    }
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:unzipPath isDirectory:&isDirectory]) {
        if (![[NSFileManager defaultManager] removeItemAtPath:unzipPath error:error]) {
            return NO;
        }
    }
    
    return YES;
}

- (BOOL)p_handleDownloadedFileWithPath:(NSString *)downloadPath
                             unzipPath:(NSString *)unzipPath
                           destination:(NSString *)destination
                               fileMD5:(NSString *)fileMD5
                           effectModel:(IESEffectModel *)effectModel
                                 error:(NSError **)error {
    
    // Check if download file exists at specific path.
    if (![[NSFileManager defaultManager] fileExistsAtPath:downloadPath]) {
        NSError *downloadError = [NSError ieseffect_errorWithCode:40011 description:@"Download file not exists."];
        *error = downloadError;
        return NO;
    }
    
    // Check file md5.
    NSString *computeMD5 = [FileHash md5HashOfFileAtPath:downloadPath];
    if (!computeMD5 || ![computeMD5 isEqualToString:fileMD5]) {
        [[NSFileManager defaultManager] removeItemAtPath:downloadPath error:nil];
        NSString *errorDescription = [NSString stringWithFormat:@"computeMD5(%@) is not match fileMD5(%@).", computeMD5, fileMD5];
        NSError *md5Error = [NSError ieseffect_errorWithCode:40012 description:errorDescription];
        *error = md5Error;
        return NO;
    }
    
    // Unzip
    NSError *unzipError = nil;
    if (![SSZipArchive unzipFileAtPath:downloadPath toDestination:unzipPath overwrite:YES password:nil error:&unzipError]) {
        [[NSFileManager defaultManager] removeItemAtPath:unzipPath error:nil];
        *error = unzipError;
        return NO;
    }
    
    // Compute effect folder size.
    unsigned long long allocatedSize = 0;
    NSError *getAllocatedSizeError = nil;
    if (![NSFileManager ieseffect_getAllocatedSize:&allocatedSize
                                  ofDirectoryAtURL:[NSURL fileURLWithPath:unzipPath]
                                             error:&getAllocatedSizeError] || allocatedSize == 0) {
        [[NSFileManager defaultManager] removeItemAtPath:unzipPath error:nil];
        *error = getAllocatedSizeError;
        return NO;
    }
    
    // Rename $(md5).unzip to $(md5)
    NSError *renameError = nil;
    if (![[NSFileManager defaultManager] moveItemAtPath:unzipPath toPath:destination error:&renameError]) {
        *error = renameError;
        return NO;
    }
    
    // Remove the download file
    [[NSFileManager defaultManager] removeItemAtPath:downloadPath error:nil];
    
    // Insert into database
    [self.manifestManager insertEffectModel:effectModel
                                 effectSize:allocatedSize
                                     NSData:nil
                                 completion:nil];
    
    return YES;
}

- (void)startWithCompletion:(void (^)(void))completion {
    NSString *fileMD5 = self.fileMD5;
    NSString *destination = self.destination;
    NSString *downloadPath = [self.destination stringByAppendingString:@".zip"];
    NSString *unzipPath = [self.destination stringByAppendingString:@".unzip"];
    IESEffectModel *effectModel = self.effectModel;
    
    IESEffectLogInfo(@"Begin download effect model. %@", effectModel);
    NSMutableString *traceLog = [[NSMutableString alloc] initWithString:[NSString stringWithFormat:@"Begin download effect model. %@", effectModel]];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *cleanUpError = nil;
        if (![self p_cleanUpWithDestination:destination unzipPath:unzipPath error:&cleanUpError]) {
            IESEffectLogError(@"Clean up effects failed with error: %@", cleanUpError);
            [traceLog appendString:[NSString stringWithFormat:@"clean up the effect files and unzip files with error: %@. ", cleanUpError]];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self callCompletionBlocks:NO error:cleanUpError traceLog:traceLog.copy];
                if (completion) {
                    completion();
                }
            });
            return;
        }
        
        NSError *finalError = nil;
        if ([self p_handleDownloadedFileWithPath:downloadPath
                                       unzipPath:unzipPath
                                     destination:destination
                                         fileMD5:fileMD5
                                     effectModel:effectModel
                                           error:&finalError]) {
            IESEffectLogInfo(@"Effect model download file exists. %@", effectModel);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self callCompletionBlocks:YES error:nil traceLog:traceLog.copy];
                if (completion) {
                    completion();
                }
            });
            return;
        }
        
        @weakify(self);
        void (^downloadFileCompletion)(NSError *error, NSString *filePath, NSDictionary *extraInfoDict) = ^(NSError *error, NSString *filePath, NSDictionary *extraInfoDict) {
            @strongify(self);
            // Check if Download failed.
            if (!filePath || error) {
                IESEffectLogError(@"Download effect model failed with error: %@. %@", error, effectModel);
                [traceLog appendString:[NSString stringWithFormat:@"download effect model zip file failed with error: %@. ", error]];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self callCompletionBlocks:NO error:error traceLog:traceLog.copy];
                    if (completion) {
                        completion();
                    }
                });
                return;
            }
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSError *finalError = nil;
                if ([self p_handleDownloadedFileWithPath:downloadPath
                                               unzipPath:unzipPath
                                             destination:destination
                                                 fileMD5:fileMD5
                                             effectModel:effectModel
                                                   error:&finalError]) {
                    IESEffectLogInfo(@"Download effect model success. %@", effectModel);
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self callCompletionBlocks:YES error:nil traceLog:traceLog.copy];
                        if (completion) {
                            completion();
                        }
                    });
                } else {
                    IESEffectLogError(@"Download effect model failed with error: %@. %@", finalError, effectModel);
                    [traceLog appendString:[NSString stringWithFormat:@"process download effect model zip file failed with error: %@. ", finalError]];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self callCompletionBlocks:NO error:finalError traceLog:traceLog.copy];
                        if (completion) {
                            completion();
                        }
                    });
                }
            });
        };
        IESEffectPreFetchProcessIfNeed(completion, downloadFileCompletion)
        [self downloadFileWithURLs:self.effectModel.fileDownloadURLs
                      downloadPath:downloadPath
                  downloadProgress:^(CGFloat progress) {
            [self callProgressBlocks:progress];
        } completion:downloadFileCompletion];
    });
}

@end
