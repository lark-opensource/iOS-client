//
//  HMDClassCoverageUploader.m
//  Pods
//
//  Created by kilroy on 2020/6/10.
//

#import "HMDClassCoverageUploader.h"
#import "HMDFileUploadRequest.h"
#import "HMDFileUploader.h"
#import "HMDInjectedInfo.h"
#import "HeimdallrUtilities.h"
#import "HMDALogProtocol.h"
#import "HMDTTMonitor+CodeCoverage.h"
#import "HMDGCD.h"
#import "NSDictionary+HMDSafe.h"
#import "HMDDiskSpaceDistribution.h"
// PrivateServices
#import "HMDServerStateService.h"
#import "HMDZipArchiveService.h"

static NSString *const kHMDClassCoverageZipFileExtension = @"zip";

@interface HMDClassCoverageUploader()<HMDInspectorDiskSpaceDistribution>
@end

@implementation HMDClassCoverageUploader

- (void)uploadAfterAppLaunched {
    if (!hmd_is_server_available(HMDReporterClassCoverage)) {
        return;
    }
    if ([self checkFile]) {
        //Compress file to be uploaded
        NSString *zipFilePath = [self prepareUploadFile];
        if (zipFilePath) {
        //upload file
            HMDLog(@"Class Coverage Compressed File Begins to Upload.");
            [HMDTTMonitor uploadCodeCoverageFile:zipFilePath
                                           scene:nil
                                    commonParams:[HMDInjectedInfo defaultInfo].commonParams
                                        callback:^(BOOL success, id jsonObject) {
                NSDictionary *result = [(NSDictionary *)jsonObject hmd_dictForKey:@"result"];
                NSInteger statusCode = [(NSDictionary *)jsonObject hmd_intForKey:@"status_code"];
                hmd_update_server_checker(HMDReporterClassCoverage, result, statusCode);
                
                if (success) {
                    HMDLog(@"Class Coverage Compressed File Upload Success.");
                    HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"[HMDClassCoverageUploader uploadAfterAppLaunched]: Class Coverage Compressed File Upload Success");
                }
                else {
                    HMDLog(@"Class Coverage File Upload Failed.");
                    HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[HMDClassCoverageUploader uploadAfterAppLaunched] failed: Class Coverage Compressed File Upload Failed, fileName : %@", [zipFilePath lastPathComponent]);
                }
                [HMDClassCoverageUploader cleanFilesInPath:zipFilePath];
            }];
        }
    }
}

#pragma mark - File Section

+ (void)cleanFilesInPath:(nonnull NSString*) path {
    NSFileManager *manager = [NSFileManager defaultManager];
    BOOL isDir;
    if ([manager fileExistsAtPath:path isDirectory:&isDir]) {
        if (isDir) {
            //clear all files in the directory containing compressed files
            NSArray<NSString *> *oldZipFiles = [manager contentsOfDirectoryAtPath:path error:nil];
            if (oldZipFiles.count>0) {
                NSEnumerator *e = [oldZipFiles objectEnumerator];
                NSString *filename;
                while ((filename = [e nextObject])) {
                    [manager removeItemAtPath:[path stringByAppendingPathComponent:filename] error:nil];
                }
            }
        }
        else {
            [manager removeItemAtPath:path error:nil];
        }
    }
}

+ (void)cleanClassCoverageFiles {
    [self cleanFilesInPath:[self classCoveragePath]];
}

- (BOOL)checkFile {
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *dirPath = [HMDClassCoverageUploader classCoveragePath];
    //check if there is a file to be upload
    return [manager fileExistsAtPath: [dirPath stringByAppendingPathComponent:kHMDClassCoverageFileName]];
}

+ (NSString *)classCoveragePath {
    NSString *heimdallrRootPath = [HeimdallrUtilities heimdallrRootPath];
    NSString *classCoverageRootPath = [heimdallrRootPath stringByAppendingPathComponent:@"ClassCoverage"];
    return classCoverageRootPath;
}

//func that compress file to be upload
- (NSString *)prepareUploadFile {
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *dirPath = [HMDClassCoverageUploader classCoveragePath];
    
    NSString *originalFilePath = [dirPath stringByAppendingPathComponent:kHMDClassCoverageFileName];
    NSString *zipFilePath = [dirPath stringByAppendingPathComponent:[kHMDClassCoverageFileName stringByAppendingPathExtension:kHMDClassCoverageZipFileExtension]];
    //compress file
    BOOL zipValid = [HMDZipArchiveService createZipFileAtPath:zipFilePath withFilesAtPaths:@[originalFilePath]];
    if (!zipValid) {
        //压缩失败就清空压缩失败的文件
        [manager removeItemAtPath:zipFilePath error:nil];
        HMDALOG_PROTOCOL_WARN_TAG(@"Heimdallr", @"[HMDClassCoverageUploader prepareUploadFile] failed: Class Coverage File Compression Fail.");
    }
    HMDLog(@"Class Coverage Compressed File Successfully.");
    HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"[HMDClassCoverageUploader prepareUploadFile] success: Class Coverage File Compression Success.");
    return zipFilePath;
}

#pragma mark HMDInspectorDiskSpaceDistribution
+ (NSString *)removableFileDirectoryPath {
    return [self classCoveragePath];
}
@end
