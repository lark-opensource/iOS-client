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

#import "Gaia/AMGExport.h"
#import "Gaia/AMGInclude.h"
#import "Gaia/AMGLog.h"
#import "Gaia/AMGPrerequisites.h"
#import "Gaia/AMGPrimitiveNumber.h"
#import "Gaia/AMGPrimitiveVector.h"
#import "Gaia/AMGRefBase.h"
#import "Gaia/AMGSharePtr.h"
#import "Gaia/AMGSystemTime.h"
#import "Gaia/AMGThreadLocal.h"
#import "Gaia/AMGThreadPool.h"
#import "Gaia/Image/AMGImageType.h"
#import "Gaia/Platform/AMGPlatformDef.h"
#import "Gaia/STL/Sort.h"

FOUNDATION_EXPORT double gaia_lib_publishVersionNumber;
FOUNDATION_EXPORT const unsigned char gaia_lib_publishVersionString[];