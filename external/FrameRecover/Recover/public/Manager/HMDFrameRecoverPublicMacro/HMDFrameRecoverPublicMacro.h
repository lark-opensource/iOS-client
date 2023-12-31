//
//  HMDFrameRecoverPublicMacro.h
//  Heimdallr
//
//  Created by someone on yesterday
//

#ifndef HMDFrameRecoverPublicMacro_h
#define HMDFrameRecoverPublicMacro_h

#if !defined(HMDFC_EXTERN)
#   if defined(__cplusplus)
#       define HMDFC_EXTERN extern "C"
#   else
#       define HMDFC_EXTERN extern
#   endif
#endif

#if !defined(HMDFC_EXTERN_SCOPE_BEGIN)
#   if defined(__cplusplus)
#       define HMDFC_EXTERN_SCOPE_BEGIN extern "C" {
#   else
#       define HMDFC_EXTERN_SCOPE_BEGIN
#   endif
#endif

#if !defined(HMDFC_EXTERN_SCOPE_END)
#   if defined(__cplusplus)
#       define HMDFC_EXTERN_SCOPE_END }
#   else
#       define HMDFC_EXTERN_SCOPE_END
#   endif
#endif

#if !defined(HMDFC_PACKED)
#define HMDFC_PACKED __attribute__ ((packed))
#endif

#if !defined(HMDFC_ALIGNED)
#define HMDFC_ALIGNED(num_bytes) __attribute__((aligned (num_bytes)))
#endif

#if !defined(HMDFC_DEPRECATED)
#define HMDFC_DEPRECATED __attribute__((deprecated))
#endif

#if !defined(HMDFC_MSG_DEPRECATED)
#if __has_feature(attribute_deprecated_with_message)
    #define HMDFC_MSG_DEPRECATED(s) __attribute__((deprecated(s)))
#else
    #define HMDFC_MSG_DEPRECATED(s) __attribute__((deprecated))
#endif
#endif

#endif /* HMDFrameRecoverPublicMacro_h */
