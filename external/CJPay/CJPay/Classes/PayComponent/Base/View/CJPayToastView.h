//
//  CJPayToastView.h
//  CJFXJSDK
//
//  Created by 王新华 on 2018/11/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayToastView : UIView

+(CJPayToastView *)toast:(NSString *)title inWindow:(nullable UIWindow *)window;
+(CJPayToastView *)toastTitle:(NSString *)title timestamp:(CGFloat)time inWindow:(nullable UIWindow *)window;
+(CJPayToastView *)toast:(NSString *)title code:(NSString *)code inWindow:(nullable UIWindow *)window;
+(CJPayToastView *)toast:(NSString *)title code:(NSString *)code duration:(NSTimeInterval)duration inWindow:(nullable UIWindow *)window;

@end

NS_ASSUME_NONNULL_END
