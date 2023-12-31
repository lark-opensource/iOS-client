//
//  BDWebSecureLinkPlugin.h
//  BDWebKit
//
//  Created by bytedance on 2020/4/16.
//

#import <BDWebCore/IWKPluginObject.h>
#import <BDWebKit/BDWebSecureLinkCustomSetting.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN NSString * const BDWebSecureLinkResponseNotification;

@interface BDWebSecureLinkPlugin : IWKPluginObject<IWKInstancePlugin>

/// 注入webview的实例对象中，要开启的话还需要引用WKWebView+BDSecureLink.h，开启bdw_switchOnSecureLink
/// @param webview wkwebview对象
/// @param aid 开启功能必填，产品id，头条13，商业化广告1402，抖音:1128，tiktok:1180，musically:1233，火山：1112
/// @param scene 开启功能必填，scene 场景，如私信：'im'，扫一扫：'qrcode'
/// @param lang 开启功能选填，默认为中文zh，lang 语言，中文：zh，英文：en，繁体：zh-Hant
+ (void)injectToWebView:(WKWebView *)webview withAid:(int)aid scene:(NSString *)scene lang:(NSString *)lang;

/// ！！！必须要调用设置
/// 安全要求，域名不能直接在代码汇中写死，需要业务侧根据app不同配置
/// 配置可参考 ： 国内【https://link.wtturl.cn/】，美东 【https://va-link.byteoversea.com/link/】，新加坡【https://sg-link.byteoversea.com/link/】
/// @param domain domain
+ (void)configSecureLinkDomain:(NSString *)domain;

/// 更新securelink的一些自定义配置参数，app生命周期内全局通用
/// @param settingModel 配置model
+ (void)updateCustomSettingModel:(BDWebSecureLinkCustomSetting *)settingModel;

/// 安全回退，逐步回退上一页，直到是安全校验通过的页面才停止，如果没有上一页可回退，执行block
/// @param webView webView
/// @param block 回退到栈底了需要执行的操作
+ (void)secureGoBackStepByStep:(WKWebView *)webView reachEndBlock:(void(^)(void))block;

@end

@protocol BDWebSecureLinkContextProtocol <NSObject>

-(void)bdw_clearSecLinkContext;
-(BOOL)bdw_isSeclinkInstalled;

@end


@interface WKWebView (BDSecureLinkContext)<BDWebSecureLinkContextProtocol>

@end
NS_ASSUME_NONNULL_END
