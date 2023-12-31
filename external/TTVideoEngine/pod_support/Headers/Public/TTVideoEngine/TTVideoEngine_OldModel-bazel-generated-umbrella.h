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

#import "TTVideoEngineInfoModel.h"
#import "TTVideoEngineMaskInfo.h"
#import "TTVideoEngineThumbInfo.h"

FOUNDATION_EXPORT double TTVideoEngineVersionNumber;
FOUNDATION_EXPORT const unsigned char TTVideoEngineVersionString[];