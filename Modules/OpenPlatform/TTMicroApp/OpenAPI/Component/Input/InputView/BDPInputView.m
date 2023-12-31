//
//  BDPInputView.m
//  Timor
//
//  Created by 王浩宇 on 2018/12/4.
//

#import "BDPInputView.h"
#import <OPFoundation/BDPUtils.h>
#import "BDPAppPage.h"
#import "BDPKeyboardManager.h"

#import <OPFoundation/UIView+BDPExtension.h>
#import <OPFoundation/UIColor+BDPExtension.h>
#import <OPFoundation/UITextField+BDPExtension.h>
#import <OPFoundation/EEFeatureGating.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <LarkWebViewContainer/LKNativeRenderDelegate.h>
#import <OPSDK/OPSDK-Swift.h>
#import <OPFoundation/OPFoundation-Swift.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <LarkWebViewContainer/LarkWebViewContainer-Swift.h>

#define KEYBOARD_ADJUST_DELAY 0.1
#define KEYBOARD_ADJUST_DURATION 0.35

static NSString * const IDCARD_CHAR_SET = @"0123456789X";
static NSString * const DIGIT_CHAR_SET = @".,-0123456789";

@interface BDPInputPageFrameFix : NSObject
@property (nonatomic, assign) CGFloat lastPageFrameOrignY;
@property (nonatomic, assign) BOOL needSetLastPageFrameOrignY;
@end

@implementation BDPInputPageFrameFix

- (CGRect)keyboardShowWithTargetFrame:(const CGRect)targetFrame offset:(const CGFloat)offset {
    CGRect result = targetFrame;
    if (self.needSetLastPageFrameOrignY) {
        // 防止多次重复调用
        return result;
    }
    if (offset > 0) {
        self.needSetLastPageFrameOrignY = YES;
        self.lastPageFrameOrignY = targetFrame.origin.y;
        result.origin.y -= offset;
    } else {
        self.needSetLastPageFrameOrignY = NO;
    }
    return result;
}

- (CGRect)keyboardHideWithTargetFrame:(const CGRect)targetFrame {
    CGRect result = targetFrame;
    if (self.needSetLastPageFrameOrignY) {
        result.origin.y = self.lastPageFrameOrignY;
    }
    self.needSetLastPageFrameOrignY = NO;
    self.lastPageFrameOrignY = 0;
    return result;
}

@end

@interface BDPInputView () <UITextFieldDelegate, LKNativeRenderDelegate, OPComponentKeyboardDelegate>

@property (nonatomic, assign) BOOL isKeyboardShowFired;
@property (nonatomic, strong, nullable) BDPInputPageFrameFix *pageFrameFix;

@property (nonatomic, assign) BOOL enableKeyboardOpt;
@property (nonatomic, strong) OPComponentKeyboardHelper *keyboardHelper;

@property (nonatomic, assign, readwrite) BOOL isNativeComponent; // 是否是用的新框架
@property (nonatomic, assign, readwrite) BOOL isOverlay; // 是否是同层框架下overlay渲染
@property (nonatomic, assign) BOOL needListenOrientation;
@property (nonatomic, assign) UIInterfaceOrientation interfaceOrientation;

@end

@implementation BDPInputView
@synthesize renderState = _renderState;

- (NSString *)resultText {
    return [self.text stringByReplacingOccurrencesOfString:@"\u00a0" withString:@" "];
}

#pragma mark - Initialize
/*-----------------------------------------------*/
//              Initialize - 初始化相关
/*-----------------------------------------------*/
- (instancetype)initWithModel:(BDPInputViewModel *)model {
    self = [self initWithFrame:model.style.frame];
    if (self) {
        _enableKeyboardOpt = [EEFeatureGating boolValueForKey:EEFeatureGatingKeyNativeComponentKeyboardOpt];
        if (_enableKeyboardOpt) {
            _keyboardHelper = [[OPComponentKeyboardHelper alloc] initWithDelegate:self];
        }
        [self setupViews];
        [self setupViewModel:model];
        [self addKeyboardObserve];
        [self setupSpaceFixAction];
    }
    return self;
}

- (instancetype)initWithModel:(BDPInputViewModel *)model isNativeComponent:(BOOL)isNativeComponent isOverlay:(BOOL)isOverlay {
    self = [self initWithModel:model];
    self.isOverlay = isOverlay;
    self.isNativeComponent = isNativeComponent;
    [self listeningRotating: isOverlay || !isNativeComponent];
    return self;
}

