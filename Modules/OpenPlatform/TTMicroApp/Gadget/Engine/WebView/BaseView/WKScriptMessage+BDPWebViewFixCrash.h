#import <WebKit/WebKit.h>
NS_ASSUME_NONNULL_BEGIN
@interface WKScriptMessage (BDPWebViewFixCrash)
+ (void)bdpwebview_tryFixWKScriptMessageCrash;
@end
NS_ASSUME_NONNULL_END
