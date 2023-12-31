//
//  TestWKWebView.m
//  BDTuring_Tests
//
//  Created by bob on 2019/10/14.
//  Copyright © 2019 Bytedance. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <BDTuring/WKWebView+Piper.h>

@interface TestWKWebView : XCTestCase

@end

@implementation TestWKWebView


- (void)testWebView {
    WKUserContentController *userContent = [[WKUserContentController alloc] init];
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    config.userContentController = userContent;

    WKWebView *webview = [[WKWebView alloc] initWithFrame:CGRectZero configuration:config];

    [webview turing_installPiper];
    XCTAssertNotNil(webview.turing_piper);
}

@end