- (void)cut:(id)sender {
    // 同复制，剪切的时候需要把nonBreakingSpace 换回来
    [SCPasteboardOCBridge setGeneralWithToken:OPSensitivityEntryTokenBDPInputViewCut string:[self resultText]];
    self.text = @"";
}

- (void)copy:(id)sender {
    // 复制的时候需要把nonBreakingSpace 换回来
    [SCPasteboardOCBridge setGeneralWithToken:OPSensitivityEntryTokenBDPInputViewCopy string: [self resultText]];
}

- (void)setTextAlignment:(NSTextAlignment)textAlignment {
    if (textAlignment == NSTextAlignmentRight && self.textAlignment != textAlignment) {
        // 如果改变alignment需要处理下
        [self replaceNormalSpaceWithNonBreakingSpace];
    } else {
        [self replaceNonBreakingSpaceWithNormalSpace];
    }
    [super setTextAlignment:textAlignment];
}

- (void)setupSpaceFixAction {
    [self addTarget:self action:@selector(replaceNormalSpaceWithNonBreakingSpace) forControlEvents:UIControlEventEditingDidBegin];
    [self addTarget:self action:@selector(replaceNormalSpaceWithNonBreakingSpace) forControlEvents:UIControlEventEditingChanged];
}

- (void)replaceNormalSpaceWithNonBreakingSpace {
    if (self.textAlignment != NSTextAlignmentRight) {
        // 右对齐的情况下才需要替换
        return;
    }
    // 高亮部分其实没确定，不做替换，不然在iOS14上无法输入词组了
    NSString *lang = [[self textInputMode] primaryLanguage]; // 键盘输入模式
    if ([lang isEqualToString:@"zh-Hans"]) { // 简体中文输入，包括简体拼音，健体五笔，简体手写
        UITextRange *selectedRange = [self markedTextRange];       //获取高亮部分
        if (selectedRange && !selectedRange.isEmpty) {
            // 高亮部分没确定，不做替换
            return;
        }
    }
    self.text = [self.text stringByReplacingOccurrencesOfString:@" " withString:@"\u00a0"];
}

- (void)replaceNonBreakingSpaceWithNormalSpace {
    NSString *text = [self.text stringByReplacingOccurrencesOfString:@"\u00a0" withString:@" "];
    if (![self.text isEqual:text]) {
        self.text = text;
    }
}

- (void)setupViews {
    self.isKeyboardShowFired = NO;
    self.backgroundColor = [UIColor clearColor];
    self.delegate = self;
    [self addTarget:self action:@selector(textFieldTextChanged:) forControlEvents:UIControlEventEditingChanged];
    if ([OPSDKFeatureGating enableInputPageFrameOriginYFix]) {
        self.pageFrameFix = [[BDPInputPageFrameFix alloc] init];
    }
}

- (void)setupViewModel:(BDPInputViewModel *)model {
    if (model) {
        self.text = model.value;
        self.secureTextEntry = model.password;
        
        if (model.style) {
            self.font = [model.style font];
            self.textColor = [UIColor colorWithHexString:model.style.color];
            self.backgroundColor = [UIColor colorWithHexString:model.style.backgroundColor];
            self.textAlignment = [model.style textAlignment];
        }
        
        self.placeholder = model.placeholder;
        self.attributedPlaceholder = [model attributedPlaceholder];
        
        [self updateKeyboardType:model.type];
        [self updateReturnKeyType:model.confirmType];
        self.model = model;
    }
}

- (void)setComponentID:(NSInteger)componentID {
    _componentID = componentID;
    _keyboardHelper.componentID = [NSString stringWithFormat:@"%ld", componentID];
}

#pragma mark - LKNativeRenderDelegate

- (void)lk_render
{
    BDPLogInfo(@"lk_render, superviewWillBeRemoved: %@", @(self.renderState.superviewWillBeRemoved));
    if (self.renderState.superviewWillBeRemoved) {
        self.renderState.superviewWillBeRemoved = NO;
    }
}

