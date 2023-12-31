//
//  ACCWebViewProtocol.h
//  Pods
//
//  Created by chengfei xiao on 2019/8/7.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCWebViewProtocol <NSObject>

- (UIViewController * _Nonnull)createWebviewControllerWithUrl:(NSString * _Nonnull)url title:(NSString * _Nullable)title;

- (void)webVC:(UIViewController * _Nonnull)vc hideNavigationBar:(BOOL)hide;

@end

NS_ASSUME_NONNULL_END
