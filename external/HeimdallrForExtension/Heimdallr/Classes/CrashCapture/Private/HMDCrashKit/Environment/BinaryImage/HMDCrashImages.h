//
//  HMDCrashBinaryImage.h
//  CaptainAllred
//
//  Created by sunrunwang on 2019/7/10.
//  Copyright © 2019 sunrunwang. All rights reserved.
//

#ifndef HMDCrashImages_h
#define HMDCrashImages_h

#include <stdio.h>

#ifdef __cplusplus
extern "C" {
#endif

void setupWithFD(void);
void setImageFD(int fd);
void writeImageOnCrash(void);

#ifdef __cplusplus
} // extern "C"
#endif

#endif /* HMDCrashImages_h */
