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

#import "BDBDModule.h"
#import "BDBDQuaterback.h"
#import "BDDYCModule+Internal.h"
#import "BDDYCModuleModel.h"
#import "BDDYCMonitor.h"
#import "BDDYCMonitorImpl.h"
#import "BDQBDelegate.h"
#import "BDQuaterbackConfigProtocol.h"

FOUNDATION_EXPORT double QuaterbackVersionNumber;
FOUNDATION_EXPORT const unsigned char QuaterbackVersionString[];