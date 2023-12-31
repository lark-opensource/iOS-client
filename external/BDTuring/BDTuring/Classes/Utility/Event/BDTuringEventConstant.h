//
//  BDTuringEventConstant.h
//  BDTuring
//
//  Created by yanming.sysu on 2020/12/20.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, BDTuringEventCloseReason) {
    BDTuringEventCloseUnknown           = 0,
    BDTuringEventCloseFeedBack          = 1,
    BDTuringEventCloseFeedBackClose     = 2,
    BDTuringEventCloseFeedBackMask      = 3,
};

FOUNDATION_EXTERN NSString *const BDTuringEventParamKey;
FOUNDATION_EXTERN NSString *const BDTuringEventParamDuration;
FOUNDATION_EXTERN NSString *const BDTuringEventParamResult;
FOUNDATION_EXTERN NSString *const BDTuringEventParamCount;
FOUNDATION_EXTERN NSString *const BDTuringEventParamCustom;
FOUNDATION_EXTERN NSString *const BDTuringEventParamHostAppID;

FOUNDATION_EXTERN NSString *const BDTuringEventParamSpecial;
FOUNDATION_EXTERN NSString *const BDTuringEventParamTuring;
FOUNDATION_EXTERN NSString *const BDTuringEventParamEvent;
FOUNDATION_EXTERN NSString *const BDTuringEventParamSdkVersion;

FOUNDATION_EXTERN NSString *const BDTuringEventName;

FOUNDATION_EXTERN NSString *const BDTuringEventNameSDKSart;
FOUNDATION_EXTERN NSString *const BDTuringEventNameOrientationChange;
FOUNDATION_EXTERN NSString *const BDTuringEventNameOrientation;
FOUNDATION_EXTERN NSString *const BDTuringEventNameBackground;
FOUNDATION_EXTERN NSString *const BDTuringEventNameSystemLow;
FOUNDATION_EXTERN NSString *const BDTuringEventNamePop;
FOUNDATION_EXTERN NSString *const BDTuringEventNameSettings;
FOUNDATION_EXTERN NSString *const BDTuringEventNamePreloadFinish;
FOUNDATION_EXTERN NSString *const BDTuringEventNamePreloadRefreshFinish;
FOUNDATION_EXTERN NSString *const BDTuringEventNameWebView;
FOUNDATION_EXTERN NSString *const BDTuringEventNameResult;
FOUNDATION_EXTERN NSString *const BDTuringEventNameClose;
