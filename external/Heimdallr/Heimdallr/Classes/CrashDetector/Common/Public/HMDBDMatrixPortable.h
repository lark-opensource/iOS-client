//
//  HMDBDMatrixPortable.h
//  Pods
//
//  Created by bytedance on 2023/4/12.
//

#ifndef HMDBDMatrixPortable_h
#define HMDBDMatrixPortable_h

#include <stdint.h>

#ifndef HMD_BD_MATRIX_ATTR
#ifdef  HMD_THIS_IS_BD_MATRIX_FILE
#define HMD_BD_MATRIX_ATTR
#else
#define HMD_BD_MATRIX_ATTR __attribute__((unavailable("Heimdallr Internal Private, not exported")))
#endif
#endif

// 该文件仅限 BDMatrix 使用
bool HMDBDMatrixPortable_crashTrackerFinishedDetection(void) HMD_BD_MATRIX_ATTR;

// 该文件仅限 BDMatrix 使用, 只有 crashTrackerFinishedDetection = YES 该值有效
bool HMDBDMatrixPortable_lastTimeCrash(void) HMD_BD_MATRIX_ATTR;

// 该文件仅限 BDMatrix 使用, 只有 crashTrackerFinishedDetection = YES 该值有效
uint64_t HMDBDMatrixPortable_lastCrashUsedVM(void) HMD_BD_MATRIX_ATTR;

// 该文件仅限 BDMatrix 使用, 只有 crashTrackerFinishedDetection = YES 该值有效
uint64_t HMDBDMatrixPortable_lastCrashTotalVM(void) HMD_BD_MATRIX_ATTR;


#endif /* HMDBDMatrixPortable_h */
