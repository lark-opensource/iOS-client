//
//  HMDEMCollectTraceData.hpp
//  AWECloudCommand
//
//  Created by maniackk on 2021/5/31.
//

#ifndef HMDEMCollectTraceData_hpp
#define HMDEMCollectTraceData_hpp

#include <stdio.h>
#include <atomic>

#ifdef __cplusplus
extern "C" {
#endif

extern BOOL heimdallrEvilMethodEnabled;
extern BOOL kHMDEMCollectFrameDrop;
extern BOOL kHMDEvilMethodinstrumentationSuccess;

void EMRunloopAddObserver();
void EMRunloopRemoveObserver();
void setEMFilterMillisecond(NSInteger millisecond);
void setEMTTimeoutInterval(NSTimeInterval time);
void setEMFilterEvilMethod(BOOL filterEvilMethod);

void setEMCollectFrameDrop(BOOL collect);
void setEMCollectFrameDropThreshold(NSTimeInterval threshold);

// 丢弃本时间点之前采集的EM
void startEMCollect(void);
// 存入 start -> end 的EM到磁盘
void endEMCollect(NSTimeInterval hitch, bool isScrolling);

/*
 仅用于插桩 LLVM Pass 调用，内部同时记录 walltime, cputime
 耗时测试：
  iPhone11 pro max iOS14.3, debug, 连续执行 1000 次:
   walltime cost: 2.716ms / 2.705ms
   cputime cost:  0 / 0
  连续执行 100w 次:
   walltime cost: 2722.529ms / 2709.840ms
   cputime cost: 2.750ms / 2.757ms
 */
void __heimdallr_instrument_begin(u_int64_t hash);
void __heimdallr_instrument_end(u_int64_t hash);


#ifdef __cplusplus
}
#endif

#endif /* HMDEMCollectTraceData_hpp */
