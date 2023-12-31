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

#import "BDUGShareBaseUtil.h"
#import "BDUGShareError.h"
#import "BDUGShareEvent.h"
#import "BDUGShareEventManager.h"
#import "BDUGShareImageUtil.h"
#import "BDUGShareSettingsUtil.h"

FOUNDATION_EXPORT double BDUGShareVersionNumber;
FOUNDATION_EXPORT const unsigned char BDUGShareVersionString[];