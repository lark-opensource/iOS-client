//
//  BDWebViewSchemeTaskHandler.h
//  ByteWebView
//
//  Created by Lin Yong on 2019/2/27.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import <BDWebKit/BDWebInterceptor.h>

@class TTHttpTask;

API_AVAILABLE(ios(11.0))
@interface BDWebViewSchemeTaskHandler : NSObject <BDWebURLSchemeTaskHandler>

// 子类可重写此方法进行配置，如果只是需要加配置，则需要调用super保留基础默认配置
- (TTHttpTask *)configHttpTask:(TTHttpTask *)task;

@end
