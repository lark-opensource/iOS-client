#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "HMDLogHelper.h"
#import "HMDLogUploader.h"
#import "HMDLogWrapper.h"

FOUNDATION_EXPORT double HeimdallrVersionNumber;
FOUNDATION_EXPORT const unsigned char HeimdallrVersionString[];