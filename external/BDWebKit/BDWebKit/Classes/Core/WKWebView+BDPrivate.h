//
//  WKWebView+BDPrivate.h
//  BDWebKit
//
//  Created by wealong on 2020/1/5.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import "BDWebKitDefine.h"

@class BDWebKitMainFrameModel;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, BDWebKitURLProtocolInterceptionStatus) {
    BDWebKitURLProtocolInterceptionStatusNone,
    BDWebKitURLProtocolInterceptionStatusAbout,
    BDWebKitURLProtocolInterceptionStatusHTTP
};

typedef NS_ENUM(NSUInteger, BDWebKitSchemeHandlerInterceptionStatus) {
    BDWebKitSchemeHandlerInterceptionStatusNone,
    BDWebKitSchemeHandlerInterceptionStatusHTTP
};

@interface WKWebView (BDPrivate)

@property (nonatomic, readonly) NSArray *bdw_urlProtocols;

@property (nonatomic) BDWebViewOfflineType bdw_offlineType;

@property (nonatomic) BDWebKitMainFrameModel *bdw_mainFrameModelRecord;

@property (nonatomic) BDWebKitSchemeHandlerInterceptionStatus bdw_schemeHandlerInterceptionStatus;

+ (void)bdw_updateURLProtocolInterceptionStatus:(BDWebKitURLProtocolInterceptionStatus)status;

- (BOOL)bdw_hasInterceptMainFrameRequest;

- (void)bdw_registerURLProtocolClass:(Class)protocol;

- (void)bdw_unregisterURLProtocolClass:(Class)protocol;

- (nullable WKNavigation *)bdw_loadRequest:(NSURLRequest *)request;

- (BOOL)bd_isPageValid;

- (UIView*)bd_contentView;
@end

@interface NSURLRequest (WebKitSupport)

@property (nonatomic,assign) BOOL useURLProtocolOnlyLocal;

@end

NS_ASSUME_NONNULL_END
