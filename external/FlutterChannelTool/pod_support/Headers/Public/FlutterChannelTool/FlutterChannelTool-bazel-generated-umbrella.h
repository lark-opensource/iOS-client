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

#import "FlutterChannelTool.h"
#import "NSDictionary+Safe.h"
#import "NSObject+DartCodec.h"

FOUNDATION_EXPORT double FlutterChannelToolVersionNumber;
FOUNDATION_EXPORT const unsigned char FlutterChannelToolVersionString[];