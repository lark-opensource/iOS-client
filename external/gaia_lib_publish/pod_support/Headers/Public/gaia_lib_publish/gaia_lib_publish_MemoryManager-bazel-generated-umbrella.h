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

#import "Gaia/MemoryManager/AMGAllocationHeader.h"
#import "Gaia/MemoryManager/AMGBaseAllocator.h"
#import "Gaia/MemoryManager/AMGDefaultAllocator.h"
#import "Gaia/MemoryManager/AMGLowLevelAllocator.h"
#import "Gaia/MemoryManager/AMGMemoryLabelNames.h"
#import "Gaia/MemoryManager/AMGMemoryLabels.h"
#import "Gaia/MemoryManager/AMGMemoryManager.h"
#import "Gaia/MemoryManager/AMGMemoryManagerCommon.h"
#import "Gaia/MemoryManager/AMGMemoryPool.h"

FOUNDATION_EXPORT double gaia_lib_publishVersionNumber;
FOUNDATION_EXPORT const unsigned char gaia_lib_publishVersionString[];