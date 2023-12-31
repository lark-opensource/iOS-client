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

#import "BDClassInfo.h"
#import "BDMappingStrategy.h"
#import "BDModel.h"
#import "BDModelFacade.h"
#import "BDModelMappingDefine.h"
#import "NSObject+BDModel.h"

FOUNDATION_EXPORT double BDModelVersionNumber;
FOUNDATION_EXPORT const unsigned char BDModelVersionString[];