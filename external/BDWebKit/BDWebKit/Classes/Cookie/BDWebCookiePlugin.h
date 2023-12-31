//
//  BDWebCookiePlugin.h
//  BDWebKit
//
//  Created by wealong on 2019/11/17.
//

#import <BDWebCore/IWKPluginObject.h>

NS_ASSUME_NONNULL_BEGIN

/// Cookie Sync Mode
typedef NS_ENUM(NSInteger, BDWebCookiePluginSyncMode) {
    BDWebCookiePluginSyncAnywayMode = 0,    // Sync cookie in main thread，block webview init.
    BDWebCookiePluginAsyncMode,             // Sync cookie in sub thread, not block webview init.
    BDWebCookiePluginSkipSyncMode           // Jump Cookie sync step.
};

@interface WKWebViewConfiguration (BDWebCookiePlugin)

@property (nonatomic, assign) BDWebCookiePluginSyncMode bdw_cookiePluginSyncMode;

@end

@interface WKWebView (BDWebCookiePlugin)

/// Whether the cookies are syncing.
@property (nonatomic, assign) BOOL bdw_cookieSyncing;

@end

@interface BDWebCookiePlugin : IWKPluginObject <IWKClassPlugin>

@end

NS_ASSUME_NONNULL_END
