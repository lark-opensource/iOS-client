//
//  WKWebViewConfiguration+PublicInterface.h
//  IESWebViewMonitor
//
//  Created by bytedance on 2021/11/29.
//

#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WKWebViewConfiguration (PublicInterface)

// 实例monitor开关
@property (nonatomic, assign) BOOL bdwm_disableMonitor;
// 实例是否注入js sdk
@property (nonatomic, assign) BOOL bdwm_disableInjectBrowser;

// 所有实例配置
@property (nonatomic, strong, readonly, nullable) NSDictionary *settings;

@end

NS_ASSUME_NONNULL_END
