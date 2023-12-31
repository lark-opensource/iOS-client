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

#import "React/CoreModulesPlugins.h"
#import "React/RCTExceptionsManager.h"
#import "React/RCTImageEditingManager.h"
#import "React/RCTImageLoader.h"
#import "React/RCTImageStoreManager.h"
#import "React/RCTPlatform.h"

FOUNDATION_EXPORT double ReactVersionNumber;
FOUNDATION_EXPORT const unsigned char ReactVersionString[];