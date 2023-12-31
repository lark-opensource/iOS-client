//
//  HMDCrashLoadMacro.h
//  Heimdallr
//
//  Created by sunrunwang on 2024/08/08.
//


#ifndef HMDCrashLoadMacro_h
#define HMDCrashLoadMacro_h

#ifdef DEBUG
#define HMD_CLOAD_DEBUG
#else
#define HMD_CLOAD_RELEASE
#endif

#if defined HMD_CLOAD_DEBUG && defined HMD_CLOAD_RELEASE
#error can not define both HMD_CLOAD_DEBUG and HMD_CLOAD_RELEASE \
this will result in compile error
#endif

#endif /* HMDCrashLoadMacro_h */
