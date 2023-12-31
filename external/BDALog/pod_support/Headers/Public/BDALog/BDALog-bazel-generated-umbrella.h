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

#import "BDALogHelper.h"
#import "BDALogProtocolHelper.h"
#import "BDAgileLog.h"
#import "BDAgileLogs.h"
#import "bdloggerbase.h"

FOUNDATION_EXPORT double BDALogVersionNumber;
FOUNDATION_EXPORT const unsigned char BDALogVersionString[];