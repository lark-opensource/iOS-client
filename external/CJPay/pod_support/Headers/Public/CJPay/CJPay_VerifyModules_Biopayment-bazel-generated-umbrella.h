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

#import "CJPayBDBioConfirmViewController.h"
#import "CJPayBioGuideFigureViewController.h"
#import "CJPayBioGuideTipsItemView.h"
#import "CJPayBioGuideViewController.h"
#import "CJPayBioHeader.h"
#import "CJPayBioManager.h"
#import "CJPayBioPaymentBaseRequestModel.h"
#import "CJPayBioPaymentCheckRequest.h"
#import "CJPayBioPaymentCloseRequest.h"
#import "CJPayBioPaymentPluginImpl.h"
#import "CJPayBioPaymentTimeCorrectRequest.h"
#import "CJPayBioVerifyUtil.h"
#import "CJPayBridgePlugin_bio.h"
#import "CJPayCashdeskEnableBioPayRequest.h"
#import "CJPayEnvManager.h"
#import "CJPayMemberEnableBioPayRequest.h"
#import "CJPayOpenBioGuideView.h"
#import "CJPayTouchIdManager.h"
#import "CJPayVerifyItemBioPayment.h"
#import "CJPayVerifyItemRecogFaceOnBioPayment.h"
#import "CJPayVerifyItemStandardBioPayment.h"
#import "OTPGenerator.h"
#import "TOTPGenerator.h"

FOUNDATION_EXPORT double CJPayVersionNumber;
FOUNDATION_EXPORT const unsigned char CJPayVersionString[];