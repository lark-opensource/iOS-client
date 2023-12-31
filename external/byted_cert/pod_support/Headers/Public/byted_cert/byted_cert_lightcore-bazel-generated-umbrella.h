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

#import "BytedCert.h"
#import "BytedCertDefine.h"
#import "BytedCertError.h"
#import "BytedCertInterface.h"
#import "BytedCertMacros.h"
#import "BytedCertManager+OCR.h"
#import "BytedCertManager+VideoRecord.h"
#import "BytedCertManager.h"
#import "BytedCertNetInfo.h"
#import "BytedCertNetResponse.h"
#import "BytedCertParameter.h"
#import "BytedCertUIConfig.h"
#import "BytedCertUserInfo.h"
#import "BytedCertVideoRecordParameter.h"
#import "BytedCertWrapper.h"

FOUNDATION_EXPORT double byted_certVersionNumber;
FOUNDATION_EXPORT const unsigned char byted_certVersionString[];