#pragma mark - UITextFieldDelegate
/*-----------------------------------------------*/
//        UITextFieldDelegate - 输入组件代理
/*-----------------------------------------------*/
- (BOOL)becomeFirstResponder
{
    BOOL become = [super becomeFirstResponder];
    BDPLogInfo(@"become first responder, keyboardShow: %@ %@, become: %@", @(self.isKeyboardShowFired), @([BDPKeyboardManager sharedManager].isKeyboardShow), @(become));
    if (!become) {
        [self resignFirstResponder];
        return become;
    }
    
    if (self.enableKeyboardOpt) {
        if (become && [self.keyboardHelper isKeyboardShowing]) {
            [self.keyboardHelper keyboardWillShow];
        }
    } else {
        // Trick Code - 解决部分系统键盘无WillHide, willChange回调
        [self fixAppPageFrameWhenBecomeFirstResponder];
        
        // 判断键盘是否已经展示
        if (!self.isKeyboardShowFired && [BDPKeyboardManager sharedManager].isKeyboardShow) {
            self.isKeyboardShowFired = YES;
            CGRect keyboardFrame = [[BDPKeyboardManager sharedManager] keyboardFrame];
            [self fireEventToWebView:@"onKeyboardShow"
                                data:@{@"inputId": @(self.componentID),
                                       @"height": @(keyboardFrame.size.height),
                                       @"value": [self resultText]
                                     }];
        }
    }
    
    return become;
}

- (BOOL)resignFirstResponder
{
    if (self.isNativeComponent && !self.isOverlay && self.renderState.superviewWillBeRemoved) {
        BDPLogInfo(@"resignFirstResponder return NO");
        WeakSelf;
        dispatch_async(dispatch_get_main_queue(), ^{
            StrongSelfIfNilReturn;
            BDPLogInfo(@"resignFirstResponder next runloop, should resign: %@", @(self.renderState.superviewWillBeRemoved));
            if (self.renderState.superviewWillBeRemoved) {
                self.renderState.superviewWillBeRemoved = NO;
                [self resignFirstResponder];
            }
        });
        return NO;
    }
    
    BDPLogInfo(@"resign first responder, isNative: %@, isOverlay: %@", @(self.isNativeComponent), @(self.isOverlay));
    BOOL resign = [super resignFirstResponder];
    
    if (self.enableKeyboardOpt) {
        if (resign) {
            [self.keyboardHelper keyboardWillHide];
        }
    } else {
        // Trick Code - 解决部分系统键盘无WillHide, willChange回调
        [self fixAppPageFrameWhenResignFirstResponder];
    }
    
    // 键盘完成消息
    self.isKeyboardShowFired = NO;
    [self fireEventToWebView:@"onKeyboardComplete"
                        data:@{@"cursor": @(self.bdp_selectedRange.location),
                               @"inputId": @(self.componentID),
                               @"value": [self resultText] ?: @""}];

    // 移除视图 如果是同层渲染则不应该移除
    if (!self.isNativeComponent) {
        [self removeFromSuperview];
    } else if (self.isOverlay) {
        [self setOverlayStatus:NO];
    }
    
    return resign;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    BDPLogInfo(@"keyboard confirm");
    [self fireEventToWebView:@"onKeyboardConfirm"
                        data:@{@"inputId": @(self.componentID),
                               @"value": [self resultText] ?: @""}];
    [self resignFirstResponder];
    return YES;
}

- (void)textFieldTextChanged:(UITextField *)textField
{
    if (textField != self) {
        return;
    }
    
    // 有选中的高亮文字为中文输入法，高亮部分不算做文本改变
    NSString *lang = [[self textInputMode] primaryLanguage]; // 键盘输入模式
    if ([lang isEqualToString:@"zh-Hans"]) { // 简体中文输入，包括简体拼音，健体五笔，简体手写
        UITextRange *selectedRange = [self markedTextRange];       //获取高亮部分
        UITextPosition *position = [self positionFromPosition:selectedRange.start offset:0];
        if (position) {
            return;
        }
    }
    
    // 限制字数在maxLength范围内
    if (self.model.maxLength && self.text.length > self.model.maxLength) {
        self.text = [self.text substringToIndex:self.model.maxLength];
        [self updateCursor:self.text.length selectionStart:-1 selectionEnd:-1];
    }
    
    // onKeyboardValueChange
    [self fireEventToAppService:@"onKeyboardValueChange"
                           data:@{@"inputId" : @(self.componentID),
                                  @"value" : [self resultText] ?: @"",
                                  @"cursor" : @(self.bdp_selectedRange.location),
                                  @"data" : self.model.data ?: @""}];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if ([self.model.type isEqualToString:@"idcard"] && self.keyboardType == UIKeyboardTypeDefault) {
        // 限制在「idcard」场景下，除 “数字” 和 “X” 以外其他字符的输入
        NSCharacterSet *cs = [[NSCharacterSet characterSetWithCharactersInString:IDCARD_CHAR_SET] invertedSet];
        NSString *filtered = [[string componentsSeparatedByCharactersInSet:cs] componentsJoinedByString:@""];
        return [string isEqualToString:filtered];
    }
    if ([self.model.type isEqualToString:@"digit"] && self.keyboardType == UIKeyboardTypeNumbersAndPunctuation) {
        // 限制在「digit」场景下，除 “数字”、“-”、“.”以及“,” 以外其他字符的输入
        NSCharacterSet *cs = [[NSCharacterSet characterSetWithCharactersInString:DIGIT_CHAR_SET] invertedSet];
        NSString *filtered = [[string componentsSeparatedByCharactersInSet:cs] componentsJoinedByString:@""];
        return [string isEqualToString:filtered];
    }
    if (self.keyboardType == UIKeyboardTypeNumberPad || self.keyboardType == UIKeyboardTypeDecimalPad) {
        return [self checkValidateNumber:string keyboardType:self.keyboardType];
    }
    return YES;
}

