//
//  HMDDwarfConfig.h
//  Pods
//
//  Created by yuanzhangjing on 2020/2/5.
//

#ifndef HMDDwarfConfig_h
#define HMDDwarfConfig_h

#include "HMDCompactUnwindConfig.h"

#if defined(__arm64__) && HMD_USE_COMPACT_UNWIND
#define HMD_USE_DWARF_UNWIND 1
#endif

#endif /* HMDDwarfConfig_h */
