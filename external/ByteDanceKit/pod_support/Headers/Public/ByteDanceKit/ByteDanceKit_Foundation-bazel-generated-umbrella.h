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

#import "BTDDispatch.h"
#import "BTDMacros.h"
#import "BTDWeakProxy.h"
#import "ByteDanceKit.h"
#import "NSArray+BTDAdditions.h"
#import "NSBundle+BTDAdditions.h"
#import "NSData+BTDAdditions.h"
#import "NSDate+BTDAdditions.h"
#import "NSDictionary+BTDAdditions.h"
#import "NSFileManager+BTDAdditions.h"
#import "NSNumber+BTDAdditions.h"
#import "NSObject+BTDAdditions.h"
#import "NSObject+BTDBlockObservation.h"
#import "NSSet+BTDAdditions.h"
#import "NSString+BTDAdditions.h"
#import "NSTimer+BTDAdditions.h"
#import "NSURL+BTDAdditions.h"

FOUNDATION_EXPORT double ByteDanceKitVersionNumber;
FOUNDATION_EXPORT const unsigned char ByteDanceKitVersionString[];