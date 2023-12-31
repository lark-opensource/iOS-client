//
//  BDWebViewDebugKit.m
//  BDWebKit
//
//  Created by wealong on 2020/1/19.
//

#import <Foundation/Foundation.h>
#import "BDWebViewDebugKit.h"
#import <objc/message.h>
#import <ByteDanceKit/ByteDanceKit.h>
#import <ByteDanceKit/NSObject+BTDAdditions.h>

@implementation BDWebViewDebugKit : NSObject

+ (void)setEnable:(BOOL)enable {
    if ([self.debugger respondsToSelector:_cmd]) {
        ((void (*)(id, SEL, BOOL))objc_msgSend)(self.debugger, _cmd, enable);
    }
}

+ (BOOL)enable {
    if ([self.debugger respondsToSelector:_cmd]) {
        return [self.debugger btd_performSelectorWithArgs:_cmd];
    }
    return NO;
}

+ (void)log:(NSString *)log{
    if (!self.enable) {
        return ;
    }
    if ([self.debugger respondsToSelector:_cmd]) {
        [self.debugger btd_performSelectorWithArgs:_cmd, log];
    }
}

+ (void)registerDebugLabel:(NSString *)label withAction:(void(^)(WKWebView *webview, UINavigationController *nav))action {
    if ([self.debugger respondsToSelector:_cmd]) {
        [self.debugger btd_performSelectorWithArgs:_cmd, label, action];
    }
}

+ (Class)debugger {
    static Class clz = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        clz = NSClassFromString(@"BDWebDebugger");
    });
    return clz;
}

@end
