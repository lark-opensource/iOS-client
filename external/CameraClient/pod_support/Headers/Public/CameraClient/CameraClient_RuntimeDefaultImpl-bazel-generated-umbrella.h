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

#import "ACCAlertDefaultImpl.h"
#import "ACCCustomWebImageManager.h"
#import "ACCWebImageDefaultImpl.h"
#import "ACCWebImageOptions.h"
#import "ACCWebImageTransformProtocol.h"
#import "ACCWebImageTransformer.h"
#import "NSArray+AnimatedType.h"
#import "UIAlertController+ACCAlertDefaultImpl.h"
#import "UIButton+ACCAdditions.h"
#import "UIImageView+ACCWebImage.h"

FOUNDATION_EXPORT double CameraClientVersionNumber;
FOUNDATION_EXPORT const unsigned char CameraClientVersionString[];