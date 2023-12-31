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

#import "CJPayBaseLoadingItem.h"
#import "CJPayBaseLoadingView.h"
#import "CJPayDouyinFailLoadingItem.h"
#import "CJPayDouyinHalfLoadingItem.h"
#import "CJPayDouyinLoadingItem.h"
#import "CJPayDouyinLoadingView.h"
#import "CJPayDouyinOpenDeskLoadingItem.h"
#import "CJPayDouyinOpenDeskLoadingView.h"
#import "CJPayDouyinStyleBindCardLoadingItem.h"
#import "CJPayDouyinStyleHalfLoadingItem.h"
#import "CJPayDouyinStyleLoadingItem.h"
#import "CJPayDouyinStyleLoadingView.h"
#import "CJPayHalfLoadingItem.h"
#import "CJPayLoadingManager.h"
#import "CJPaySuperPayLoadingItem.h"
#import "CJPayTopLoadingItem.h"

FOUNDATION_EXPORT double CJPayVersionNumber;
FOUNDATION_EXPORT const unsigned char CJPayVersionString[];