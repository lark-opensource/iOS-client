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

#import "AGFXLib/Context.h"
#import "AGFXLib/PBFConfig.h"
#import "AGFXLib/PBFSimulator.h"
#import "AGFXLib/SSFR.es31.h"
#import "AGFXLib/SSFR.h"
#import "AGFXLib/SSFR.shader.h"

FOUNDATION_EXPORT double AGFX_pubVersionNumber;
FOUNDATION_EXPORT const unsigned char AGFX_pubVersionString[];