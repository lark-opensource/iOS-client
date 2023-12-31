//
//  BDHeapedLogInfo.h
//  Musically
//
//  Created by FD on 2022/11/18.
//

#ifndef BDHeapedLogInfo_hpp
#define BDHeapedLogInfo_hpp

#define BDALogMaxLength (8 * 1024)

#ifdef __cplusplus
extern "C" {
#endif

#include <stdio.h>
#include <stdbool.h>
#include "bdloggerbase.h"

typedef struct BDHeapedLogInfo_t BDHeapedLogInfo;
typedef struct BDHeapedLogInfo_t {
    BDHeapedLogInfo *pre;
    BDHeapedLogInfo *next;
    int index;
    bool used;
    void *data; 
    
    // all str in info and log will copied to buf;
    BDLoggerInfo info;
    char *log;
    char buf[BDALogMaxLength];
} BDHeapedLogInfo;

void SetMaxHeapedLogInfoCount(int count);
void SetMaxHeapedLogInfoCountAbandon(int count);

void heaped_log_info_reuse_enqueue(BDHeapedLogInfo *info);
BDHeapedLogInfo *heaped_log_info_reuse_dequeue(void);

BDHeapedLogInfo *log_info_copy_to_heap(const BDLoggerInfo *info, const char *log);

#ifdef __cplusplus
}
#endif

#endif /* BDHeapedLogInfo_hpp */
