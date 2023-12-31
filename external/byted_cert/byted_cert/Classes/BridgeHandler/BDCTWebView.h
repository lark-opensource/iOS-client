//
//  BytedCertWebView.h
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/7/5.
//

#import <WebKit/WebKit.h>
#import "BytedCertInterface.h"

@class BDCTWebView, BDCTCorePiperHandler;

NS_ASSUME_NONNULL_BEGIN


@interface BDCTWebView : WKWebView

@property (nonatomic, strong, readonly) BDCTCorePiperHandler *corePiperHandler;

+ (instancetype _Nonnull)webView;

- (void)loadURL:(NSURL *_Nullable)URL;

@end

NS_ASSUME_NONNULL_END
