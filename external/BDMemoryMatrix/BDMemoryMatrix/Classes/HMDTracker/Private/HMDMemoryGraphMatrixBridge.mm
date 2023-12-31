//
//  HMDMemoryGraphMatrixBridge.m
//  BDMemoryMatrix
//
//  Created by zhouyang11 on 2022/5/18.
//

#import "HMDMemoryGraphMatrixBridge.h"
#import "HMDMatrixMonitor+Uploader.h"
#import "memory_logging.h"
#import "MMMatrixDeviceInfo.h"
#import <SSZipArchive/SSZipArchive.h>
#import <Heimdallr/HMDALogProtocol.h>
#import <Heimdallr/HMDDynamicCall.h>
#import <Heimdallr/HeimdallrUtilities.h>
#import <stdio.h>

char* file_uuid; //associated with MemoryGraph
#define safeString(x) ((x)?:"")

@implementation HMDMemoryGraphMatrixBridge

@end

char* getTempZipFileFromData(NSData *data,NSString *name) {
    NSString *rootPath = [HMDMatrixMonitor matrixOfMemoryGraphUploadPath];
    if (![[NSFileManager defaultManager] fileExistsAtPath:rootPath]) {
        if (![[NSFileManager defaultManager] createDirectoryAtPath:rootPath
                                       withIntermediateDirectories:YES
                                                        attributes:nil
                                                             error:nil]) {
            return NULL;
        }
    }
    
    [HMDMatrixMonitor hmdMatrixSessionParamsTracker:rootPath customFilters:nil paramsWriteToFileName:[name stringByDeletingPathExtension]];
    
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

void matrix_memory_dump_callback(const char *content_str,size_t content_size) {
    NSData *reportData = [NSData dataWithBytes:(void *)content_str length:content_size];
    NSString * fileName = [NSString stringWithFormat:@"%@.dat", [NSString stringWithCString:file_uuid encoding:NSUTF8StringEncoding]];
    char* filePath = getTempZipFileFromData(reportData,fileName);
    NSDictionary *category = @{@"status": (filePath != NULL)?@"compress_success":@"compress_failed"};
    DC_OB(DC_CL(HMDTTMonitor, heimdallrTTMonitor), hmdTrackService:metric:category:extra:syncWrite:, @"slardar_memory_matrix_zip", nil, category, nil, YES);
    if (filePath == NULL) {
        HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"Memory data zip failed");
    } else {
        HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"Memory data zip success");
    }
    ::free(filePath);
    ::free((void *)file_uuid);
}

void mg_memory_dump() {
    summary_report_param param;
    param.cpu_arch = safeString([MMMatrixDeviceInfo cpuArch].UTF8String);
    memory_dump(matrix_memory_dump_callback, param);
}
    
void mg_suspend_memory_logging_and_dump_memory(const char *fileUUID) {
    if (strlen(fileUUID) == 0) {
        suspend_memory_logging();//避免matrix和memorygraph死锁
    } else {
        file_uuid = strdup(fileUUID);
        memory_graph_dump = true;
        mg_memory_dump();
        suspend_memory_logging();
    }
}

void hmd_matrix_time_cosume_tracker(long time) {
    DC_OB(DC_CL(HMDTTMonitor, heimdallrTTMonitor), hmdTrackService:metric:category:extra:syncWrite:, @"slardar_matrix_dump_time", @{@"duration":@(time)}, nil, nil, YES);
}

void setup_matrix_dump_time_callback() {
    set_memory_dump_time_cost_callback(hmd_matrix_time_cosume_tracker);
}

void mg_resume_memory_logging(void) {
    resume_memory_logging();
}
