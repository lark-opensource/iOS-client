//
//  WKWebView+Keyboard.h
//  BDWebKit
//
//  Created by li keliang on 2020/3/15.
//

#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WKWebView (Keyboard)

@property (nonatomic, assign) BOOL bdw_keyboardDisplayRequiresUserAction;

@end

@interface BDWebKeyboardManager : NSObject

+ (void)setupIfNeeded;

@end

NS_ASSUME_NONNULL_END
