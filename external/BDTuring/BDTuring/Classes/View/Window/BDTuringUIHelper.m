//
//  BDTuringUIHelper.m
//  BDTuring
//
//  Created by bob on 2019/9/2.
//

#import "BDTuringUIHelper.h"
#import "BDTuringPresentView.h"
#import <UIKit/UIKit.h>

@implementation BDTuringUIHelper

+ (UIWindow *)keyWindow {
    UIWindow *keyWindow = nil;
    #ifdef __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        NSArray<UIWindow *>  *windows = [UIApplication sharedApplication].windows;
        for (UIWindow *window in windows) {
            if (window.isKeyWindow) {
                keyWindow = window;
                break;
            }
        }
    }
    #endif
    if (keyWindow == nil) {
        keyWindow = [UIApplication sharedApplication].keyWindow;
    }

    return keyWindow;
}

+ (CGFloat)statusBarHeight {
    if (@available(iOS 11.0, *)) {
        return [self keyWindow].safeAreaInsets.top;
    } else {
        if ([UIApplication sharedApplication].statusBarHidden) return 0;
        CGSize size = [UIApplication sharedApplication].statusBarFrame.size;

        return MIN(size.width, size.height);
    }
}

+ (instancetype)sharedInstance {
    static BDTuringUIHelper *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });

    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.shouldCloseFromMask = YES;
    }
    
    return self;
}

- (void)setSupportLandscape:(BOOL)supportLandscape {
    if ([BDTuringPresentView defaultPresentView].presentingViews.count > 0) {
        return;
    }
    _supportLandscape = supportLandscape;
}

@end
