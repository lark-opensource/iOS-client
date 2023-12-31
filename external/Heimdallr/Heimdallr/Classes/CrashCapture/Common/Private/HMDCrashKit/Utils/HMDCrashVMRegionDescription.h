//
//  HMDCrashVMRegionDescription.h
//  AWECloudCommand-iOS13.0
//
//  Created by yuanzhangjing on 2019/12/1.
//

#ifndef HMDCrashVMRegionDescription_h
#define HMDCrashVMRegionDescription_h

#include <stdio.h>
#include <mach/vm_statistics.h>
#include <mach/vm_region.h>

const char *hmd_vm_region_user_tag_string(unsigned int user_tag);

const char *hmd_vm_region_share_mode_string(unsigned int share_mode);

#endif /* HMDCrashVMRegionDescription_h */