#pragma mark - Notification Observer
/*-----------------------------------------------*/
//         Notification Observer - 通知
/*-----------------------------------------------*/
- (void)addKeyboardObserve {
    if (self.enableKeyboardOpt) {
        return;
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChange:) name:UIKeyboardWillChangeFrameNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    BDPLogInfo(@"keyboardWillShow isFirstRes: %@, isKeyboardShow: %@", @(self.isFirstResponder), @(self.isKeyboardShowFired));
    if (self.isFirstResponder) {
        // 键盘展示消息只能发送一次并带上键盘高度，键盘弹起后高度变化不在告知JSSDK
        if (!self.isKeyboardShowFired) {
            self.isKeyboardShowFired = YES;
            CGRect keyboardFrame = [[notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
            [self fireEventToWebView:@"onKeyboardShow"
                                data:@{@"inputId": @(self.componentID),
                                       @"height": @(keyboardFrame.size.height),
                                       @"value": [self resultText]
                                     }];
        };
    }
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    BDPLogInfo(@"keyboardWillHide isNative: %@, isFirstRes: %@, isOverlay: %@", @(self.isNativeComponent), @(self.isFirstResponder), @(self.isOverlay));
    if (self.isNativeComponent && !self.isFirstResponder && !self.isOverlay) {
        return; // 同层组件时，应当判断自身是否是第一响应者
    }
    self.isKeyboardShowFired = NO;
    if (self.model.adjustPosition) {
        [self adjustAppPageFrameForKeyboardHidden:notification];
    }
}

- (void)keyboardWillChange:(NSNotification *)notification
{
    // 将键盘遮挡部分弹起
    if (self.isFirstResponder) {
        if (self.model.adjustPosition) {
            [self adjustAppPageFrameForKeyboardShow:notification];
        }
        [self updateCursorAndSelection:self.model];
    }
}

#pragma mark - OPComponentKeyboardDelegate

- (void)keyboardWillShowWithKeyboardInfo:(OPComponentKeyboardInfo *)keyboardInfo {
    CGRect appPageFrameInWindow = [self.page.superview convertRect:self.page.frame toView:nil];
    CGRect textFrameInWindow = [self.superview convertRect:self.frame toView:nil];

    if (!CGRectIntersectsRect(appPageFrameInWindow, textFrameInWindow)) {
        [self resignFirstResponder];
        return;
    }
    
    if (!self.isKeyboardShowFired) {
        self.isKeyboardShowFired = YES;
        [self fireEventToWebView:@"onKeyboardShow"
                            data:@{@"inputId": @(self.componentID),
                                   @"height": @([self.keyboardHelper getKeyboardHeight]),
                                   @"value": [self resultText]
                                 }];
    }
    [self adjustPageFrame:keyboardInfo.adjustFrame duration:keyboardInfo.animDuration options:keyboardInfo.animOption];
    [self updateCursorAndSelection:self.model];
}

- (void)keyboardWillHideWithKeyboardInfo:(OPComponentKeyboardInfo *)keyboardInfo {
    self.isKeyboardShowFired = NO;
    if (self.model.adjustPosition) {
        [self.page.layer removeAllAnimations];
        [UIView animateWithDuration:keyboardInfo.animDuration delay:0.f options:keyboardInfo.animOption animations:^{
            self.page.frame = keyboardInfo.adjustFrame;
        } completion:nil];
    }
}

- (CGRect)owningViewFrame {
    CGRect textFrameInWindow = [self.superview convertRect:self.frame toView:nil];
    textFrameInWindow.size.height += self.model.style.marginBottom;
    return textFrameInWindow;
}

- (CGRect)adjustViewFrame {
    return self.page.frame;
}

- (id<UICoordinateSpace>)adjustViewCoordinateSpace {
    return self.page.superview;
}

- (BOOL)isOwningViewFirstResponder {
    return self.isFirstResponder;
}

#pragma mark - Orientation

/**
 *  监听设备旋转通知
 */
- (void)listeningRotating: (BOOL)need {
    self.needListenOrientation = need;
    if (!need) {
        return;
    }
    self.interfaceOrientation = [BDPInputView getInterfaceOrientation];
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onDeviceOrientationChange)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
}

- (void)onDeviceOrientationChange {
    // overlay才会监听
    UIInterfaceOrientation interfaceOrientation = [BDPInputView getInterfaceOrientation];
    if (self.interfaceOrientation == interfaceOrientation) {
        return;
    }
    self.interfaceOrientation = interfaceOrientation;
    if (self.isFirstResponder) {
        [self endEditing:YES];
    }
}

- (void)dealloc {
    if (_needListenOrientation) {
        [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    }
}

#pragma mark - Keyboard Blocking Layout
/*-----------------------------------------------*/
//     Keyboard Blocking Layout - 键盘遮挡布局
/*-----------------------------------------------*/

- (void)adjustPageFrame:(CGRect)adjustFrame duration:(NSTimeInterval)duration options:(UIViewAnimationOptions)options {
    if (!self.isFirstResponder || !self.model.adjustPosition) {
        return;
    }
    
    [self.page.layer removeAllAnimations];
    [UIView animateWithDuration:duration delay:0.f options:options animations:^{
        self.page.frame = adjustFrame;
    } completion:nil];
}

- (void)adjustAppPageFrameForKeyboardShow:(NSNotification *)notification
{
    CGFloat duration = [notification.userInfo bdp_doubleValueForKey:UIKeyboardAnimationDurationUserInfoKey];
    CGRect keyboardFrame = [[notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    // 在iPad浮动键盘下会有Bug，浮动键盘应该看做是CGRectZero
    if (keyboardFrame.size.width < UIScreen.mainScreen.bounds.size.width) {
        keyboardFrame.size = CGSizeZero;
        keyboardFrame.origin = CGPointZero;
    }
    // 此处延迟0.1s是为了响应效果与UITextView(JS-TextArea组件)一致，不是因为有坑😂
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(KEYBOARD_ADJUST_DELAY * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:duration delay:0.f options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.page.frame = [self containerThatFitsForFrame:self.page.frame
                                                keyboardFrame:keyboardFrame];
        } completion:nil];
    });
}

- (void)adjustAppPageFrameForKeyboardHidden:(NSNotification *)notification
{
    CGRect targetFrame = self.page.frame;
    if (self.pageFrameFix) {
        targetFrame = [self.pageFrameFix keyboardHideWithTargetFrame:targetFrame];
    } else {
        targetFrame.origin.y = 0;
    }
    UIViewAnimationOptions options = [self animationOptions:notification];
    CGFloat duration = [notification.userInfo bdp_doubleValueForKey:UIKeyboardAnimationDurationUserInfoKey];
    [UIView animateWithDuration:duration delay:0.f options:options animations:^{
        self.page.frame = targetFrame;
    } completion:nil];
}

- (CGRect)containerThatFitsForFrame:(CGRect)frame keyboardFrame:(CGRect)keyboardFrame
{
    CGRect targetFrame = frame;
    if (CGRectEqualToRect(CGRectZero, keyboardFrame)) {
        targetFrame.origin.y = 0;
        return targetFrame;
    }
    CGFloat offset = (CGRectGetMaxY(self.absFrame) - CGRectGetMinY(keyboardFrame));
    if (self.pageFrameFix) {
        targetFrame = [self.pageFrameFix keyboardShowWithTargetFrame:targetFrame offset:offset];
    } else {
        targetFrame.origin.y -= offset;
        targetFrame.origin.y = targetFrame.origin.y >= 0 ? 0 : targetFrame.origin.y;
    }
    return targetFrame;
}

#pragma mark - Force Fix PageFrame
/*-----------------------------------------------*/
//    Force Fix PageFrame - 强制修复 Frame 问题
/*-----------------------------------------------*/
- (BOOL)fixAppPageFrameSystemVersion
{
    // Trick Code - 解决部分系统半嗯的键盘无WillHide, willChange通知回调
    // 参考：https://stackoverflow.com/questions/51193470/keyboard-notification-not-called-in-ios-11-3
    CGFloat systemVersion = [UIDevice currentDevice].systemVersion.floatValue;
    if (systemVersion >= 11.0f && systemVersion < 11.5f) {
        return YES;
    }
    if (systemVersion >= 13.0f) {
        return YES;
    }
    return NO;
}

- (void)fixAppPageFrameWhenBecomeFirstResponder
{
    // Trick Code - 解决部分系统半嗯的键盘无WillHide, willChange通知回调
    BOOL isNeedFixAppPageFrame = [self fixAppPageFrameSystemVersion];
    if (self.model.adjustPosition && isNeedFixAppPageFrame) {
        
        // 如果键盘已经展示，根据frame重新计算appPage上滑距离
        if ([BDPKeyboardManager sharedManager].isKeyboardShow) {
            CGRect keyboardFrame = [BDPKeyboardManager sharedManager].keyboardFrame;
            
            // 这里不能移除动画，否则会出现页面闪动
//            [self.page.layer removeAllAnimations];
            [UIView animateWithDuration:KEYBOARD_ADJUST_DURATION delay:0.f options:UIViewAnimationOptionCurveEaseInOut animations:^{
                self.page.frame = [self containerThatFitsForFrame:self.page.frame
                                                    keyboardFrame:keyboardFrame];
            } completion:nil];
        }
    }
}

- (void)fixAppPageFrameWhenResignFirstResponder
{
    // Trick Code 解决部分系统半嗯的键盘无WillHide, willChange通知回调
    BOOL isNeedFixAppPageFrame = [self fixAppPageFrameSystemVersion];
    if (self.model.adjustPosition && isNeedFixAppPageFrame) {
        
        // 这里不能移除动画，否则会出现页面闪动
//        [self.page.layer removeAllAnimations];
        
        // 失去焦点时，因收不到隐藏通知，只能强行恢复AppPage原始位置，再在becomeFirstResponder重新计算高度
        CGRect targetFrame = CGRectZero;
        if (self.pageFrameFix) {
            targetFrame = [self.pageFrameFix keyboardHideWithTargetFrame:self.page.frame];
        } else {
            targetFrame = CGRectMake(self.page.bdp_left, 0, self.page.bdp_width, self.page.bdp_height);
        }
        [UIView animateWithDuration:KEYBOARD_ADJUST_DURATION delay:0.f options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.page.frame = targetFrame;
        } completion:nil];
    }
}

