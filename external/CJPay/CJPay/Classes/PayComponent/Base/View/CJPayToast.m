//
//  CJPayToast.m
//  CJPay
//
//  Created by wangxinhua on 2018/11/5.
//

#import "CJPayToast.h"
#import "CJPayToastView.h"
#import "CJPayProtocolManager.h"
#import "CJPayUIMacro.h"
#import "CJPayImageToastView.h"

@implementation CJPayToast

+ (instancetype)sharedToast{
    static CJPayToast *toast;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        toast = [CJPayToast new];
    });
    return toast;
}

- (void)toastText:(NSString *)content inWindow:(nullable UIWindow *)window{
    if (!Check_ValidString(content)) {
        return;
    }
    CJ_DECLARE_ID_PROTOCOL(CJPayToastProtocol);
    if (objectWithCJPayToastProtocol && [objectWithCJPayToastProtocol respondsToSelector:@selector(toastText:inWindow:)]) {
        [objectWithCJPayToastProtocol toastText:content inWindow:window];
    } else {
        [self toastText:content duration:2.5 inWindow:window];
    }
}

- (void)toastText:(NSString *)content inWindow:(UIWindow *)window location:(CJPayToastLocation)location {
    if (location == CJPayToastLocationCenter) {
        [self toastText:content inWindow:window];
    } else {
        CJPayToastView *toastView = [CJPayToastView toastTitle:content timestamp:2.5 inWindow:window];
        CGRect rect = toastView.frame;
        rect.origin = CGPointMake(rect.origin.x, rect.origin.y * 1.5);
        toastView.frame = rect;
    }
}

- (void)toastText:(NSString *)content duration:(NSTimeInterval)duration inWindow:(nullable UIWindow *)window {
    if (content == nil || content.length < 1) {
        return;
    }
    CJ_DECLARE_ID_PROTOCOL(CJPayToastProtocol);
    if (objectWithCJPayToastProtocol && [objectWithCJPayToastProtocol respondsToSelector:@selector(toastText:duration:inWindow:)]) {
        [objectWithCJPayToastProtocol toastText:content duration:duration inWindow:window];
        return;
    }
    NSString *code = @"";
    NSString *title = content;
    if ([content containsString:@"["]) {
        NSArray <NSString *>* strs = [content componentsSeparatedByString:@"["];
        NSString *temCode = @"";
        if (strs.count > 1 && strs.firstObject.length < content.length) {
            temCode = [content substringFromIndex:strs.firstObject.length];
        }
        if ([temCode hasPrefix:@"["] && [temCode hasSuffix:@"]"] && temCode.length >= 3) {
            title = strs.firstObject;
            code = temCode;
        }
    }
    if (code.length > 1) {
        [CJPayToastView toast:title code:code duration:duration inWindow:window];
    } else {
        [CJPayToastView toastTitle:content timestamp:duration inWindow:window];
    }
}

- (void)toastText:(NSString *)content code:(NSString *)code inWindow:(nullable UIWindow *)window{
    [self toastText:content code:code duration:0 inWindow:window];
}

- (void)toastText:(NSString *)content code:(NSString *)code duration:(NSTimeInterval)duration inWindow:(nullable UIWindow *)window{
    if (content == nil && content.length < 1) {
        return;
    }
    CJ_DECLARE_ID_PROTOCOL(CJPayToastProtocol);
    if (objectWithCJPayToastProtocol && [objectWithCJPayToastProtocol respondsToSelector:@selector(toastText:code:inWindow:)]) {
        [objectWithCJPayToastProtocol toastText:content code:code inWindow:window];
        return;
    }
    [CJPayToastView toast:content code:code duration:duration inWindow:window];
}

+ (void)toastImage:(NSString *)imageName title:(NSString *)title duration:(NSTimeInterval)duration inWindow:(UIWindow *)window {
    [CJPayImageToastView toastImage:imageName title:title duration:duration inWindow:window];
}

@end
