//
//  HMDCDSaveCore.hpp
//  Heimdallr
//
//  Created by maniackk on 2020/10/14.
//

#ifndef HMDCDSaveCore_h
#define HMDCDSaveCore_h

#include "HMDMacro.h"
#include "HMDCrashDetectShared.h"

HMD_EXTERN_SCOPE_BEGIN
    
void hmd_handle_coredump(struct hmdcrash_detector_context *crash_detector_context,
                         struct hmd_crash_env_context *envContextPointer,
                         bool force);

void hmd_cd_set_basePath(const char *path);
void hmd_cd_set_minFreeDiskUsageMB(unsigned long minFreeDiskUsageMB);
void hmd_cd_set_maxCDFileSizeMB(unsigned long maxCDFileSizeMB);
void hmd_cd_set_isOpen(bool isOpen);
void hmd_cd_set_dumpNSException(BOOL isDump);
void hmd_cd_set_dumpCPPException(BOOL isDump);
void hmd_cd_markReady(void);

HMD_EXTERN_SCOPE_END

#endif /* HMDCDSaveCore_h */