#pragma mark - Variables Getters & Setters
/*-----------------------------------------------*/
//     Variables Getters & Setters - 变量相关
/*-----------------------------------------------*/
- (CGRect)absFrame
{
    // Convert TextView & AppPage Frame to window Coordinate System
    CGRect appPageFrameInWindow = [self.page.superview convertRect:self.page.frame toView:nil];
    CGRect textFrameInWindow = [self.superview convertRect:self.frame toView:nil];
    textFrameInWindow.size.height +=  self.model.style.marginBottom;
    
    // 超出AppPage底部的部分要删掉，计算在AppPage内的部分
    CGFloat frameOutOfAppPage = CGRectGetMaxY(textFrameInWindow) - CGRectGetMaxY(appPageFrameInWindow);
    if (frameOutOfAppPage > 0.f) {
        textFrameInWindow.size.height -= frameOutOfAppPage;
    }
    return textFrameInWindow;
}

- (void)updateWithDictionary:(NSDictionary *)dict
{
    // Non-Null Dictionary
    if (BDPIsEmptyDictionary(dict)) {
        return;
    }
    
    // UpdateInput方法传输的参数为增量，有则更新，没有则不做处理。
    // 增量判断参数是否需要更新
    if ([dict valueForKey:@"adjustPosition"]) {
        self.model.adjustPosition = [dict bdp_boolValueForKey:@"adjustPosition"];
    }
    if ([dict valueForKey:@"data"]) {
        self.model.data = [dict bdp_stringValueForKey:@"data"];
    }
    
    if ([dict valueForKey:@"maxLength"]) {
        self.model.maxLength = [dict bdp_integerValueForKey:@"maxLength"];
    }
    
    if ([dict valueForKey:@"password"]) {
        self.model.password = [dict bdp_boolValueForKey:@"password"];
        self.secureTextEntry = self.model.password;
    }
    
    if ([dict valueForKey:@"type"]) {
        self.model.type = [dict bdp_stringValueForKey:@"type"];
        [self updateKeyboardType:self.model.type];
    }
    
    if ([dict valueForKey:@"value"]) {
        self.model.value = [dict bdp_stringValueForKey:@"value"];
        if (![self.model.value isEqual:self.text]) {
            self.text = self.model.value;
        }
    }
    
    if ([dict valueForKey:@"confirmType"]) {
        self.model.confirmType = [dict bdp_stringValueForKey:@"confirmType"];
        [self updateReturnKeyType:self.model.confirmType];
    }
    
    if ([dict valueForKey:@"placeholder"]) {
        self.model.placeholder = [dict bdp_stringValueForKey:@"placeholder"];
        self.placeholder = self.model.placeholder;
    }
    
    // style参数是一个子类，如果传了style则内容一定为全量参数，直接全量使用即可
    if ([dict valueForKey:@"style"]) {
        // Get Style Param
        NSDictionary *styleDict = [dict bdp_dictionaryValueForKey:@"style"];
        [self.model.style updateWithDictionary:styleDict];
        
        // Update Style
        if (self.model.style) {
            self.font = [self.model.style font];
            self.textAlignment = [self.model.style textAlignment];
            self.textColor = [UIColor colorWithHexString:self.model.style.color];
            self.backgroundColor = [UIColor colorWithHexString:self.model.style.backgroundColor];
            if (!CGRectIsNull(self.model.style.frame)) {
                self.frame = self.model.style.frame;
            }
        }
    }
    
    // placeholderStyle参数是一个子类，如果传了placeholderStyle则内容一定为全量参数，直接全量使用即可
    if ([dict valueForKey:@"placeholderStyle"]) {
        // Get PlaceHolder Style Param
        NSDictionary *placeholderStyleDict = [dict bdp_dictionaryValueForKey:@"placeholderStyle"];
        [self.model.placeholderStyle updateWithDictionary:placeholderStyleDict];
        
        // Update PlaceHolder Style
        self.attributedPlaceholder = [self.model attributedPlaceholder];
    }
    
    // 更新 focus
    if ([dict valueForKey:@"focus"]) {
        BOOL focus = [dict bdp_boolValueForKey2:@"focus"];
        self.model.focus = focus;
    }
    
    // 更新disable
    if ([dict valueForKey:@"disabled"]) {
        BOOL disabled = [dict bdp_boolValueForKey2:@"disabled"];
        self.model.disabled = disabled;
    }
}

