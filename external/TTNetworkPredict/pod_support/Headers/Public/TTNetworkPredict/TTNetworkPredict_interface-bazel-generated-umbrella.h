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

#import "IVCNetworkSpeedPredictor.h"
#import "IVCNetworkSpeedRecord.h"
#import "VCNetworkSpeedRecord.h"

FOUNDATION_EXPORT double TTNetworkPredictVersionNumber;
FOUNDATION_EXPORT const unsigned char TTNetworkPredictVersionString[];