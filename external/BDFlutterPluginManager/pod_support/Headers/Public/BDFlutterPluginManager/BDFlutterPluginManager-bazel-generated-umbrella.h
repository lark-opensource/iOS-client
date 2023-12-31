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

#import "BDBaseFlutterPlugin.h"
#import "BDBaseFlutterPluginProtocol.h"
#import "BDFLEventForwarder.h"
#import "BDFlutterPluginManager.h"

FOUNDATION_EXPORT double BDFlutterPluginManagerVersionNumber;
FOUNDATION_EXPORT const unsigned char BDFlutterPluginManagerVersionString[];