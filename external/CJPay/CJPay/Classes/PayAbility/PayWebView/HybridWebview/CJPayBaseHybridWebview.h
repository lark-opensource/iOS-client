//
//  CJPayBaseHybridWebview.h
//  cjpaysandbox
//
//  Created by ByteDance on 2023/5/6.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class WKWebView;
@class WKNavigation;

//实际逻辑在CJPayHybridView+webview中完成，一定要确保接入hybrid能力再使用该内容
@interface CJPayBaseHybridWebview : UIView

@property (nonatomic, weak, readonly) WKWebView *webview;
@property (nonatomic, copy)NSString *containerID;

- (instancetype)initWithScheme:(NSString *)scheme delegate:(nullable id)delagate initialData:(nullable NSDictionary *)params;

- (void)sendEvent:(NSString *)event params:(nullable NSDictionary *)data;

@end

NS_ASSUME_NONNULL_END
