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

#import "ByteNNABTest.h"
#import "ByteNNBasicType.h"
#import "ByteNNEngine.h"
#import "espresso.h"

FOUNDATION_EXPORT double bytenn_iosVersionNumber;
FOUNDATION_EXPORT const unsigned char bytenn_iosVersionString[];