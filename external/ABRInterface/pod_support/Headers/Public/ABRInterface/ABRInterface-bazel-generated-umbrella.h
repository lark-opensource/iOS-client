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

#import "IVCABRBufferInfo.h"
#import "IVCABRDeviceInfo.h"
#import "IVCABRInfoListener.h"
#import "IVCABRModule.h"
#import "IVCABRModuleSpeedRecord.h"
#import "IVCABRPlayStateSupplier.h"
#import "IVCABRStream.h"
#import "VCABRAudioStream.h"
#import "VCABRBufferInfo.h"
#import "VCABRConfig.h"
#import "VCABRDeviceInfo.h"
#import "VCABRResult.h"
#import "VCABRResultElement.h"
#import "VCABRVideoStream.h"

FOUNDATION_EXPORT double ABRInterfaceVersionNumber;
FOUNDATION_EXPORT const unsigned char ABRInterfaceVersionString[];