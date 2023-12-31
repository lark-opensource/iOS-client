//
//  BDAccountSealDefine.h
//  BDTuring
//
//  Created by bob on 2020/3/4.
//

#import <UIKit/UIKit.h>

#ifndef BDAccountSealDefine_h
#define BDAccountSealDefine_h

NS_ASSUME_NONNULL_BEGIN

@class BDTuringAlertOption;

/*! @abstract seal result Code
*/
typedef NS_ENUM(NSInteger, BDAccountSealResultCode) {
    BDAccountSealResultCodeOK                   = 0,    /// success
    BDAccountSealResultCodeSelectManual         = 1,    /// choose Manual
    BDAccountSealResultCodeCancel               = 2,    /// cancel
    BDAccountSealResultCodeFail                 = 3,    /// fail
    BDAccountSealResultNetworkError             = 4,    /// network error
    BDAccountSealResultNotSupport               = 997, /// now only support CN
    BDAccountSealResultConflict                 = 998,  /// showing
    BDAccountSealResultSystemVersionLow         = 999,  /// system version too low
    /// for query status of seal
    BDAccountSealResultCodeAllowedSeal          = 0, /// Allowed to Seal
    BDAccountSealResultCodeParameterError       = 20001, /// ParameterError
    BDAccountSealResultCodeUIDLimited           = 60000, /// you have applied too many times
    BDAccountSealResultCodeFailLimited          = 60001, /// you have fail too many times
    BDAccountSealResultCodeForceManual          = 60003, /// not support seal
};

/*! @abstract result callback
 @param resultCode code
 @param statusCode code
 @param message  message
 @param extraData extra
*/
typedef void (^BDAccountSealCallback)(BDAccountSealResultCode resultCode,
                                      NSInteger statusCode,
                                      NSString *_Nullable message,
                                      NSDictionary *_Nullable extraData);

typedef NS_ENUM(NSInteger, BDAccountSealNavigatePage) {
    BDAccountSealNavigatePageUnknown        = 0,
    BDAccountSealNavigatePagePolicy         = 1,    /// Policy   page
    BDAccountSealNavigatePageCommunity,             /// Community page
};

typedef NS_ENUM(NSUInteger, BDAccountSealThemeMode) {
    BDAccountSealThemeModeDark  = 0,
    BDAccountSealThemeModeLight = 1,
};

/*! @abstract jump callback
 @param page the page
 @param pageType string
 @param navigationController  current UIViewController.navigationController
 @discussion e.g.
 BDAccountSealNavigateBlock navigate = ^(BDAccountSealNavigatePage page,
                                NSString *pageType,
                                UINavigationController *navigationController) {
     XXXViewController *vc = [XXXViewController new];
     vc.title = page == BDAccountSealNavigatePagePolicy ? @"Policy" : @"Community";
     [navigationController pushViewController:vc animated:YES];
 };
*/
typedef void (^BDAccountSealNavigateBlock)(BDAccountSealNavigatePage page,
                                           NSString *_Nullable pageType,
                                           UINavigationController *navigationController);



/// you should implement it if you want to custom the alert dialog
@protocol BDTuringUIHandler <NSObject>

- (void)showAlertWithTitle:(NSString *)title
                   message:(NSString *)message
                   options:(NSArray<BDTuringAlertOption *> *)options
          onViewController:(UIViewController *)viewController;

@end

NS_ASSUME_NONNULL_END

#endif
