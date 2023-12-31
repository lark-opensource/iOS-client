//
//  HMDOCObjectAnalyzerInternal.h
//  Heimdallr
//
//  Created by bytedance on 2022/11/3.
//

#ifndef HMDOCObjectAnalyzerInternal_h
#define HMDOCObjectAnalyzerInternal_h

#include <stdint.h>
#include <os/base.h>
#include "HMDMacro.h"
#import <Foundation/Foundation.h>

#define hmd_objc_analyzer_read_rawISA_return_zero_if_not_exist \
Heimdallr_object_analyzer_is_trying_to_read_ISA_info_from_unsafe_object_if_it_crashed_this_object_is_over_release_or_smashed

HMD_EXTERN uintptr_t hmd_objc_analyzer_read_rawISA_return_zero_if_not_exist(void * _Nonnull object) OS_NOINLINE;


#endif /* HMDOCObjectAnalyzerInternal_h */
