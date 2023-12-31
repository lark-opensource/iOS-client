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

#import "CoreModules/CoreModulesPlugins.h"
#import "CoreModules/RCTExceptionsManager.h"
#import "CoreModules/RCTImageEditingManager.h"
#import "CoreModules/RCTImageLoader.h"
#import "CoreModules/RCTImageStoreManager.h"
#import "CoreModules/RCTPlatform.h"

FOUNDATION_EXPORT double CoreModulesVersionNumber;
FOUNDATION_EXPORT const unsigned char CoreModulesVersionString[];