#pragma mark - Update
/*-----------------------------------------------*/
//               Update - 状态更新
/*-----------------------------------------------*/
- (void)updateKeyboardType:(NSString *)type
{
    if ([type isEqualToString:@"text"]) {
        self.keyboardType = UIKeyboardTypeDefault;
    } else if ([type isEqualToString:@"number"]) {
        self.keyboardType = UIKeyboardTypeNumberPad;
    } else if ([type isEqualToString:@"digit"]) {
        self.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    } else if ([type isEqualToString:@"idcard"]) {
        self.keyboardType = UIKeyboardTypeDefault;
    } else {
        self.keyboardType = UIKeyboardTypeDefault;
    }
}

- (void)updateReturnKeyType:(NSString *)confirmType
{
    if ([confirmType isEqualToString:@"send"]) {
        self.returnKeyType = UIReturnKeySend;
    } else if ([confirmType isEqualToString:@"search"]) {
        self.returnKeyType = UIReturnKeySearch;
    } else if ([confirmType isEqualToString:@"next"]) {
        self.returnKeyType = UIReturnKeyNext;
    } else if ([confirmType isEqualToString:@"go"]) {
        self.returnKeyType = UIReturnKeyGo;
    } else if ([confirmType isEqualToString:@"done"]) {
        self.returnKeyType = UIReturnKeyDone;
    } else {
        self.returnKeyType = UIReturnKeyDone;
    }
}

