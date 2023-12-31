//
//  CJPayManager.h
//  CJPay
//
//  Created by jiangzhongping on 2018/8/29.
//

#import <Foundation/Foundation.h>
#import "CJPayCookieUtil.h"
#import "CJBizWebDelegate.h"
#import "CJPayNameModel.h"
#import "CJPayOrderResultResponse.h"
#import "CJPayManagerDelegate.h"
#import "CJPayHalfPageBaseViewController.h"
#import "CJPayUIMacro.h"
#import "CJPayBinaryAdapter.h"


NS_ASSUME_NONNULL_BEGIN
@class CJPayHomePageViewController;
@interface CJPayManager : NSObject<CJPayManagerAdapterDelegate>

@property (nonatomic,weak)id<CJPayManagerDelegate> cj_delegate;
@property (nonatomic,strong,readonly) CJPayNameModel *nameModel;
@property (nonatomic, strong, nullable) CJPayHalfPageBaseViewController *deskVC;  // 强持有是为了支付完成的回调能够正确的被处理。
@property (nonatomic,weak) CJPayNavigationController *byteNavVC;

/**
 * 获取服务实例
 **/
+ (instancetype)defaultService;

/**
 设置收银台页面显示的title MOdel

 @param nameModel titleModel
 */
- (void)setupTitlesModel:(CJPayNameModel *)nameModel;

/**
 * 打开收银台界面  bizParams是由商户传入的参数 
 **/
- (void)openPayDeskWith:(nonnull NSDictionary *)bizParams delegate:(id<CJPayManagerDelegate>)delegate;

/**
 * 是否支持支付回调URL
 **/
- (BOOL)isSupportPayCallBackURL:(nonnull NSURL *)URL;

/**
 打开WebView

 @param url webview的url
 @param params 额外的参数
 @param closeCallBack H5在调用closeCallBack时回传的参数
 */
- (void)openWebView:(nonnull NSString *)url params:(nullable NSDictionary *)params closeCallBack:(nullable void(^)(id data)) closeCallBack;
/**
 关闭收银台
 */
- (void)closePayDesk;

- (void)closePayDeskWithCompletion:(void (^)(BOOL))completion;


/**
 注册离线包，在调用该方法时，会去服务端拉去资源文件

 @param appid appid
 */
- (void)registerOffline:(nonnull NSString *)appid;

/// 降级收银台样式
/// @param params 下单参数
/// @param completionBlock 降级后的收银台vc
- (void)downgradeDeskVCWithParams:(NSDictionary *)params completion:(nonnull void(^)(CJPayHomePageViewController *deskVC))completionBlock;

@end
NS_ASSUME_NONNULL_END
