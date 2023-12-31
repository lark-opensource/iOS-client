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

#import "ACCJSRuntimeContext.h"
#import "ACCLynxDefaultPackage.h"
#import "ACCLynxDefaultPackageLoadModel.h"
#import "ACCLynxDefaultPackageTemplate.h"
#import "ACCLynxView.h"
#import "ACCLynxWindowContext.h"
#import "ACCLynxWindowService.h"
#import "ACCXBridgeTemplateProtocol.h"

FOUNDATION_EXPORT double CameraClientVersionNumber;
FOUNDATION_EXPORT const unsigned char CameraClientVersionString[];