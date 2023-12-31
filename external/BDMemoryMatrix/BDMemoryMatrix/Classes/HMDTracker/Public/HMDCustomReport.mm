//
//  HMDCustomReport.cpp
//  BDMemoryMatrix
//
//  Created by Ysurfer on 2023/3/31.
//

#import "HMDCustomReport.h"
#import "memory_logging.h"
#import "MMMatrixDeviceInfo.h"
#import "HMDMatrixMonitor.h"
#import "HMDMatrixMonitor+Uploader.h"
#import <SSZipArchive/SSZipArchive.h>
#import <Heimdallr/HMDDynamicCall.h>
#import <Heimdallr/HeimdallrUtilities.h>
#import <stdio.h>
#import <Heimdallr/HMDALogProtocol.h>
#import <Heimdallr/HMDAppExitReasonDetector.h>
#import <Heimdallr/HMDSessionTracker.h>

@implementation HMDCustomReport

@end

static int reportCount = 0;
static char *matrixCustomInfo = NULL;
#define safeString(x) ((x)?:"")

char* getCustomZipFileFromData(NSData *data,NSString *name) {
    NSString *rootPath = [HMDMatrixMonitor matrixOfCustomUploadPath];
    NSString *sessionID = [HMDSessionTracker sharedInstance].eternalSessionID;
    rootPath = [rootPath stringByAppendingPathComponent:sessionID];
    if (![[NSFileManager defaultManager] fileExistsAtPath:rootPath]) {
        if (![[NSFileManager defaultManager] createDirectoryAtPath:rootPath
                                       withIntermediateDirectories:YES
                                                        attributes:nil
                                                             error:nil]) {
            return NULL;
        }
    }
    if (matrixCustomInfo == NULL) {
        [HMDMatrixMonitor hmdMatrixSessionParamsTracker:rootPath customFilters:nil paramsWriteToFileName:[name stringByDeletingPathExtension]];
    } else {
        [HMDMatrixMonitor hmdMatrixSessionParamsTracker:rootPath customFilters:[NSString stringWithUTF8String:matrixCustomInfo] paramsWriteToFileName:[name stringByDeletingPathExtension]];
    }
    
    NSString *path = [rootPath stringByAppendingPathComponent:name];

    SSZipArchive *zipArchive = [[SSZipArchive alloc] initWithPath:path]; //compression
    BOOL success = [zipArchive open];
    if (!success) {
        return NULL;
    }

    if (![zipArchive writeData:data filename:@"data.json" withPassword:nil]) {
        [zipArchive close];
        return NULL;
    }

    if (![zipArchive close]) {
        return NULL;
    }
    return strdup([path cStringUsingEncoding:NSUTF8StringEncoding]);
}

void custom_memory_dump_callback(const char *content_str,size_t content_size) {
    NSData *reportData = [NSData dataWithBytes:(void *)content_str length:content_size];
    reportCount += 1;
    NSString *sessionID = [HMDSessionTracker sharedInstance].eternalSessionID;
    NSString *matrixName = [[NSString alloc] init];
    if (matrixCustomInfo == NULL) {
        matrixName = [NSString stringWithFormat:@"%@_%@_%d",sessionID,@"custom",reportCount];
    } else {
        NSString *customInfo = [NSString stringWithUTF8String:matrixCustomInfo];
        matrixName = [NSString stringWithFormat:@"%@_%@_%d_%@",sessionID,@"custom",reportCount,customInfo];
    }
    [HMDAppExitReasonDetector triggerCurrentEnvironmentInformationSavingWithAction:matrixName];
    NSString * fileName = [NSString stringWithFormat:@"%@.dat",matrixName];
    char* filePath = getCustomZipFileFromData(reportData,fileName);
    NSDictionary *category = @{@"status": (filePath != NULL)?@"compress_success":@"compress_failed"};
    DC_OB(DC_CL(HMDTTMonitor, heimdallrTTMonitor), hmdTrackService:metric:category:extra:syncWrite:, @"slardar_custom_matrix_zip", nil, category, nil, YES);
    if (filePath == NULL) {
        HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"Memory data zip failed");
    } else {
        HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"Memory data zip success");
    }
    matrixCustomInfo = NULL;
    ::free(filePath);
}

void matrixCustomCollect() {
    summary_report_param param;
    param.cpu_arch = safeString([MMMatrixDeviceInfo cpuArch].UTF8String);
    memory_dump(custom_memory_dump_callback, param);
}

void matrixCustomCollectWithInfo(char *customInfo) {
    summary_report_param param;
    param.cpu_arch = safeString([MMMatrixDeviceInfo cpuArch].UTF8String);
    if (memory_dump(custom_memory_dump_callback, param)) {
        matrixCustomInfo = customInfo;
    }
}
