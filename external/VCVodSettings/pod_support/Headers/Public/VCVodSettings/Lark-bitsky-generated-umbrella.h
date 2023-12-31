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

#import "VodSettingsConfigEnv.h"
#import "VodSettingsFetcherUtils.h"
#import "VodSettingsHeader.h"
#import "VodSettingsManager.h"
#import "VodSettingsNetProtocol.h"

FOUNDATION_EXPORT double VCVodSettingsVersionNumber;
FOUNDATION_EXPORT const unsigned char VCVodSettingsVersionString[];
