//
//  HMDPublicMacro.h
//  Heimdallr
//
//  Created by fengyadong on yesterday
//

#ifndef HMDPublicMacro_h
#define HMDPublicMacro_h

#if !defined(HMD_EXTERN)
#   if defined(__cplusplus)
#       define HMD_EXTERN extern "C"
#   else
#       define HMD_EXTERN extern
#   endif
#endif

#if !defined(HMD_EXTERN_SCOPE_BEGIN)
#   if defined(__cplusplus)
#       define HMD_EXTERN_SCOPE_BEGIN extern "C" {
#   else
#       define HMD_EXTERN_SCOPE_BEGIN
#   endif
#endif

#if !defined(HMD_EXTERN_SCOPE_END)
#   if defined(__cplusplus)
#       define HMD_EXTERN_SCOPE_END }
#   else
#       define HMD_EXTERN_SCOPE_END
#   endif
#endif

#if !defined(HMD_PACKED)
#define HMD_PACKED __attribute__ ((packed))
#endif

#if !defined(HMD_ALIGNED)
#define HMD_ALIGNED(num_bytes) __attribute__((aligned (num_bytes)))
#endif

#endif /* HMDPublicMacro_h */
