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

#import "HMDHTTPDetailRecord.h"
#import "HMDHTTPRequestInfo.h"
#import "HMDHTTPRequestRecord.h"
#import "HMDHTTPRequestTracker.h"
#import "HMDHTTPTrackerConfig.h"

FOUNDATION_EXPORT double HeimdallrVersionNumber;
FOUNDATION_EXPORT const unsigned char HeimdallrVersionString[];