- (void)updateCursorAndSelection:(BDPInputViewModel *)model
{
    if (self.isFirstResponder) {
        [self updateCursor:model.cursor
            selectionStart:model.selectionStart
              selectionEnd:model.selectionEnd];
        
        // Cursor & Selection 只设置一次即失效
        // 再次设置选中范围需重置model.cursor, model.selectionStart, model.selectionEnd
        model.cursor = -1;
        model.selectionStart = -1;
        model.selectionEnd = -1;
    }
}

- (void)updateCursor:(NSInteger)cursor selectionStart:(NSInteger)selectionStart selectionEnd:(NSInteger)selectionEnd
{
    NSInteger location = cursor;
    NSInteger length = 0;
    
    // selectionStart默认值为-1，此时不生效
    // 选中区域只有在selectionEnd大于selectionStart才生效
    if (selectionStart >= 0 && (selectionStart < selectionEnd)) {
        location = selectionStart;
        length = labs(selectionEnd - selectionStart);
    }
    
    // cursor和selectionStart默认值均为-1，此时不生效
    if (location >= 0) {
        NSRange range = NSMakeRange(location, length);
        // 延迟0.1s确保调用方法时“选中范围”可设置
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(KEYBOARD_ADJUST_DELAY * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self setBdp_selectedRange:range];
        });
    }
}

