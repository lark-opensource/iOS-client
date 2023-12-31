//
//  BDTuring+UserInterface.h
//  BDTuring
//
//  Created by bob on 2020/6/16.
//

#import "BDTuring.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDTuring (UserInterface)

/**
 setForbidLandscape if you dont want it to be Landscape
 */
+ (void)setForbidLandscape:(BOOL)forbid;

/**
 disable loading when captcha is loading and window is grey
 */
+ (void)setDisableLoadingView:(BOOL)disable;

/**
 custom theme or text, you can set nil to clear custom ui
see the API Doc
*/

/// for picture captcha
+ (void)setVerifyTheme:(nullable NSDictionary *)theme;
+ (void)setVerifyText:(nullable NSDictionary *)text;

/// for mobile captcha
+ (void)setSMSTheme:(nullable NSDictionary *)theme;
+ (void)setSMSText:(nullable NSDictionary *)text;

/// for question & answer captcha
+ (void)setQATheme:(nullable NSDictionary *)theme;
+ (void)setQAText:(nullable NSDictionary *)text;

@end

NS_ASSUME_NONNULL_END
