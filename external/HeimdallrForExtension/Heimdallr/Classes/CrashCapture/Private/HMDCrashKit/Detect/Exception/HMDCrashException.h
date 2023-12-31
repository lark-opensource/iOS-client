//
//  HMDCrashException.h
//  CaptainAllred
//
//  Created by sunrunwang on 2019/7/12.
//  Copyright © 2019 sunrunwang. All rights reserved.
//
//  非线程安全 🔒

#ifndef HMDCrashException_h
#define HMDCrashException_h

#include <stdbool.h>
#include "HMDCrashException_Namespace.h"
#include "HMDCrashDetectShared.h"
#include "HMDCrashHeader.h"
#include "stdint.h"

#define TRANSLATION_SIZE 512

#pragma mark - exception write

EXTERN_C

/// Only return true means all set and you could write exception
int create_exception(void);

bool open_exception(void);

#pragma mark - basic info

void basic_info(hmdcrash_detector_context_t *ctx);

#pragma mark - threads

void begin_threads(void);

void begin_thread(bool is_crashed, bool first_entry);

void begin_register(void);

void register_info(const char *name, uintptr_t value, bool first_entry);

void end_register(void);

void begin_backtrace(void);

void backtrace_address(uintptr_t address,bool first_entry);

void backtrace_batch(uintptr_t *addr_array, size_t count);

void end_backtrace(void);

void end_thread(void);

void end_threads(void);

#pragma mark - queue name

void begin_dispatch_name(void);

void write_dispatch_name(const char *name, bool first_entry);

void end_dispatch_name(void);

#pragma mark - async stack

void hmd_crash_begin_stack_record(void);
void hmd_crash_stack_record_thread_name(char *str);
void hmd_crash_stack_record_backtrace(uintptr_t *backtraces,size_t length);
void hmd_crash_end_stack_record(void);

#pragma mark - runtime info

void begin_runtime_info(void);

void write_runtime_sel(const char *sel);

void begin_crash_infos(void);

void write_crash_info(const char *crash_info, bool first_entry);

void end_crash_infos(void);

void end_runtime_info(void);

#pragma mark - thread name

void begin_pthread_name(void);

void write_pthread_name(const char *name, bool first_entry);

void end_pthread_name(void);

#pragma mark - memory

void process_stats(void);

#pragma mark - storage

void write_storage(void);

#pragma mark - dynamic data

void HMDCrashWriteDynamicData(void);
void HMDCrashWriteExtraDynamicData(uint64_t crash_time, uint64_t fault_address, thread_t current_thread, thread_t crash_thread);
void HMDCrashWriteGWPASanInfo(const char *asanStr, uintptr_t *allocateTrace, int allocateTraceLen, uintptr_t *deallocateTrace, int deallocateTraceLen);

#pragma mark - address

void HMDCrashWriteAddressAnalyze(int fd, const char *name, uintptr_t value);

void HMDCrashStackAnalyze(int fd, uintptr_t sp, uint32_t max_count);

#pragma mark - vmmap

void HMDCrashWriteVMMap(int max_vmmap);

void close_exception(void);

void HMDCrashWriteScriptStack(char *crash_data);

#pragma mark - extra crash info

bool HMDCrashOpenExtraCrashInfoFile(void);

void HMDCrashBeginExtraCrashInfo(void);

void HMDCrashWriteExtraCrashInfo(const char *crash_info, bool first_entry);

void HMDCrashEndExtraCrashInfo(void);

void HMDCrashCloseExtraCrashInfoFile(void);

EXTERN_C_END

#endif /* HMDCrashException_h */
