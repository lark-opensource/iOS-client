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

#import "NBAsYouTypeFormatter.h"
#import "NBMetadataHelper.h"
#import "NBNumberFormat.h"
#import "NBPhoneMetaData.h"
#import "NBPhoneNumber.h"
#import "NBPhoneNumberDefines.h"
#import "NBPhoneNumberDesc.h"
#import "NBPhoneNumberUtil.h"
#import "NBRegExMatcher.h"
#import "NBRegularExpressionCache.h"
#import "NSArray+NBAdditions.h"

FOUNDATION_EXPORT double libPhoneNumber_iOSVersionNumber;
FOUNDATION_EXPORT const unsigned char libPhoneNumber_iOSVersionString[];
