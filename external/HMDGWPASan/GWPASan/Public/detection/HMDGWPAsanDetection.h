//
//  HMDGWPAsanDetection.h
//  HMDGWPAsanDetection
//
//  Created by someone at yesterday
//

#ifndef HMDGWPAsanDetection_h
#define HMDGWPAsanDetection_h

#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>

#include "HMDGWPASanPublicMacro.h"

HMD_ASAN_EXTERN_SCOPE_BEGIN

bool detect_gwp_asan(uintptr_t faultAddress,
                       char * _Nonnull reasonString,
                       int reasonStringLength,
                       uintptr_t * _Nonnull allocateTrace,
                       int * _Nonnull allocateTraceLen,
                       uintptr_t * _Nonnull deallocateTrace,
                       int *  _Nonnull deallocateTraceLen);

HMD_ASAN_EXTERN_SCOPE_END

#endif /* HMDGWPAsanDetection_h */
