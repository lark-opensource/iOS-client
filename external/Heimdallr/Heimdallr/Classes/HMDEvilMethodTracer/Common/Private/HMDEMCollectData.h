//
//  HMDEMCollectData.hpp
//  AWECloudCommand
//
//  Created by maniackk on 2021/5/28.
//

#ifndef HMDEMCollectData_hpp
#define HMDEMCollectData_hpp

#include <stdio.h>

#ifdef __cplusplus
extern "C" {
#endif
void writeEMDataToDisk(void *dataMap, integer_t runloopCostTime, uint64_t runloopStartTime, uint64_t runloopEndTime);

void writeCustomEMDataToDisk(void *dataMap, integer_t costTime, uint64_t startTime, uint64_t endTime, NSTimeInterval hitch, bool isScrolling);

// app退出时候，关闭文件
void __heimdallr_instrument_sync_close_file(void);
#ifdef __cplusplus
}
#endif


#endif /* HMDEMCollectData_hpp */
