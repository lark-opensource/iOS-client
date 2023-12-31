//
//  hmd_memory_logger.c
//  Heimdallr
//
//  Created by zhouyang11 on 2023/7/18.
//

#include <stdio.h>
#include "hmd_memory_logger.h"
#import "HMDCrashDynamicSavedFiles.h"
#include <sys/time.h>
#import "HMDFileTool.h"

static FILE *fp = NULL;

static const char* init_hmd_memory_log_file_path(void) {
    static const char* tmpPath = nullptr;
    if (tmpPath == nullptr) {
        NSString *homePath = NSHomeDirectory();
        NSString* tmpDirectoryPath = [homePath stringByAppendingPathComponent:@"Library/Heimdallr/SlardarMalloc"];
        hmdCheckAndCreateDirectory(tmpDirectoryPath);
        NSString *fileName = [NSString stringWithFormat:@"memory_log_file_%f", [[NSDate date] timeIntervalSince1970]];
        NSString *filePath = [tmpDirectoryPath stringByAppendingPathComponent:fileName];
        HMDCrashDynamicSavedFiles_registerFilePath([filePath substringFromIndex:homePath.length+1].UTF8String);
        tmpPath = strdup(filePath.UTF8String);
    }
    return tmpPath;
}

long getCurrentTime()

{
    struct timeval tv;
    gettimeofday(&tv,NULL);
    return tv.tv_sec * 1000 + tv.tv_usec / 1000;
}

void hmd_memory_log_start(void)
{
    if(!fp) {
        const char* log_path = init_hmd_memory_log_file_path();
        fp = fopen(log_path, "w");
    }
}
 
void hmd_memory_log_to_file(const char *format,...)
{
    if(fp) fprintf(fp,"%ld:", getCurrentTime());
    va_list ap;
    va_start(ap,format);
    //vprintf(format,ap);          // 打印到串口
    if(fp) vfprintf(fp,format,ap); // 写文件
    va_end(ap);
    fflush(fp);
}
 
void hmd_memory_log_end(void)
{
    if(fp)
    {
        fflush(fp);
        fclose(fp);
        fp = NULL;
    }
}
