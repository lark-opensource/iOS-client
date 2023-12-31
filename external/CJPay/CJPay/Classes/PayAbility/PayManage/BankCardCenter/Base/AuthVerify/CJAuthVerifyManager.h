//
//  CJAuthVerifyManager.h
//  CJPay
//
//  Created by wangxiaohong on 2020/9/3.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, CJPayAuthDeskCallBackType) {
    CJPayAuthDeskCallBackTypeCancel,
    CJPayAuthDeskCallBackTypeSuccess,
    CJPayAuthDeskCallBackTypeFail,
    CJPayAuthDeskCallBackTypeLogout,
    CJPayAuthDeskCallBackTypeUnnamed,
    CJPayAuthDeskCallBackTypeAuthorized,
    CJPayAuthDeskCallBackTypeQueryError
};

@interface CJAuthVerifyManager : NSObject

+ (instancetype)defaultService;

/**
* 打开授权页面
* @param params 需要包含app_id，merchant_id
* @param callBack 回到给业务方的授权结果
*  CJPayAuthDeskCallBackTypeCancel, //授权取消
*  CJPayAuthDeskCallBackTypeSuccess, //授权成功
*  CJPayAuthDeskCallBackTypeFail, //授权失败
*  CJPayAuthDeskCallBackTypeLogout, //注销成功
*  CJPayAuthDeskCallBackTypeUnnamed, //未实名
*  CJPayAuthDeskCallBackTypeAuthorized //已授权
*  CJPayAuthDeskCallBackTypeQueryError //查询授权信息失败
**/
- (void)openAuthDeskWithParams:(NSDictionary *)params callBack:(void (^)(CJPayAuthDeskCallBackType))callBack;

@end

NS_ASSUME_NONNULL_END
