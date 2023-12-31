//
//  CJPayHybridPlugin.h
//  CJPaySandBox
//
//  Created by 高航 on 2023/3/6.
//

#ifndef CJPayHybridPlugin_h
#define CJPayHybridPlugin_h

#import <Webkit/WebKit.h>
NS_ASSUME_NONNULL_BEGIN

@protocol CJPayHybridPlugin

- (BOOL)pluginHasInstalled;

#pragma mark - HybridView

- (BOOL)isContainerView:(UIView *)view;

- (nullable WKWebView *)getRawWebview:(UIView *)view;

- (nullable UIView *)createHybridViewWithScheme:(nonnull NSString *)scheme
                                       delegate:(nullable UIViewController *)delegate
                                    initialData:(nullable NSDictionary *)params;

- (void)sendEvent:(nonnull NSString *)event params:(nullable NSDictionary *)data container:(nonnull UIView *)container;

- (nullable NSString *)getContainerID:(UIView *)container;
@end

NS_ASSUME_NONNULL_END
#endif /* CJPayHybridPlugin_h */

