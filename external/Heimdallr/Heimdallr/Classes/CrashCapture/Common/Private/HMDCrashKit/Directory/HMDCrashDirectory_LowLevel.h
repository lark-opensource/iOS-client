//
//  HMDCrashDirectory_LowLevel.h
//  CaptainAllred
//
//  Created by sunrunwang on 2019/7/18.
//  Copyright © 2019 sunrunwang. All rights reserved.
//

#ifndef HMDCrashDirectory_LowLevel_h
#define HMDCrashDirectory_LowLevel_h

#include <stdbool.h>

#pragma mark - Always valid

// expose for crash capture
const char * _Nonnull HMDCrashDirectory_exceptionPath(void);

// expose for crash load launch
void HMDCrashDirectory_setExceptionPath(const char * _Nonnull exceptionPath);

#pragma mark - Not valid for crash load launch

const char *_Nonnull HMDCrashDirectory_exception_tmp_path(void);

const char *_Nonnull HMDCrashDirectory_memory_analyze_path(void);

const char * _Nullable HMDCrashDirectory_vmmap_path(void);

const char * _Nullable HMDCrashDirectory_extend_path(void);

const char * _Nullable HMDCrashDirectory_fd_info_path(void);

const char * _Nullable HMDCrashDirectory_gwpasan_info_path(void);

const char * _Nullable HMDCrashDirectory_NSHomeDirectory_path(void);

size_t                 HMDCrashDirectory_NSHomeDirectory_path_length(void);

const char * _Nullable HMDCrashDirectory_dynamic_data_path(void);

#endif /* HMDCrashDirectory_LowLevel_h */