- (void)updateHeight {
    // 根据fontSize计算新高度给JS
    CGRect rect = [@"test" boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, 0)
                                          options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                       attributes:@{NSFontAttributeName: self.font}
                                          context:nil];
    int height = (int)ceilf(rect.size.height);
    if (self.model.style.height < height) {
        [self fireEventToWebView:@"onComponentAttributeChange" data:@{
            @"style": @{@"height": @((int)ceilf(rect.size.height))}
        }];
    }
}

- (BOOL)checkValidateNumber:(NSString *)number keyboardType:(UIKeyboardType)keyboardType
{
    NSCharacterSet *tmpSet;
    if (keyboardType == UIKeyboardTypeNumberPad) {
        tmpSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
    } else if (keyboardType == UIKeyboardTypeDecimalPad) {
        tmpSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789.,"];
    }
    
    int i = 0;
    while (i < number.length) {
        NSString * string = [number substringWithRange:NSMakeRange(i, 1)];
        if ([string rangeOfCharacterFromSet:tmpSet].length == 0) {
            return NO;
        }
        i++;
    }
    return YES;
}

#pragma mark - Animation
/*-----------------------------------------------*/
//              Animation - 动画切换
/*-----------------------------------------------*/
- (UIViewAnimationOptions)animationOptions:(NSNotification *)notification
{
    UIViewAnimationCurve animationCurve = [[[notification userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue];
    UIViewAnimationOptions options = UIViewAnimationCurveEaseIn | UIViewAnimationCurveEaseOut | UIViewAnimationCurveLinear;
    switch (animationCurve) {
        case UIViewAnimationCurveEaseInOut:
            options = UIViewAnimationOptionCurveEaseInOut;
            break;
        case UIViewAnimationCurveEaseIn:
            options = UIViewAnimationOptionCurveEaseIn;
            break;
        case UIViewAnimationCurveEaseOut:
            options = UIViewAnimationOptionCurveEaseOut;
            break;
        case UIViewAnimationCurveLinear:
            options = UIViewAnimationOptionCurveLinear;
            break;
        default:
            options = animationCurve << 16;
            break;
    }
    
    return options;
}

#pragma mark - Utils
/*-----------------------------------------------*/
//                  Utils - 工具
/*-----------------------------------------------*/
- (void)fireEventToWebView:(NSString *)event data:(NSDictionary *)data
{
    // 代理到新的框架事件
    if (self.eventDelegate) {
        [self.eventDelegate fireInputEvent:event data:data];
        return;
    }
    //jsapi 下沉之后，会出现engine为空的情况。这时需要使用新的事件发送接口
    if (self.engine==nil&&self.fireWebviewEventBlock) {
        // 新版Plugin，不直接依赖engine
        _fireWebviewEventBlock(event, data);
        return;
    }
    // Native Engine
    if (IsGadgetWebView(self.engine)) {
        BDPAppPage *appPage = (BDPAppPage *)self.engine;
        [appPage bdp_fireEvent:event sourceID:appPage.appPageID data:data];
        
    }
}

- (void)fireEventToAppService:(NSString *)event data:(NSDictionary *)data
{
    // 代理到新的框架事件
    if (self.eventDelegate) {
        [self.eventDelegate fireInputEvent:event data:data];
        return;
    }
    //jsapi 下沉之后，会出现engine为空的情况。这时需要使用新的事件发送接口
    if (self.engine==nil&&self.fireAppServiceEventBlock) {
        // 新版Plugin，不直接依赖engine
        _fireAppServiceEventBlock(event, data);
        return;
    }
    
    // Native Engine
    if (IsGadgetWebView(self.engine)) {
        BDPAppPage *appPage = (BDPAppPage *)self.engine;
        [appPage publishEvent:event param:data];
        
    }
}

- (void)setOverlayStatus:(BOOL)isShow {
    if (isShow) {
        self.hidden = NO;
    } else {
        self.hidden = YES;
    }
}

+ (UIInterfaceOrientation)getInterfaceOrientation {
    if (@available(iOS 13.0, *)) {
        return [[[OPWindowHelper fincMainSceneWindow] windowScene] interfaceOrientation] ?: [[UIApplication sharedApplication] statusBarOrientation];
    }
    return [[UIApplication sharedApplication] statusBarOrientation];
}


@end
