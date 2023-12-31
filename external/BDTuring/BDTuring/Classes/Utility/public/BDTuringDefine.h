//
//  BDTuringDefine.h
//  Pods
//
//  Created by bob on 2020/3/6.
//

#import <Foundation/Foundation.h>

#ifndef BDTuringDefine_h
#define BDTuringDefine_h

NS_ASSUME_NONNULL_BEGIN

@class BDTuring, BDTuringVerifyResult, BDTuringVerifyModel;

/*! @abstract region type
*/
typedef NS_ENUM(NSInteger, BDTuringRegionType){
    BDTuringRegionTypeCN = 1,
    BDTuringRegionTypeSG,      /// Singapore
    BDTuringRegionTypeVA,      /// EastAmerica
    BDTuringRegionTypeIndia,    /// india
};

/*! @abstract verify type
*/
typedef NSInteger BDTuringVerifyType NS_TYPED_ENUM;

/*! @abstract BDTuringConfigDelegate
*/
@protocol BDTuringConfigDelegate <NSObject>

/// deviceID from BDTracker
- (NSString *)deviceID;

/// return [[TTAccount sharedAccount] sessionKey] or nil
- (nullable NSString *)sessionID;

/// installID from BDTracker
- (NSString *)installID;

/// [TTAccount sharedAccount] .userIdString
- (nullable NSString *)userID;

/*
 if ([[TTAccount sharedAccount] isLogin]) {
     return [TTAccount sharedAccount].user.secUserId;
 } else {
     return [TTAccount sharedAccount].secUserId;
 }
 */
- (nullable NSString *)secUserID;

@end

/*! @abstract result code
*/
typedef NS_ENUM(NSInteger, BDTuringVerifyStatus) {
    BDTuringVerifyStatusOK              = 0,    ///< success
    BDTuringVerifyStatusError           = 1,    ///< fail
    BDTuringVerifyStatusClose           = 2,    ///< user  close  it
    BDTuringVerifyStatusNetworkError    = 3,    ///< network error
    BDTuringVerifyStatusCloseFromMask   = 4,    ///< user close it from mask
    BDTuringVerifyStatusCloseFromAPI    = 6,    ///< you close it from close api
    BDTuringVerifyStatusCloseFromFeedback = 7,///< user close it from feedback
    BDTuringVerifyStatusNotSupport     = 996,  ///code or type not support
    BDTuringVerifyStatusResponseError   = 997,  ///response error
    BDTuringVerifyStatusConflict        = 998,  /// the first is showing now
    BDTuringVerifySystemVersionLow      = 999,    ///< OS version too  low
    BDTuringVerifyParamError            = 1006,    ///< sms verify code failed
    BDTuringVerifyFailed                = 1202,    ///< sms verify code failed
    BDTuringVerifyOutdated              = 1203,    ///< sms verify code outdated
};

/*! @abstract result callback
 @param status result code
 @param token token for sms
 @param mobile  mobile for sms
 @discussion token and mobile only available from sms
*/
typedef void (^BDTuringVerifyCallback)(BDTuringVerifyStatus status,
                                       NSString *_Nullable token,
                                       NSString *_Nullable mobile);

/*! @abstract result callback
 @param result the result information
*/
typedef void (^BDTuringVerifyResultCallback)(BDTuringVerifyResult *_Nonnull result);


/*! @abstract the delegate
*/
@protocol BDTuringDelegate <NSObject>

@optional

/*! @abstract the view did show
*/
- (void)turingDidShow:(BDTuring *)turing;

/*! @abstract the view did hidden
*/
- (void)turingDidHide:(BDTuring *)turing;

/*! @abstract the webview load success
*/
- (void)turingWebViewDidLoadSuccess:(BDTuring *)turing;

/*! @abstract the webview load failed
*/
- (void)verifyWebViewDidLoadFail:(BDTuring *)turing;

@end

@protocol BDTuringVerifyHandler <NSObject>

/*! @abstract you need implement it
 @param model the request model
*/
- (void)popVerifyViewWithModel:(BDTuringVerifyModel *)model;

@end


NS_ASSUME_NONNULL_END

#endif
