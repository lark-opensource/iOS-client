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

#import "ACCExifUtil.h"
#import "ACCPersonalRecommendWords.h"
#import "ACCSecurityFramesCheck.h"
#import "ACCSecurityFramesExporter.h"
#import "ACCSecurityFramesSaver.h"
#import "ACCSecurityFramesUtils.h"

FOUNDATION_EXPORT double CameraClientVersionNumber;
FOUNDATION_EXPORT const unsigned char CameraClientVersionString[];