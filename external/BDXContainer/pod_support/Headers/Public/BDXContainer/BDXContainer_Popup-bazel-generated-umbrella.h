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

#import "BDXPopupContainerService.h"
#import "BDXPopupSchemaParam.h"
#import "BDXPopupViewController+Gesture.h"
#import "BDXPopupViewController.h"

FOUNDATION_EXPORT double BDXContainerVersionNumber;
FOUNDATION_EXPORT const unsigned char BDXContainerVersionString[];