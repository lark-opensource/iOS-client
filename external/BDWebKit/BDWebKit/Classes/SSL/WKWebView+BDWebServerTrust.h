//
//  BDWebView+BDServerTrust.h
//  ByteWebView
//
//  Created by Nami on 2019/3/6.
//

#import <WebKit/WebKit.h>
#import "BDWebServerTrustChallengeHandler.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, BDWebServerUntrustOperation) {
    BDWebServerUntrustReject,
    BDWebServerUntrustConfirm,
    BDWebServerUntrustPass,
};


@protocol BDWebServerTrustDelegate <NSObject>

/*! @abstract 务必在实现中调用 completion回调
 */
- (void)webView:(WKWebView *)webView decideServerTrustWithHost:(NSString *)host completion:(void (^)(BDWebServerUntrustOperation operation))completion;

@end

@interface WKWebView (BDWebServerTrust)

@property (nonatomic, weak) id<BDWebServerTrustDelegate> bdw_serverTrustDelegate;

@property (nonatomic, assign) BOOL bdw_enableServerTrustHandler;
@property (nonatomic, assign) BOOL bdw_skipAndPassAllServerTrust;
@property (nonatomic, assign) BOOL bdw_enableServerTrustAsync; // 默认为NO表示证书校验在主线程执行，否则在异步子线程中处理避免卡顿主线程

@property (nonatomic, strong, readonly) BDWebServerTrustChallengeHandler *bdw_serverTrustChallengeHandler;

@end

NS_ASSUME_NONNULL_END
