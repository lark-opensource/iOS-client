//
//  ACCCutSameTemplateZipDowndoader.m
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/3/23.
//

#import "ACCCutSameTemplateZipDowndoader.h"
#import "ACCFileDownloader+ACCCutSameTemplate.h"

#import <FileMD5Hash/FileHash.h>

static NSString* ACCCutSameTemplateZipDowndoaderPath(void)
{
    NSString *cachesDir = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"ACCCutSameTemplateCache"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:cachesDir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:cachesDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return cachesDir;
}

static NSString* ACCGenerateCutSameTemplateZipPath(NSString *md5)
{
    if (!md5.length) {
        md5 = [NSUUID UUID].UUIDString;
    }
    
    NSString *f = [md5 stringByAppendingPathExtension:@"zip"];
    NSString *n = [ACCCutSameTemplateZipDowndoaderPath() stringByAppendingPathComponent:f];
    
    return n;
}

@implementation ACCCutSameTemplateZipDowndoader

+ (void)clearCache
{
    [[NSFileManager defaultManager] removeItemAtPath:ACCCutSameTemplateZipDowndoaderPath()
                                               error:nil];
}

- (BOOL)checkTemplateExist
{
    if (self.templateModel.md5.length) {
        NSString *templatePath = ACCGenerateCutSameTemplateZipPath(self.templateModel.md5);

        if ([[NSFileManager defaultManager] fileExistsAtPath:templatePath]) {
            NSString *fileMd5 = [FileHash md5HashOfFileAtPath:templatePath];

            if ([fileMd5 isEqualToString:self.templateModel.md5]) {
                return YES;
            } else {
                [self removeTemplateFile];
            }
        }
    }
    
    return NO;
}

- (void)removeTemplateFile
{
    if (self.templateModel.md5.length) {
        NSString *templatePath = ACCGenerateCutSameTemplateZipPath(self.templateModel.md5);
        [[NSFileManager defaultManager] removeItemAtPath:templatePath error:nil];
    }
}

#pragma mark - LVTemplateZipDowndoader
- (void)downloadFile:(NSURL *)fileURL
            progress:(void(^)(CGFloat progress))progressBlock
          completion:(void(^)( NSString * _Nullable path, NSError * _Nullable error))completion
{
    if ([self checkTemplateExist]) {
        if (progressBlock) {
            progressBlock(1.0);
        }
        
        if (completion) {
            completion(ACCGenerateCutSameTemplateZipPath(self.templateModel.md5), nil);
        }
        
        if (self.delegateCompletion) {
            self.delegateCompletion(self, ACCGenerateCutSameTemplateZipPath(self.templateModel.md5), nil);
        }
    } else {
        @weakify(self);
        self.task =
        [[ACCFileDownloader sharedInstance]
         downloadCutSameTemplate:self.templateModel
         url:fileURL
         downloadPath:ACCGenerateCutSameTemplateZipPath(self.templateModel.md5)
         downloadProgress:^(CGFloat progress) {
            if (progressBlock) {
                progressBlock(progress);
            }
        }
         completion:^(NSError *error, NSString *filePath, NSDictionary *extraInfoDict) {
            @strongify(self);
            NSString *templatePath = ACCGenerateCutSameTemplateZipPath(self.templateModel.md5);
            if (!error && ([[NSFileManager defaultManager] fileExistsAtPath:templatePath])) {
                NSString *fileMd5 = [FileHash md5HashOfFileAtPath:templatePath];
                if (![fileMd5 isEqualToString:self.templateModel.md5]) {
                    error = [NSError errorWithDomain:@"ACCCutSameTemplateZipDowndoader" code:-1 userInfo:nil];
                }
            }
            
            if (completion) {
                completion(filePath, error);
            }
            
            if (self.delegateCompletion) {
                self.delegateCompletion(self, filePath, error);
            }
        }];
    }
}

- (void)cancel
{
    [self.task cancel];
    self.task = nil;
}

- (void)removeCache;
{
    [self removeTemplateFile];
}

@end
