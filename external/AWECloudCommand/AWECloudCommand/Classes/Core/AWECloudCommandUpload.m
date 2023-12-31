//
//  AWECloudCommandUpload.m
//  Pods
//
//  Created by willorfang on 2017/1/23.
//
//

#import "AWECloudCommandUpload.h"
#import "AWECloudCommandReachability.h"
#import "AWECloudCommandNetworkUtility.h"
#import <SSZipArchive/ZipArchive.h>
#import "AWECloudDiskUtility.h"
#import "AWECloudCommandMacros.h"

static const long long kMaxUploadSize = 100 * 1024 * 1024;

@implementation AWECloudCommandUpload

AWE_REGISTER_CLOUD_COMMAND(@"file")

+ (instancetype)createInstance
{
    return [[self alloc] init];
}

- (void)excuteCommand:(AWECloudCommandModel *)model completion:(AWECloudCommandResultCompletion)completion
{
    AWECloudCommandResult *result = [self _resultWithCommand:model];
    AWESAFEBLOCK_INVOKE(completion, result);
}

- (AWECloudCommandResult *)_resultWithCommand:(AWECloudCommandModel *)model
{
    AWECloudCommandResult *result = [[AWECloudCommandResult alloc] init];
    result.fileType = @"unknown";
    result.commandId = model.commandId;
    result.operateTimestamp = [[NSDate date] timeIntervalSince1970];
    // 命令参数解析
    NSDictionary *params = model.params;
    BOOL wifiOnly = [params objectForKey:@"wifiOnly"] ? [[params objectForKey:@"wifiOnly"] boolValue] : YES;
    NSString *filename = [params objectForKey:@"filename"];
    
    if (!filename) {
        result.status = AWECloudCommandStatusFail;
        result.errorMessage = [filename stringByAppendingString:@"Filename should not be empty!"];
        return result;
    }
    
    if (wifiOnly && [AWECloudCommandReachability reachabilityForInternetConnection].currentReachabilityStatus != AWECloudCommandReachableViaWiFi) {
        result.status = AWECloudCommandStatusFail;
        result.errorMessage = @"Network is not wifi!";
        return result;
    }
    
    NSString *absolutePath = [NSHomeDirectory() stringByAppendingPathComponent:filename];
    BOOL isDirectory = NO;
    if (![[NSFileManager defaultManager] fileExistsAtPath:absolutePath isDirectory:&isDirectory]) {
        result.status = AWECloudCommandStatusFail;
        result.errorMessage = [filename stringByAppendingString:@" not found!"];
        return result;
    }
    
    long long totalSize = isDirectory ? [AWECloudDiskUtility folderSizeAtPath:absolutePath] : [AWECloudDiskUtility fileSizeAtPath:absolutePath];
    if (totalSize > kMaxUploadSize) {
        result.status = AWECloudCommandStatusFail;
        result.errorMessage = [filename stringByAppendingString:[NSString stringWithFormat:@" exceed the max upload limit (%@ MB out of %@ MB)", @(totalSize/1024/1024), @(kMaxUploadSize/1024/1024)]];
        return result;
    }
    
    NSArray *allowedFilePaths = [model allowedFilePathsAfterChecking:filename];
    if (!allowedFilePaths.count) {
        result.status = AWECloudCommandStatusFail;
        result.errorMessage = [NSString stringWithFormat:@"%@ is not allowed to upload", filename];
        return result;
    }
    
    NSString *directoryZipPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"cloud_control_data_%@.zip",model.commandId]];
    if (isDirectory) {
        if (allowedFilePaths.count == 1) {
            [SSZipArchive createZipFileAtPath:directoryZipPath withContentsOfDirectory:absolutePath];
        }
        else {
            [SSZipArchive createZipFileAtPath:directoryZipPath withFilesAtPaths:allowedFilePaths];
        }
        result.mimeType = [AWECloudCommandNetworkUtility fileMimeTypeWithPath:directoryZipPath];
        result.data = [NSData dataWithContentsOfFile:directoryZipPath];
        result.fileName = [NSString stringWithFormat:@"%@.zip", [absolutePath lastPathComponent]];
        
        [[NSFileManager defaultManager] removeItemAtPath:directoryZipPath error:nil];
    } else {
        result.mimeType = [AWECloudCommandNetworkUtility fileMimeTypeWithPath:absolutePath];
        result.data = [NSData dataWithContentsOfFile:absolutePath];
        result.fileName = [absolutePath lastPathComponent];
    }
    
    return result;
}

@end


