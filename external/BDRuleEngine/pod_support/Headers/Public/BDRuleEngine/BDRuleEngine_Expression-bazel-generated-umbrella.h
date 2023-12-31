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

#import "BDREExprConst.h"
#import "BDREExprEnv.h"
#import "BDREExprRunner.h"
#import "BDREFunc.h"
#import "BDREOperator.h"

FOUNDATION_EXPORT double BDRuleEngineVersionNumber;
FOUNDATION_EXPORT const unsigned char BDRuleEngineVersionString[];