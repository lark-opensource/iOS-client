//
//  IESAlgorithmModelDownloadTask.m
//  EffectPlatformSDK
//
//  Created by zhangchengtao on 2020/3/9.
//

#import "IESAlgorithmModelDownloadTask.h"
#import <EffectPlatformSDK/IESFileDownloader.h>
#import <EffectPlatformSDK/NSError+IESEffectManager.h>
#import <EffectPlatformSDK/NSFileManager+IESEffectManager.h>
#import <EffectPlatformSDK/IESEffectLogger.h>
#import <EffectPlatformSDK/IESEffectPlatformRequestManager.h>

#import <FileMD5Hash/FileHash.h>

@implementation IESAlgorithmModelDownloadTask

- (instancetype)initWithAlgorithmModel:(IESEffectAlgorithmModel *)algorithmModel destination:(nonnull NSString *)destination {
    if (self = [super initWithFileMD5:algorithmModel.modelMD5 destination:destination]) {
        _algorithmModel = algorithmModel;
    }
    return self;
}

- (BOOL)p_handleDownloadedFileWithPath:(NSString *)downloadPath
                           destination:(NSString *)destination
                              modelMD5:(NSString *)modelMD5
                        algorithmModel:(IESEffectAlgorithmModel *)algorithmModel
                                 error:(NSError **)error {
    
    // Check if download file exists at specific path.
    if (![[NSFileManager defaultManager] fileExistsAtPath:downloadPath]) {
        *error = [NSError ieseffect_errorWithCode:40021 description:@"Download file not exists."];
        return NO;
    }
    
    // Check file md5.
    NSString *computeMD5 = [FileHash md5HashOfFileAtPath:downloadPath];
    if (!computeMD5 || ![computeMD5 isEqualToString:modelMD5]) {
        // Remove the broken file
        [[NSFileManager defaultManager] removeItemAtPath:downloadPath error:nil];
        NSString *errorDescription = [NSString stringWithFormat:@"computeMD5(%@) is not match modelMD5(%@).", computeMD5, modelMD5];
        *error = [NSError ieseffect_errorWithCode:40022 description:errorDescription];
        return NO;
    }
    
    // Compute file size
    unsigned long long fileSize = 0;
    NSError *fileSizeError = nil;
    if (![NSFileManager ieseffect_getFileSize:&fileSize filePath:downloadPath error:&fileSizeError]) {
        *error = fileSizeError;
        return NO;
    }
    
    // Rename $(md5).download to $(md5)
    NSError *renameError = nil;
    if (![[NSFileManager defaultManager] moveItemAtPath:downloadPath toPath:destination error:&renameError]) {
        *error = renameError;
        return NO;
    }
    
    // Insert into database
    [self.manifestManager insertAlgorithmModel:algorithmModel size:fileSize completion:nil];
    
    return YES;
}

- (void)startWithCompletion:(void (^)(void))completion {
    NSArray *fileDownloadURLs = self.algorithmModel.fileDownloadURLs;
    NSString *modelMD5 = self.algorithmModel.modelMD5;
    NSString *destination = self.destination;
    NSString *downloadPath = [self.destination stringByAppendingString:@".download"];
    IESEffectAlgorithmModel *algorithmModel = self.algorithmModel;
    
    IESEffectLogInfo(@"Begin download algorithm model. %@", algorithmModel);
    NSMutableString *traceLog = [[NSMutableString alloc] initWithString:[NSString stringWithFormat:@"Begin download algorithm model. %@ ", algorithmModel]];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if ([[NSFileManager defaultManager] fileExistsAtPath:destination]) {
            NSString *computeMD5 = [FileHash md5HashOfFileAtPath:destination];
            if (computeMD5 && [computeMD5 isEqualToString:modelMD5]) {
                IESEffectLogInfo(@"Algorithm model already exists. %@", algorithmModel);
                
                // Compute file size
                NSError *fileSizeError = nil;
                unsigned long long fileSize = 0;
                [NSFileManager ieseffect_getFileSize:&fileSize filePath:destination error:&fileSizeError];
                
                // Insert into database
                [self.manifestManager insertAlgorithmModel:algorithmModel size:fileSize completion:nil];
                [traceLog appendString:[NSString stringWithFormat:@"insert algorithmModel record to database fileSize:%llu, fileSizeError:%@. ", fileSize, fileSizeError]];
                
                // Download Success
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self callCompletionBlocks:YES error:nil traceLog:traceLog.copy];
                    if (completion) {
                        completion();
                    }
                });
                
                return;
            } else {
                IESEffectLogWarn(@"Algorithm model exists but broken. %@", algorithmModel);
                [traceLog appendString:@"algorithm model exits but broken. "];
                [[NSFileManager defaultManager] removeItemAtPath:destination error:nil];
            }
        }
        
        NSError *finalError = nil;
        if ([self p_handleDownloadedFileWithPath:downloadPath
                                     destination:destination
                                        modelMD5:modelMD5
                                  algorithmModel:algorithmModel
                                           error:&finalError]) {
            IESEffectLogInfo(@"Algorithm model download file exists. %@", algorithmModel);
            // Already downloaded.
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
                IESEffectLogError(@"Download algorithm model failed with error: %@. %@", error, algorithmModel);
                [traceLog appendString:[NSString stringWithFormat:@"Download algorithn model failed with error: %@. ", error]];
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
                                             destination:destination
                                                modelMD5:modelMD5
                                          algorithmModel:algorithmModel
                                                   error:&finalError]) {
                    IESEffectLogInfo(@"Download algorithm model success. %@", algorithmModel);
                    // Download Success
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self callCompletionBlocks:YES error:nil traceLog:traceLog.copy];
                        if (completion) {
                            completion();
                        }
                    });
                } else {
                    IESEffectLogError(@"Download algorithm model failed with error: %@. %@", finalError, algorithmModel);
                    [traceLog appendString:[NSString stringWithFormat:@"process algorithm model download file failed with error: %@. ", finalError]];
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
        [self downloadFileWithURLs:fileDownloadURLs
                      downloadPath:downloadPath
                  downloadProgress:^(CGFloat progress) {
        } completion:downloadFileCompletion];
    });
}

@end
