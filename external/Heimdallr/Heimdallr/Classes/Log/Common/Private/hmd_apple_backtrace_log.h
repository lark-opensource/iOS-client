//
//  hmd_apple_backtrace_log.h
//  Pods
//
//  Created by 白昆仑 on 2020/2/4.
//

#ifndef hmd_apple_backtrace_log_h
#define hmd_apple_backtrace_log_h

#import <stdio.h>
#import "HMDAsyncThread.h"
#import "HMDLog.h"
#import "hmd_thread_backtrace.h"
#import "HMDHeaderLog.h"
NS_ASSUME_NONNULL_BEGIN



#ifdef __cplusplus
extern "C" {
#endif

// 注：调用成功后返回的char*需要手动释放
char *_Nullable hmd_backtrace_json_log_of_thread(hmdbt_backtrace_t *backtrace);

// 注：确保使用前调用hmd_setup_log_header()
char *_Nullable hmd_apple_backtraces_log_of_all_threads(thread_t keyThread,
                                                        unsigned long maxThreadCount,
                                                        unsigned long skippedDepth,
                                                        bool suspend,
                                                        HMDLogType type,
                                                        char *_Nullable exceptionField,
                                                        char *_Nullable reasonField,
                                                        bool needSymbol = false);

// 注：确保使用前调用hmd_setup_log_header()
char *_Nullable hmd_apple_backtraces_log_of_threads(hmdbt_backtrace_t *backtraces,
                                                    int backtrace_size,
                                                    thread_t keyThread,
                                                    HMDLogType type,
                                                    char *_Nullable exceptionField,
                                                    char *_Nullable reasonField,
                                                    bool needSymbolName = false);

// 生成单个线程的堆栈（不包含header和image信息）
char *hmd_apple_clear_backtrace_log_of_thread(hmdbt_backtrace_t *backtrace);
#ifdef __cplusplus
}  // extern "C"
#endif

NS_ASSUME_NONNULL_END

#endif /* hmd_apple_backtrace_log_h */
