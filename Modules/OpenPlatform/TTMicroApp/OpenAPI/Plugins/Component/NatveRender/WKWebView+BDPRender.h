//
//  WKWebView+BDPRender.h
//  Timor
//
//  Created by MacPu on 2019/7/15.
//

#import <WebKit/WebKit.h>

/// WKWebView 支持同层级渲染
@interface WKWebView (BDPRender)

/// 插入原生组件
/// @param view 原生组件
/// @param index 组件 ID
/// @param completion 插入完成的回掉
- (void)bdp_insertComponent:(UIView *)view atIndex:(NSString *)index completion:(void (^)(BOOL success))completion;

///  删除原生组件
/// @param index  组件 ID
- (BOOL)bdp_removeComponentAtIndex:(NSString *)index;

/// 查找原生组件
/// @param index  组件 ID
- (UIView *)bdp_componentFromIndex:(NSString *)index;

@end
