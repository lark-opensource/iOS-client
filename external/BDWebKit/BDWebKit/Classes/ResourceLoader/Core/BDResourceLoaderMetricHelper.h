//
//  BDResourceLoaderMetricHelper.h
//  Aweme
//
//  Created by bytedance on 2022/5/19.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

@protocol BDXResourceProtocol; //resource loader protocol

@interface BDResourceLoaderMetricHelper : NSObject

/// 在resourceProvider中取监控信息
/// @param resourceProvider resourceLoader返回结果，包含了加载过程所有信息
/// @param containerId webView's containerId
/// @return result dict
+ (NSDictionary *)monitorDict:(__nullable id<BDXResourceProtocol>)resourceProvider containerId:(NSString *)containerId;

/// 返回webView的containerId
/// @param webView
/// @return containerId
+ (NSString *)webContainerId:(WKWebView *)webView;
@end

