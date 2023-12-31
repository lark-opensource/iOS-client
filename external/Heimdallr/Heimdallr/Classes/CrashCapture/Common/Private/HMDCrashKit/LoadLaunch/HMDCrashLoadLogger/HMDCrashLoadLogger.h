
/*!@header HMDCrashLoadLogger.h
   @author somebody
   @abstract Log Status of Crash Load Launch
 */


#ifndef HMDCrashLoadLogger_h
#define HMDCrashLoadLogger_h

#include "HMDCrashLoadMacro.h"

#if defined CLOAD_LOG
#error critical error CLOAD_LOG pre-defined, please figure out why it is defined
#endif

#ifdef HMD_CLOAD_DEBUG

void HMDCrashLoadLogger_format(const char * _Nonnull file, int line,
                               const char * _Nonnull format, ...)
                               __attribute__ ((format(printf, 3, 4)));

#define CLOAD_LOG(__format__, ...) \
    HMDCrashLoadLogger_format(__FILE__, __LINE__, "" __format__, ## __VA_ARGS__)

#else /* !HMD_CLOAD_DEBUG */

#define CLOAD_LOG(__format__, ...)

#endif /* HMD_CLOAD_DEBUG */

#endif /* HMDCrashLoadLogger_h */
