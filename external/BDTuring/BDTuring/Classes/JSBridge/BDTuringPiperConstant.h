//
//  BDTuringPiperConstant.h
//  BDTuring
//
//  Created by bob on 2019/8/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BDTuringPiperType){
    BDTuringpiperTypeUnknown = 1,
    BDTuringPiperTypeCall,
    BDTuringPiperTypeOn,
    BDTuringPiperTypeOff,
};

typedef NS_ENUM(NSInteger, BDTuringPiperMsg){
    BDTuringPiperMsgUnknownError   = -1000,
    BDTuringPiperMsgManualCallback = -999,
    BDTuringPiperMsgCodeUndefined      = -998,
    BDTuringPiperMsgCode404            = -997,
    BDTuringPiperMsgSuccess = 1,
    BDTuringPiperMsgFailed = 0,
    BDTuringPiperMsgParamError = -3,
    BDTuringPiperMsgNoHandler = -2,
    BDTuringPiperMsgNoPermission = -1,
};

typedef void (^BDTuringPiperCallCompletion)(id _Nullable result, NSError * _Nullable error);

typedef void (^BDTuringPiperOnCallback)(BDTuringPiperMsg msg, NSDictionary *_Nullable params);
typedef void (^BDTuringPiperOnHandler)(NSDictionary *_Nullable params, BDTuringPiperOnCallback _Nullable callback);

FOUNDATION_EXTERN NSString * const kBDTuringCallMethod;

FOUNDATION_EXTERN NSString *const kBDTuringPiperCallbackID;
FOUNDATION_EXTERN NSString *const kBDTuringPiperMsgType;
FOUNDATION_EXTERN NSString *const kBDTuringPiperName;
FOUNDATION_EXTERN NSString *const kBDTuringPiper2JSParams;
FOUNDATION_EXTERN NSString *const kBDTuringPiper2NativeParams;
FOUNDATION_EXTERN NSString *const kBDTuringPiperErrorCode;
FOUNDATION_EXTERN NSString *const kBDTuringPiperCode;
FOUNDATION_EXTERN NSString *const kBDTuringPiperData;

FOUNDATION_EXTERN NSString *const BDTuringPiperMsgTypeEvent;
FOUNDATION_EXTERN NSString *const BDTuringPiperMsgTypeOn;
FOUNDATION_EXTERN NSString *const BDTuringPiperMsgTypeCall;
FOUNDATION_EXTERN NSString *const BDTuringPiperMsgTypeOff;
FOUNDATION_EXTERN NSString *const BDTuringPiperMsgTypeCallback;

FOUNDATION_EXTERN NSString * kBDTuringPiperJSHandler;

NS_ASSUME_NONNULL_END
