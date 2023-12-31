//
//  CJH5PayDeskManager.h
//  CJPay
//
//  Created by 尚怀军 on 2019/8/1.
//

#import <Foundation/Foundation.h>
#import "CJPayUIMacro.h"
#import "CJBizWebDelegate.h"
#import "CJPayManagerDelegate.h"
#import "CJPayBizWebViewController+Biz.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJH5PayDeskManager : NSObject

/**
 * 获取服务实例
 **/
+ (instancetype)defaultService;

/**
 * 注册H5微信支付回跳的到app的URL
 * 1. info.plist 中增加URL types，URL schemes值默认为：tp-pay.snssdk.com。每个宿主App需要设置不同的URL schemes值，由财经分配。
 * 2. 初始化小程序SDK时，将该URL schemes值传递给小程序SDK
 **/
- (void)registerPayRefer:(NSString *)referUrl;

/**
 * 是否支持支付回调URL
 **/
- (BOOL)isSupportPayCallBackURL:(nonnull NSURL *)URL;

/**
 * 打开收银台
 **/
- (void)openH5CashDeskWithURL:(NSString *)url
                 orderInfoDic:(NSDictionary *)orderInfoDic
                   merchantId:(NSString *)merchantId
                        appId:(NSString *)appId
                cashDeskStyle:(CJH5CashDeskStyle)cashDeskStyle
                   completion:(void(^)(CJPayManagerResultType result, NSDictionary *resultParam))completionBlock;

/**
 * 打开收银台, 有默认的base url
 **/
- (void)openH5CashDeskWithOrderInfo:(NSDictionary *)orderInfoDic
                         merchantId:(NSString *)merchantId
                              appId:(NSString *)appId
                      cashDeskStyle:(CJH5CashDeskStyle)cashDeskStyle
                         completion:(void(^)(CJPayManagerResultType result, NSDictionary *resultParam))completionBlock;

/**
 关闭收银台
 */
- (void)closeH5PayDesk;


@end

@interface CJH5PayDeskManager(Deprecated)

/**
 * 预加载支付渠道信息，废弃方法，不在需要预加载
 **/
- (void)preloadPayChannelInfoWithAppId:(NSString *)appId
                            merchantId:(NSString *)merchantId
                                userId:(NSString *)uid DEPRECATED_MSG_ATTRIBUTE("不再需要");

/**
 * 预加载支付渠道信息,可以通过传入ext字段(json字符串)的形式自定义一些样式，废弃方法，不在需要预加载
 **/
- (void)preloadPayChannelInfoWithAppId:(NSString *)appId
                            merchantId:(NSString *)merchantId
                                userId:(NSString *)uid
                                  exts:(NSString *)exts DEPRECATED_MSG_ATTRIBUTE("不再需要");

@end

NS_ASSUME_NONNULL_END
