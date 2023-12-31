//
//  HMDCDMachO.hpp
//  AWECloudCommand
//
//  Created by maniackk on 2020/10/13.
//

#ifndef HMDCDMachO_hpp
#define HMDCDMachO_hpp

#include <stdio.h>
#include "hmd_machine_context.h"

#define kCOREDUMPMAGIC 0xcedda0ce  //don't modified

bool saveCore(unsigned long fileSize, const char *path, struct hmd_crash_env_context *envContextPointer, double crashTime);

#endif /* HMDCDMachO_hpp */
