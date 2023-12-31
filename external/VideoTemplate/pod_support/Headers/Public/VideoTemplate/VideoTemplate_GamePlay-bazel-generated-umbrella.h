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

#import "GPBaseResponseModel.h"
#import "GPMaterialModel.h"
#import "GPNetServiceProtocol.h"
#import "GPRequestModel.h"
#import "GPServerHandleResourceModel.h"
#import "GPServiceContainerProtocol.h"
#import "GPServiceFactory.h"
#import "GamePlayManager.h"
#import "NSData+GPAdditions.h"

FOUNDATION_EXPORT double VideoTemplateVersionNumber;
FOUNDATION_EXPORT const unsigned char VideoTemplateVersionString[];