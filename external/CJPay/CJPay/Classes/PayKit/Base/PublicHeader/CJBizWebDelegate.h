//
//  CJBizWebDelegate.h
//  CJPay
//
//  Created by 王新华 on 2018/11/21.
//

#ifndef CJBizWebDelegate_h
#define CJBizWebDelegate_h

typedef NS_ENUM(NSUInteger, CJBizWebCode) {
    CJBizWebCodeNone,
    CJBizWebCodeLoginSuccess,// 登录成功
    CJBizWebCodeLoginFailure, // 登录失败
    CJBizWebCodeCloseDesk, // 关闭收银台
    CJBizWebCodeHasLogged, // 已经登录
};

@protocol CJBizWebDelegate <NSObject>

/**
 需要业务方登录 // callback 参数传CJBizWebCodeLoginSuccess: 表示登录成功，传CJBizWebCodeLoginFailure: 表示登录失败， 传CJBizWebCodeCloseDesk 会立即关闭收银台所有页面
 */
- (void)needLogin:(void(^_Nullable)(CJBizWebCode))callback;

@optional
// 账户注销
- (void)logoutAccount;
// 业务方处理scheme
- (void)openCJScheme:(NSString *_Nonnull)scheme;
- (void)openCJScheme:(NSString *_Nonnull)scheme fromVC:(nullable UIViewController *)vc useModal:(BOOL) useModal; // ipad支持分屏情况下需要实现这个方法，YES表示使用Present打开新页面

@end


#endif /* CJBizWebDelegate_h */
