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

#import "CJPayBDResultPageViewController.h"
#import "CJPayBioSystemSettingGuideViewController.h"
#import "CJPayCombinePayDetailView.h"
#import "CJPayECSkipPwdUpgradeViewController.h"
#import "CJPayPayBannerRequest.h"
#import "CJPayPayBannerResponse.h"
#import "CJPayResultFigureGuideView.h"
#import "CJPayResultPageView.h"
#import "CJPaySkipPwdGuideFigureViewController.h"
#import "CJPaySkipPwdUpgradeGuideViewController.h"
#import "CJPaySkippwdAfterpayGuideView.h"
#import "CJPaySkippwdGuideUtil.h"

FOUNDATION_EXPORT double CJPayVersionNumber;
FOUNDATION_EXPORT const unsigned char CJPayVersionString[];