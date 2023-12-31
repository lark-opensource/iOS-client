#import <WebKit/WebKit.h>
#import <BDWebCore/IWKPluginObject.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSURLRequest (BDWebForestPlugin)

- (BOOL)bdw_skipForest;

@end

@interface NSMutableURLRequest (BDWebForestPlugin)
- (void)setBdw_skipForest:(BOOL)skipForest;
@end

@interface BDWebForestPluginObject : IWKPluginObject<IWKClassPlugin>

@end

@interface WKWebViewConfiguration (BDWebForest)
/// enable forest interceptor for main html file
@property (nonatomic, assign) BOOL bdw_allowForestWaitFix;

/// enable TTNetSchemeHandler; TTNetSchemeHandler will be the first schemeHandler
/// all request will be handled by this schemeHandler
@property (nonatomic, assign) BOOL bdw_enableTTNetSchemeHandler API_AVAILABLE(ios(12.0));

/// enable Forest  interceptor for offline data in TTNetSchemeHandler, will also add a  url decorator for adding ttnet common parameters, enable cache, etc.
@property (nonatomic, assign) BOOL bdw_enableForestInterceptorForTTNetSchemeHandler API_AVAILABLE(ios(12.0));

@end

@interface WKWebView (BDWebForest)
/// enable Forest  interceptor for offline data in TTNetSchemeHandler
@property (nonatomic, assign) BOOL bdw_enableForestInterceptorForTTNetSchemeHandler API_AVAILABLE(ios(12.0));

@end

NS_ASSUME_NONNULL_END
