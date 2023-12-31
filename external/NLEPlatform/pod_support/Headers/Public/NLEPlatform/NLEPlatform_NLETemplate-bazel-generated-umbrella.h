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

#import "NLEContextProcessor+iOS.h"
#import "NLEMappingNode+iOS.h"
#import "NLETemplateEditor+iOS.h"
#import "NLETemplateModel+iOS.h"
#import "NLETemplateVolumeUtils+iOS.h"
#import "TemplateConfig+iOS.h"
#import "TemplateInfo+iOS.h"
#import "TemplateNode+iOS.h"

FOUNDATION_EXPORT double NLEPlatformVersionNumber;
FOUNDATION_EXPORT const unsigned char NLEPlatformVersionString[];