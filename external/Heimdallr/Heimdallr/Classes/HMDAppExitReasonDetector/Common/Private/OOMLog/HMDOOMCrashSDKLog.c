//
//  HMDOOMCrashSDKLog.c
//
//
//  Created by bytedance on 2020/3/5.
//

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <unistd.h>
#include <pthread.h>
#include <string.h>
#import <sys/mman.h>
#import <dispatch/queue.h>
#include "HMDOOMCrashSDKLog.h"
#include <sys/time.h>


// 数据存储的数量
#define kMaxCount 500
#define kDeleteCount 300

// 每条数据存储的长度
#define kMessageLength 140
#define kInfoLength 200

static FILE *fp;
static int count = 0;
static long po = 0;
static dispatch_queue_t queue_t;

static pthread_mutex_t mutex_t = PTHREAD_MUTEX_INITIALIZER;

FILE *hmd_oom_crash_open_file(const char *path) {
    if(path == NULL) return NULL;
    
    FILE *file;
    file = fopen(path, "w+");
    count = 0;
    po = 0;
    
    return file;
}

void hmd_oom_crash_close_log(void) {
    pthread_mutex_lock(&mutex_t);
    if (!fp) {
        pthread_mutex_unlock(&mutex_t);
        return;
    }
    fclose(fp);
    fp = NULL;
    pthread_mutex_unlock(&mutex_t);
}

bool hmd_oom_crash_open_log(const char *path) {
    pthread_mutex_lock(&mutex_t);
    fp = hmd_oom_crash_open_file(path);
    
    if (!queue_t) {
        queue_t = dispatch_queue_create("com.heimdallr.oomcrash.sdklog", DISPATCH_QUEUE_SERIAL);
    }
    
    pthread_mutex_unlock(&mutex_t);
    return fp != NULL;
}

// 防止本地存储数据量f过大
void hmd_oom_cut_content_if_needed(void) {
    if (count == kDeleteCount) {
        po = ftell(fp);
    }
    
    // 删除kDeleteCount之前的数据
    if (count >= kMaxCount) {
        long current = ftell(fp);
        long length = current - po;
        char *buffer = (char*)malloc(sizeof(char)*length);
        
        // 读取截取点后面内容
        fseek(fp, po, SEEK_SET);
        fread(buffer, length, 1, fp);
        
        // 覆写文本
        rewind(fp);
        fwrite(buffer, length, 1, fp);
        
        // 截断多余部分
        ftruncate(fp->_file, length);
        fflush(fp);
        free(buffer);
        count = count - kDeleteCount;
        po = 0;
    }
    
}

void hmd_oom_crash_log_str(const char *level, const char *file, int line, const char *format, ...) {
    
    char szBuf[100];
    time_t tmCurrent = time(NULL);
    strftime(szBuf, sizeof(szBuf), "%m-%d %T", localtime(&tmCurrent));
    
    struct timeval tv;
    gettimeofday(&tv, NULL);
    __darwin_suseconds_t usec = tv.tv_usec;

    pthread_mutex_lock(&mutex_t);
    if (!fp || !queue_t) {
        pthread_mutex_unlock(&mutex_t);
        return;
    }

    if (file) {
        const char* lastFile = strrchr(file, '/');
        if (lastFile != NULL) {
            file = lastFile + 1;
        }
    }
    
    if (format == NULL) {
        format = "";
    }

    va_list args;
    va_start(args, format);
    char message[kMessageLength];
    vsnprintf(message, kMessageLength, format, args);
    va_end(args);
    
    char *info = malloc(sizeof(char) * kInfoLength);
    snprintf(info, kInfoLength, "%s [%s.%06d] [%s:%d] %s", level, szBuf, usec, file, line, message);

    dispatch_block_t block = ^{
        if (fp) {
            fprintf(fp, "%s\n", info);
            fflush(fp);
            count++;
            hmd_oom_cut_content_if_needed();
        }
        free(info);
    };
    
    // 如果在主线程，需要在子线程操作，防止写文件卡死
    if (pthread_main_np()) {
        pthread_mutex_unlock(&mutex_t);
        dispatch_async(queue_t, ^{
            pthread_mutex_lock(&mutex_t);
            block();
            pthread_mutex_unlock(&mutex_t);
        });
    } else {
        block();
        pthread_mutex_unlock(&mutex_t);
    }
}
