//
//  HMDCrashDirectory_LowLevel.h
//  CaptainAllred
//
//  Created by sunrunwang on 2019/7/18.
//  Copyright © 2019 sunrunwang. All rights reserved.
//

#ifndef HMDCrashDirectory_LowLevel_h
#define HMDCrashDirectory_LowLevel_h

#pragma FileBuffer open

#include <stdbool.h>

const char * _Nonnull HMDCrashDirectory_exceptionPath(void);    // used when crash to open IO buffer

const char * _Nullable HMDCrashDirectory_homePath(void);

const char *_Nonnull HMDCrashDirectory_exception_tmp_path(void);

const char *_Nonnull HMDCrashDirectory_memory_analyze_path(void);

const char * _Nullable HMDCrashDirectory_vmmap_path(void);

const char * _Nullable HMDCrashDirectory_crash_info_path(void);

const char * _Nullable HMDCrashDirectory_extend_path(void);

const char * _Nullable HMDCrashDirectory_fd_info_path(void);

const char * _Nullable HMDCrashDirectory_gwpasan_info_path(void);

const char * _Nullable HMDApplication_home_path(void);

#endif /* HMDCrashDirectory_LowLevel_h */
