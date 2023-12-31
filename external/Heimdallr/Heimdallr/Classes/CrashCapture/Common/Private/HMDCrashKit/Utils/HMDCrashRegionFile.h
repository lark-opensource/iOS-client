//
//  HMDCrashRegionFile.h
//  Pods
//
//  Created by yuanzhangjing on 2019/12/14.
//

#ifndef HMDCrashRegionFile_h
#define HMDCrashRegionFile_h

#include <stdio.h>

#ifdef __cplusplus
extern "C" {
#endif

void hmdcrash_init_filename(void);

int hmdcrash_filename(uint64_t address, void * buffer, uint32_t buffersize);


#ifdef __cplusplus
} // extern "C"
#endif

#endif /* HMDCrashRegionFile_h */
