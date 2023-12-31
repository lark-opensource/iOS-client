//
//  CJPayToastProtocol.h
//  CJPay
//
//  Created by 王新华 on 3/4/20.
//

#ifndef CJPayToastProtocol_h
#define CJPayToastProtocol_h

/**
 定制toast时，请实现该协议，并设置[CJPayToast toast].toastDelegate = #自定义Toast<CJPayToastProtocol>#
 */
NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, CJPayToastLocation) {
    CJPayToastLocationCenter,
    CJPayToastLocationBottom
};

@protocol CJPayToastProtocol <NSObject>

- (void)toastText:(NSString *)content inWindow:(nullable UIWindow *)window;

@optional
- (void)toastText:(NSString *)content duration:(NSTimeInterval)duration inWindow:(nullable UIWindow *)window;
- (void)toastText:(NSString *)content code:(NSString *)code inWindow:(nullable UIWindow *)window;
- (void)toastText:(NSString *)content code:(NSString *)code duration:(NSTimeInterval)duration inWindow:(nullable UIWindow *)window;
- (void)toastText:(NSString *)content inWindow:(nullable UIWindow *)window location:(CJPayToastLocation) location;

@end
NS_ASSUME_NONNULL_END

#endif /* CJPayToastProtocol_h */
