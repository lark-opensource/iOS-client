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

#import "BDRuleEngineDelegateCenter.h"
#import "BDRuleEngineKVStore.h"
#import "BDRuleEngineLogger.h"
#import "BDRuleEngineReporter.h"
#import "BDRuleEngineSettings.h"

FOUNDATION_EXPORT double BDRuleEngineVersionNumber;
FOUNDATION_EXPORT const unsigned char BDRuleEngineVersionString[];