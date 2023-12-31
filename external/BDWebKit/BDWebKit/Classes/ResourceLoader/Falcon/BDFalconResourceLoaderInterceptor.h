//
//  BDFalconResourceLoaderInterceptor.h
//  Indexer
//
//  Created by pc on 2022/3/22.
//

#import <Foundation/Foundation.h>

#import "IESFalconCustomInterceptor.h"
#import "IESFalconManager.h"
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDFalconResourceLoaderInterceptor : NSObject <IESFalconCustomInterceptor>

+ (void)setupWithWebView:(WKWebView *)webview;

@end

NS_ASSUME_NONNULL_END
