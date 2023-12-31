//
//  WKUserContentController+BDWebViewHookJS.h
//  BDWebKit
//
//  Created by wealong on 2019/12/15.
//

#import <WebKit/WebKit.h>
#import "WKUserContentController+BDWHelper.h"

typedef void(^WebViewLogHandler)(id _Nullable msg);

@protocol BDWebViewHookJSMonitor <NSObject>
@optional
-(NSDictionary*)bypassSetting;
-(void)didRecieveJSMessage:(NSURL*_Nonnull)url baseURL:(NSURL*_Nonnull)baseUrl;
-(void)didRecieveJSMessage:(NSURL*_Nonnull)url baseURL:(NSURL*_Nonnull)baseUrl withContentTyp:(NSString*_Nonnull)contentType;
-(void)didInvokeJSCallback:(NSError*_Nullable)error forURL:(NSURL*_Nonnull)url;
-(void)didHandleXHRMessage:(NSURL*_Nonnull)url baseURL:(NSURL*_Nonnull)baseUrl headers:(NSDictionary*)headers multipartData:(NSArray*)data error:(NSError*_Nullable)error;
-(void)didSendRequest:(NSURL*_Nonnull)url baseURL:(NSURL*_Nonnull)baseUrl;
-(void)didRecieveResponseCode:(int)code forURL:(NSURL*_Nonnull)url baseURL:(NSURL*_Nonnull)baseUrl error:(NSError*_Nullable)error;
@end

NS_ASSUME_NONNULL_BEGIN

@interface WKUserContentController(BDWebViewHookJS)
@property (nonatomic, readonly) id<BDWebViewHookJSMonitor> bdw_hookjsMonitor;

- (void)bdw_installHookAjax;
- (void)bdw_installHookAjaxWithMonitor:(id<BDWebViewHookJSMonitor>)monitor;
- (void)uninstallHookAjax;
- (void)bdw_installNativeDomReady;

@end

NS_ASSUME_NONNULL_END
