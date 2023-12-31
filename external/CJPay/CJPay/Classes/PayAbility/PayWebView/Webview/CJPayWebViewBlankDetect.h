//
//  CJPayWebViewBlankDetect.h
//  Aweme
//
//  Created by ByteDance on 2023/7/12.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN


@interface CJPayBlankDetectContext : NSObject

@property (nonatomic, assign) NSTimeInterval stayTime;
@property (nonatomic, assign) BOOL isLoadingViewShowing;
@property (nonatomic, assign) BOOL isErrorViewShowing;

@end

@interface CJPayWebViewBlankDetect : NSObject

+ (void)blankDetectionWithWebView:(WKWebView *)webView context:(CJPayBlankDetectContext *)context;

@end

NS_ASSUME_NONNULL_END
