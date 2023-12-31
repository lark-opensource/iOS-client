
/*!@header HMDCrashLoadLogger+Path.h
   @author somebody
   @abstract Log Status of Crash Load Launch
 */


#ifndef HMDCrashLoadLogger_Path_h
#define HMDCrashLoadLogger_Path_h

#include "HMDCrashLoadMacro.h"

#ifdef HMD_CLOAD_DEBUG

#define CLOAD_PATH(__path__) (HMDCrashLoadLogger_path(__path__).UTF8String)

NSString * _Nullable HMDCrashLoadLogger_path(NSString * _Nonnull path);

#else  /* !HMD_CLOAD_DEBUG */

#define CLOAD_PATH(__path__) (__path__)

#endif /* HMD_CLOAD_DEBUG */

#endif /* HMDCrashLoadLogger_Path_h */
