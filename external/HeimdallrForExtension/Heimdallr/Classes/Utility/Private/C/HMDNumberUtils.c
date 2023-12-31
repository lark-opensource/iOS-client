//
//  HMDNumberUtils.c
//  Heimdallr-52562836
//
//  Created by bytedance on 2020/7/2.
//

#include "HMDNumberUtils.h"

HMDNumberCompareType HMD_compareDouble(double first, double second) {
    if(fabs(first - second) < DBL_EPSILON) {
        return HMDNumberCompareTypeEqual;
    }
    
    if (first < second) {
        return HMDNumberCompareTypeAsc;
    }
    
    return HMDNumberCompareTypeDesc;
}
