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

#import "AWELazyRegister.h"
#import "AWELazyRegisterAccountPlatform.h"
#import "AWELazyRegisterCarrierService.h"
#import "AWELazyRegisterComponentsPriority.h"
#import "AWELazyRegisterDLab.h"
#import "AWELazyRegisterDebugAlert.h"
#import "AWELazyRegisterDebugTools.h"
#import "AWELazyRegisterJSBridge.h"
#import "AWELazyRegisterPremain.h"
#import "AWELazyRegisterRN.h"
#import "AWELazyRegisterRouter.h"
#import "AWELazyRegisterStaticLoad.h"
#import "AWELazyRegisterTabBar.h"
#import "AWELazyRegisterTransition.h"
#import "AWELazyRegisterUserModel.h"
#import "AWELazyRegisterWebImage.h"

FOUNDATION_EXPORT double AWELazyRegisterVersionNumber;
FOUNDATION_EXPORT const unsigned char AWELazyRegisterVersionString[];