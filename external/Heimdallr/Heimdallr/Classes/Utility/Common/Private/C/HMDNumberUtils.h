//
//  HMDNumberUtils.h
//  Heimdallr-52562836
//
//  Created by bytedance on 2020/7/2.
//

#ifndef HMDNumberUtils_h
#define HMDNumberUtils_h

#include <stdio.h>
#import <CoreFoundation/CoreFoundation.h>

typedef enum {
    HMDNumberCompareTypeAsc = -1,   // a < b
    HMDNumberCompareTypeEqual,      // a = b
    HMDNumberCompareTypeDesc,       // a > b
} HMDNumberCompareType;

#ifdef __cplusplus
extern "C" {
#endif

HMDNumberCompareType HMD_compareDouble(double first, double second);
    
#ifdef __cplusplus
}
#endif

#endif /* HMDNumberUtils_h */
