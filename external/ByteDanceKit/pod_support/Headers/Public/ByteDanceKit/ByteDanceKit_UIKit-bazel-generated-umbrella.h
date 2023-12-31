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

#import "BTDResponder.h"
#import "UIApplication+BTDAdditions.h"
#import "UIButton+BTDAdditions.h"
#import "UIColor+BTDAdditions.h"
#import "UIControl+BTDAdditions.h"
#import "UIDevice+BTDAdditions.h"
#import "UIGestureRecognizer+BTDAdditions.h"
#import "UIImage+BTDAdditions.h"
#import "UILabel+BTDAdditions.h"
#import "UIScrollView+BTDAdditions.h"
#import "UIView+BTDAdditions.h"
#import "UIWindow+BTDAdditions.h"

FOUNDATION_EXPORT double ByteDanceKitVersionNumber;
FOUNDATION_EXPORT const unsigned char ByteDanceKitVersionString[];