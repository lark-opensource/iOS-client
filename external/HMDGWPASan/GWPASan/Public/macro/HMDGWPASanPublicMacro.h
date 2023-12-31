//
//  HMDGWPASanPublicMacro.h
//  Heimdallr
//
//  Created by sunrunwang on yesterday
//

#ifndef HMDGWPASanPublicMacro_h
#define HMDGWPASanPublicMacro_h

#if !defined(HMD_ASAN_EXTERN)
#   if defined(__cplusplus)
#       define HMD_ASAN_EXTERN extern "C"
#   else
#       define HMD_ASAN_EXTERN extern
#   endif
#endif

#if !defined(HMD_ASAN_EXTERN_SCOPE_BEGIN)
#   if defined(__cplusplus)
#       define HMD_ASAN_EXTERN_SCOPE_BEGIN extern "C" {
#   else
#       define HMD_ASAN_EXTERN_SCOPE_BEGIN
#   endif
#endif

#if !defined(HMD_ASAN_EXTERN_SCOPE_END)
#   if defined(__cplusplus)
#       define HMD_ASAN_EXTERN_SCOPE_END }
#   else
#       define HMD_ASAN_EXTERN_SCOPE_END
#   endif
#endif

#endif /* HMDGWPASanPublicMacro */
