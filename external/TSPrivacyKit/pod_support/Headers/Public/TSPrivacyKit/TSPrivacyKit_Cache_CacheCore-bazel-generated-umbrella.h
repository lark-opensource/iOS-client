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

#import "TSPKCacheEnv.h"
#import "TSPKCacheProcessor.h"
#import "TSPKCacheStore.h"
#import "TSPKCacheStrategyGenerator.h"
#import "TSPKCacheUpdateStrategy.h"

FOUNDATION_EXPORT double TSPrivacyKitVersionNumber;
FOUNDATION_EXPORT const unsigned char TSPrivacyKitVersionString[];