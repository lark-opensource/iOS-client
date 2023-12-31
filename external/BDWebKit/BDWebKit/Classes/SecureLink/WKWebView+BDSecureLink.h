//
//  WKWebView+BDSecureLink.h
//  BDWebKit
//
//  Created by bytedance on 2020/4/17.
//

#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, BDSecureLinkCheckRedirectType) {
    BDSecureLinkCheckRedirectTypeDisable = 0,   // 不开启重定向securelink的校验。默认为disable
    BDSecureLinkCheckRedirectTypeSync,          // 在非重定向的请求下，response回来后先请求securelinkcheck，有结果后判断展示还是中转到securelink。【会增加显示耗时，建议强校验业务才加】
    BDSecureLinkCheckRedirectTypeAsync,         // 在非重定向的请求下，response回来后先渲染，然后异步请求securelinkcheck，有结果后判断是否需要中转到securelink。【不会增加显示耗时，不过会滞后展示中转页】
};

@interface WKWebView (BDSecureLink)

///  securelink重定向校验，在decidePolicyForNavigationResponse进行校验，校验方式参考BDSecureLinkCheckRedirectType
@property (nonatomic, assign) BDSecureLinkCheckRedirectType bdw_secureLinkCheckRedirectType;

///  在第一次loadRequest进行校验，后续重定向或者webview内部跳转均不再进行校验
@property (nonatomic, assign) BOOL bdw_switchOnFirstRequestSecureCheck;

@property (nonatomic, assign) BOOL bdw_strictMode;

///  用户感知   
@property (nonatomic, readonly) BOOL bdw_hasClick;

///  安全链接校验域名白名单，业务方设置后，只要是符合对应域名的都会直接通过，如www.douyin.com等，注意，安全链接只校验http和https协议的，其他协议都会自动通过。
@property (nonatomic, strong) NSArray *bdw_secureCheckHostAllowList;

@end

NS_ASSUME_NONNULL_END
