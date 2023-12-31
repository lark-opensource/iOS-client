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

#import "CGSize+NLE.h"
#import "NLEBundleDataSource.h"
#import "NLECaptureOutput.h"
#import "NLEConstDefinition.h"
#import "NLEInterface.h"
#import "NLETextTemplateInfo.h"
#import "NLEVECallBackProtocol.h"

FOUNDATION_EXPORT double NLEPlatformVersionNumber;
FOUNDATION_EXPORT const unsigned char NLEPlatformVersionString[];