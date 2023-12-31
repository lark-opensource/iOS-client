//
//  BDPNativeRenderObj.h
//  Timor
//
//  Created by MacPu on 2019/9/9.
//

#import <WebKit/WebKit.h>
#import <Foundation/Foundation.h>

@interface BDPNativeRenderObj : NSObject

@property (nonatomic, copy) NSString *viewId;
@property (nonatomic, weak) WKWebView *webView;
@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *nativeView;

@end
