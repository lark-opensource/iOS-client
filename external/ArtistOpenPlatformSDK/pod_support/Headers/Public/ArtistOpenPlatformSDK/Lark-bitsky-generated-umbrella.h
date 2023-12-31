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

#import "ARTLogger.h"
#import "ARTSDKDefines.h"
#import "ARTEffectBaseDownloadTask.h"
#import "ARTEffectCommonDownloadTask.h"
#import "ARTEffectConfig.h"
#import "ARTEffectDefines.h"
#import "ARTEffectDownloadQueue.h"
#import "ARTEffectHeader.h"
#import "ARTEffectManager.h"
#import "ARTEffectModel.h"

FOUNDATION_EXPORT double ArtistOpenPlatformSDKVersionNumber;
FOUNDATION_EXPORT const unsigned char ArtistOpenPlatformSDKVersionString[];
