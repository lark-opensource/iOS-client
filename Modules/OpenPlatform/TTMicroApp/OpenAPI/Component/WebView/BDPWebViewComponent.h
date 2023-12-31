//
//  Created by 王浩宇 on 2018/11/18.
//

#import <Foundation/Foundation.h>
#import "BDPWebView.h"
#import <OPFoundation/BDPAuthorization.h>
#import "BDPComponentManager.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, BDPWebViewURLCheckResultType) {
    /// 可以跳转的URL
    BDPWebViewValidURL = 0,
    /// 可以跳转的schema
    BDPWebViewValidSchema = 1,
    /// 不合法的URL
    BDPWebViewInValidURL = 10,
    /// 在白名单但是不能执行的schema
    BDPWebViewUnsupportSchema = 100,
    /// schema不是http、https且schema不在白名单
    BDPWebViewInvalidSchema = 101,
    /// domain不在白名单
    BDPWebViewInvalidDomain = 1000,
};

/// 小程序web-view组件 灰度阶段需要和上面方法属性等保持一致
@interface BDPWebViewComponent : BDPWebView <BDPComponentViewProtocol>
/// 组件ID 协议属性
@property (nonatomic, assign) NSInteger componentID;
/// 使用safari打开时用到的url
@property (nonatomic, strong) NSURL *bwc_openInOuterBrowserURL;
/// 用于支持webView的返回
@property (nonatomic, copy) void (^bwc_canGoBackChangedBlock)(BOOL canGoBack);

- (instancetype _Nonnull)init NS_UNAVAILABLE;
+ (instancetype _Nonnull)new NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration *)configuration NS_UNAVAILABLE;
/// 创建web-view组件
- (instancetype)initWithFrame:(CGRect)frame
                       config:(WKWebViewConfiguration *)config
                  componentID:(NSInteger)componentID
                     uniqueID:(BDPUniqueID *)uniqueID
                  progressBarColorString:(NSString *)progressBarColorString
                     delegate:(id<BDPWebViewInjectProtocol>)delegate;
/// 检查URL访问权限
+ (BDPWebViewURLCheckResultType)bwc_checkURL:(NSURL*)URL withAuth:(BDPAuthorization*)auth uniqueID:(BDPUniqueID *)uniqueID;

/// 重定向检查
+ (NSURL*)bwc_redirectedURL:(NSURL*)orignURL withCheckResult:(BDPWebViewURLCheckResultType)type;

/// 发送消息到web view
- (void)publishMsgWithApiName:(NSString * _Nonnull)apiName paramsStr:(NSString * _Nonnull)paramsStr webViewId:(NSInteger)webViewId;

@end

NS_ASSUME_NONNULL_END
