//
//  UITextField+BDPExtension.m
//  Timor
//
//  Created by 王浩宇 on 2018/12/4.
//

#import "UITextField+BDPExtension.h"
#import "NSObject+BDPExtension.h"
#import <ECOInfra/BDPLog.h>
#import "BDPDeviceHelper.h"
#import "BDPMethodSwizzledUtilsDefine.h"
//#import "BDPBootstrapHeader.h"
#import <LKLoadable/Loadable.h>

#pragma GCC diagnostic ignored "-Wundeclared-selector"

LoadableMainFuncBegin(UITextFieldBDPExtensionSwizzle)
[UITextField performSelector:@selector(bdp_textField_BDPExtension_swizzle)];
LoadableMainFuncEnd(UITextFieldBDPExtensionSwizzle)

@implementation UITextField (BDPExtension)

+ (void)bdp_textField_BDPExtension_swizzle {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self bdp_swizzleOriginInstanceMethod:@selector(didMoveToWindow) withHookInstanceMethod:@selector(bdp_textFieldDidMoveToWindow)];
    });
}

// 解决UITextField从iOS11.2开始的内存泄漏问题
- (void)bdp_textFieldDidMoveToWindow
{
    [self bdp_textFieldDidMoveToWindow];
    
    if (@available(iOS 11.2, *)) {
        //在iOS13中直接使用keypath设置会导致crash
        if ([BDPDeviceHelper OSVersionNumber] <13.f) {
            NSString *keyPath = @"textContentView.provider";
            @try {
                if (self.window) {
                    id provider = [self valueForKeyPath:keyPath];
                    if (!provider && self) {
                        [self setValue:self forKeyPath:keyPath];
                    }
                } else {
                    [self setValue:nil forKeyPath:keyPath];
                }
            } @catch (NSException *exception) {
                BDPLogError(@"%@", exception);
            }
        }
    }
}

- (NSRange)bdp_selectedRange
{
    UITextPosition *beginning = self.beginningOfDocument;

    UITextRange *selectedRange = self.selectedTextRange;
    UITextPosition *selectionStart = selectedRange.start;
    UITextPosition *selectionEnd = selectedRange.end;
    
    const NSInteger location = [self offsetFromPosition:beginning toPosition:selectionStart];
    const NSInteger length = [self offsetFromPosition:selectionStart toPosition:selectionEnd];
    
    return NSMakeRange(location, length);
}

- (void)setBdp_selectedRange:(NSRange)selectedRange
{
    UITextPosition *beginning = self.beginningOfDocument;
    UITextPosition *startPosition = [self positionFromPosition:beginning offset:selectedRange.location];
    
    // range.location超出范围时startPosition为nil，此时不做任何响应
    if (startPosition) {
        UITextPosition *endPosition = [self positionFromPosition:beginning offset:selectedRange.location + selectedRange.length];
        // range.length超出范围时endPosition为nil，此时将结束位置设置为文本结尾
        UITextRange *selectionRange = [self textRangeFromPosition:startPosition toPosition:endPosition ?: self.endOfDocument];
        [self setSelectedTextRange:selectionRange];
    }
}

@end
