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

#import "BDBDConfiguration.h"
#import "BDBDMain+local.h"
#import "BDBDMain.h"
#import "BDDDYHTSHeader.h"

FOUNDATION_EXPORT double QuaterbackVersionNumber;
FOUNDATION_EXPORT const unsigned char QuaterbackVersionString[];