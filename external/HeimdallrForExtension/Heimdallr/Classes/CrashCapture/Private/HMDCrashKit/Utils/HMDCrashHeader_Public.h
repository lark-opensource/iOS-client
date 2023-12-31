//
//  HMDCrashHeader_Public.h
//  CaptainAllred
//
//  Created by sunrunwang on 2019/8/1.
//  Copyright © 2019 sunrunwang. All rights reserved.
//

#ifndef HMDCrashHeader_Public_h
#define HMDCrashHeader_Public_h

typedef enum {
    HMDCrashTypeMissing,
    HMDCrashTypeMachException,
    HMDCrashTypeFatalSignal,
    HMDCrashTypeCPlusPlus,
    HMDCrashTypeNSException,
    HMDCrashTypeCplusplus = HMDCrashTypeCPlusPlus,
} HMDCrashType;

#endif /* HMDCrashHeader_Public_h */
