//
//  BDWebViewDebugKit.h
//  BDWebKit
//
//  Created by 杨牧白 on 2019/12/11.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

#ifndef BDWDebugLog
#define BDWDebugLog(FORMAT, ...) [BDWebViewDebugKit log:[[NSString alloc] initWithFormat:FORMAT, ##__VA_ARGS__]];
#endif


@interface BDWebViewDebugKit : NSObject

@property (nonatomic, class) BOOL enable;

+ (void)log:(NSString *)format;

+ (void)registerDebugLabel:(NSString *)label withAction:(void(^)(WKWebView *webview, UINavigationController *nav))action;

@end

NS_ASSUME_NONNULL_END
