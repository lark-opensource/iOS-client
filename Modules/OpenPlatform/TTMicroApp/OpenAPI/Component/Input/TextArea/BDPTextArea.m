//
//  BDPTextArea.m
//  Timor
//
//  Created by 王浩宇 on 2018/12/4.
//

#import "BDPTextArea.h"
#import <OPFoundation/BDPUtils.h>
#import "BDPAppPage.h"
#import "BDPKeyboardManager.h"
#import <OPFoundation/UIColor+BDPExtension.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <OPFoundation/UIView+BDPExtension.h>
#import <OPFoundation/BDPDeviceHelper.h>
#import "BDPAppPage+BDPTextArea.h"
#import <OPFoundation/EEFeatureGating.h>

#import <OPFoundation/TMACustomHelper.h>
#import <OPFoundation/BDPI18n.h>

#import <OPFoundation/OPFoundation-Swift.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <LarkWebViewContainer/LKNativeRenderDelegate.h>
#import <LarkWebViewContainer/LarkWebViewContainer-Swift.h>

#define KEYBOARD_ADJUST_DELAY 0.1
#define KEYBOARD_ADJUST_DURATION 0.35

NSString *const EEFeatureGatingKeyGadgetComponentTextAreaAttributeChangeFix = @"gadget.component.textarea.attribute_change.fix";

@interface BDPTextArea () <UITextViewDelegate, UITextPasteDelegate, LKNativeRenderDelegate, OPComponentKeyboardDelegate>

@property (nonatomic, assign) CGFloat height;
@property (nonatomic, assign) CGFloat textHeight;

@property (nonatomic, assign) BOOL isKeyboardShowFired;
@property (nonatomic, strong) UITextView *placeHolderTextView;
// textarea初始化高度
@property (nonatomic, assign) CGFloat originFrameHeight;
@property (nonatomic, assign) BOOL adjustPageHeight;

// textarea系统padding
@property (nonatomic, assign) UIEdgeInsets originContainerInset;
@property (nonatomic, assign) CGFloat originLinePadding;

@property (nonatomic, assign) BOOL attributeChangeFix;

@property (nonatomic, assign) BOOL enableKeyboardOpt;
@property (nonatomic, strong) OPComponentKeyboardHelper *keyboardHelper;

@end

@implementation BDPTextArea
@synthesize renderState = _renderState;

#pragma mark - Initialize
/*-----------------------------------------------*/
//              Initialize - 初始化相关
/*-----------------------------------------------*/
- (instancetype)initWithModel:(BDPTextAreaModel *)model
{
    self = [self initWithFrame:model.style.frame];
    if (self) {
        self.originFrameHeight = model.style.frame.size.height;
        self.attributeChangeFix = [EEFeatureGating boolValueForKey:EEFeatureGatingKeyGadgetComponentTextAreaAttributeChangeFix];
        self.enableKeyboardOpt = [EEFeatureGating boolValueForKey:EEFeatureGatingKeyNativeComponentKeyboardOpt];
        if (self.enableKeyboardOpt) {
            self.keyboardHelper = [[OPComponentKeyboardHelper alloc] initWithDelegate:self];
        }
        self.originLinePadding = self.textContainer.lineFragmentPadding;
        self.originContainerInset = self.textContainerInset;
        [self setupViews];
        [self setupViewModel:model];
        [self addKeyboardObserve];
        [self updatePaddingFor: self disableDefaultPadding: model.disableDefaultPadding];
    }
    return self;
}

- (void)setupViews
{
    self.isKeyboardShowFired = NO;
    self.backgroundColor = [UIColor clearColor];
    self.delegate = self;
    
    self.pasteDelegate = self;
}

- (void)setupViewModel:(BDPTextAreaModel *)model
{
    if (!model) {
        return;
    }
    if (model.showConfirmBar) {
        [self addConfirmBar];
    }
    self.returnKeyType = UIReturnKeyDefault;
    self.hidden = model.hidden;
    self.scrollEnabled = !model.autoSize;

    // Update Style
    if (model.style) {
        self.font = [model.style font];
        self.textColor = [UIColor colorWithHexString:model.style.color];
        self.backgroundColor = [UIColor colorWithHexString:model.style.backgroundColor];
        self.textAlignment = [model.style textAlignment];
    }

    [self updatePlaceHolder:model];

    // Update Default Value
    [self updateText:model];
    [self updateAttributedText:model];
    [self showOrHidePlaceHolderTextView];
    self.model = model;
}

- (void)setComponentID:(NSString *)componentID {
    _componentID = componentID;
    _keyboardHelper.componentID = componentID;
}

/// 添加键盘上方带有”完成“按钮那一栏
- (void)addConfirmBar {
    UIToolbar *bar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 44)];
    UIBarButtonItem *helloButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    UIBarButtonItem *btnSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:BDPI18n.microapp_m_keyboard_done style:UIBarButtonItemStyleDone target:self action:@selector(dismissKeyBoard)];
    NSArray<UIBarButtonItem *> *buttonsArray = @[helloButton, btnSpace, doneButton];
    bar.items = buttonsArray;
    self.inputAccessoryView = bar;
}

/// 移除键盘上方带有”完成“按钮那一栏
- (void)removeConfirmBar {
    self.inputAccessoryView = nil;
}

- (void)dismissKeyBoard{
    [self fireEventToWebView:@"onKeyboardConfirm"
                        data:@{
                            @"inputId": BDPSafeString(self.componentID),
                            @"value": BDPSafeString(self.text)
                        }];
    UIWindow *window = self.window ?: OPWindowHelper.fincMainSceneWindow;
    [window endEditing:YES];
}

#pragma mark - LKNativeRenderDelegate

- (void)lk_render
{
    BDPLogInfo(@"lk_render, superviewWillBeRemoved: %@", @(self.renderState.superviewWillBeRemoved));
    if (self.renderState.superviewWillBeRemoved) {
        self.renderState.superviewWillBeRemoved = NO;
    }
}

#pragma mark - UITextField Responder
/*-----------------------------------------------*/
//        UITextField Responder - 事件响应
/*-----------------------------------------------*/
- (BOOL)becomeFirstResponder
{
    BOOL become = [super becomeFirstResponder];
    
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
                                data:@{@"inputId": BDPSafeString(self.componentID),
                                       @"height": @(keyboardFrame.size.height)}];
        }
    }
    return become;
}

- (BOOL)resignFirstResponder
{
    if (self.renderState.superviewWillBeRemoved) {
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
                        data:@{@"cursor": @(self.selectedRange.location),
                               @"inputId": BDPSafeString(self.componentID),
                               @"value": BDPSafeString(self.text)}];
    return resign;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([BDPDeviceHelper OSVersionNumber] < 13.f) {
        return YES;
    }

    // 这里是为了解决https://rocket.bytedance.net/bug?biz=9983&bugId=904523 这个问题
    // 在iOS13上三指undo的话会导致crash
    // 这样修改会导致三指undo失效，不然也没有发现其他的方法可以让undo不crash，，，
    BOOL isNumber = text.length == 1 && isnumber([text characterAtIndex:0]);
    BOOL isTextString = text.length > 1;
    if ((isNumber || isTextString) && range.location >= self.model.maxLength) {
        return NO;
    }

    return YES;
}

- (void)textViewDidChange:(UITextView *)textView
{
    WeakSelf;
    dispatch_block_t blk = ^{
        StrongSelfIfNilReturn;
        
        if (textView != self) {
            return;
        }
        
        // 更新height以及光标位置(中文输入法拼音高亮时也应计算)
        // ⚠️这三行方法要严格保证顺序在下方 *真实文字输入* 部分之前。
        [self showOrHidePlaceHolderTextView];
        [self updateHeightForAutoSize:self.model];
        [self adjustAppPageFrameForLineCount:self.model];
        
        //  *真实文字输入* 部分(高亮拼音不算做真实文字输入)
        // 有选中的高亮文字为中文输入法，高亮部分不算做文本改变
        NSString *lang = [[self textInputMode] primaryLanguage]; // 键盘输入模式
        if ([lang isEqualToString:@"zh-Hans"]) { // 简体中文输入，包括简体拼音，健体五笔，简体手写
            UITextRange *selectedRange = [self markedTextRange];       //获取高亮部分
            UITextPosition *position = [self positionFromPosition:selectedRange.start offset:0];
            if (position) {
                return;
            }
        }
        
        if (self.model.maxLength && self.text.length > self.model.maxLength) {
            self.text = [self.text substringToIndex:self.model.maxLength];
            [self updateHeightForAutoSize:self.model];
            [self updateCursor:self.text.length selectionStart:-1 selectionEnd:-1];
        }
        
        // 更新lineSpace等富文本，仅在有效输入时才进行
        [self updateAttributedText:self.model];
        
        // onKeyboardValueChange
        [self fireEventToAppService:@"onKeyboardValueChange"
                               data:@{@"inputId" : BDPSafeString(self.componentID),
                                      @"value" : BDPSafeString(self.text),
                                      @"cursor" : @(self.selectedRange.location),
                                      @"data" : BDPSafeString(self.model.data)}];
        
        // 修复粘贴大量文字后回到头部
        [self scrollRangeToVisible:self.selectedRange];
    };
    
    // 这里是为了解决https://rocket.bytedance.net/bug?biz=9983&bugId=904523 这个问题
    // 在iOS13上三指undo的话会导致crash
    // 复现路径：切到拼音输入法， 疯狂按键盘但是不要按确定，然后再键盘三指上滑撤销
    if ([BDPDeviceHelper OSVersionNumber] >= 13.f) {
        dispatch_async(dispatch_get_main_queue(), ^{
            blk();
        });
    } else {
        blk();
    }
}

- (void)textViewDidChangeSelection:(UITextView *)textView {
    if (self.enableKeyboardOpt) {
        if ([self.keyboardHelper isKeyboardShowing]) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(KEYBOARD_ADJUST_DELAY * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self adjustPageFrame:[self.keyboardHelper getAdjustFrame] duration:KEYBOARD_ADJUST_DURATION options:UIViewAnimationOptionCurveEaseInOut];
            });
        }
    } else {
        if (self.model.adjustPosition) {
            if ([BDPKeyboardManager sharedManager].isKeyboardShow) {
                [self adjustPageContainerFrameForKeyboardFrame:[BDPKeyboardManager sharedManager].keyboardFrame duration:KEYBOARD_ADJUST_DURATION options:UIViewAnimationOptionCurveEaseInOut];
            }
        }
    }
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    return !self.model.disabled;
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    [self showOrHidePlaceHolderTextView];
}

- (BOOL)textPasteConfigurationSupporting:(id<UITextPasteConfigurationSupporting>)textPasteConfigurationSupporting shouldAnimatePasteOfAttributedString:(NSAttributedString*)attributedString toRange:(UITextRange*)textRange API_AVAILABLE(ios(11.0))
{
    return NO;
}

- (void)paste:(id)sender
{
    [super paste:sender];
    
    // Trick Code - UITextView sizeThatFits首次粘贴时计算错误
    // 首次粘贴文本时textDidChange通过[view sizeThatFits]得到的结果过小，导致视图偏移错误
    // 因此通过延迟0.2s(0.1s不够)保证sizeThatFits计算结果正确
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self updateHeightForAutoSize:self.model];
        [self adjustAppPageFrameForLineCount:self.model];
    });
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
                            data:@{@"inputId": BDPSafeString(self.componentID),
                                   @"height": @([self.keyboardHelper getKeyboardHeight])}];
    }
    [self adjustPageFrame:keyboardInfo.adjustFrame duration:keyboardInfo.animDuration options:keyboardInfo.animOption];
    [self updateCursorAndSelection:self.model];
}

- (void)keyboardWillHideWithKeyboardInfo:(OPComponentKeyboardInfo *)keyboardInfo {
    self.isKeyboardShowFired = NO;
    if (self.model.adjustPosition) {
        [self.page.layer removeAllAnimations];
        ((BDPAppPage *)self.page).bap_lockFrameForEditing = NO;
        [UIView animateWithDuration:keyboardInfo.animDuration delay:0.f options:keyboardInfo.animOption animations:^{
            self.page.frame = keyboardInfo.adjustFrame;
        } completion:nil];
    }
}

- (CGRect)owningViewFrame {
    CGRect textFrameInWindow = [self.superview convertRect:self.frame toView:nil];
    CGFloat resultHeight = textFrameInWindow.size.height;
    if (self.selectedTextRange) {
        CGRect cursorRect = [self caretRectForPosition:self.selectedTextRange.end];
        resultHeight = MIN(resultHeight - self.textContainerInset.bottom, CGRectGetMaxY(cursorRect) - self.contentOffset.y);
    }
    textFrameInWindow.size.height = resultHeight + self.model.style.marginBottom;
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

#pragma mark - Notification Observer
/*-----------------------------------------------*/
//         Notification Observer - 通知
/*-----------------------------------------------*/
- (void)addKeyboardObserve
{
    if (self.enableKeyboardOpt) {
        return;
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChange:) name:UIKeyboardWillChangeFrameNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    if (self.isFirstResponder) {
        // 键盘展示消息只能发送一次并带上键盘高度，键盘弹起后高度变化不在告知JSSDK
        if (!self.isKeyboardShowFired) {
            self.isKeyboardShowFired = YES;
            CGRect keyboardFrame = [[notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
            [self fireEventToWebView:@"onKeyboardShow"
                                data:@{@"inputId": BDPSafeString(self.componentID),
                                       @"height": @(keyboardFrame.size.height)}];
        }
    }
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    // 只要是键盘事件就会发通知，即使当前view不在最上层tab。此时应当判断自己是否是第一响应者
    if (self.isFirstResponder) {
        self.isKeyboardShowFired = NO;
        if (self.model.adjustPosition) {
            [self adjustAppPageFrameForKeyboardHidden:notification];
        }
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

#pragma mark - Keyboard Blocking Layout
/*-----------------------------------------------*/
//     Keyboard Blocking Layout - 键盘遮挡布局
/*-----------------------------------------------*/

- (void)adjustPageFrame:(CGRect)adjustFrame duration:(NSTimeInterval)duration options:(UIViewAnimationOptions)options {
    if (!self.isFirstResponder || !self.model.adjustPosition) {
        return;
    }
    
    [self.page.layer removeAllAnimations];
    ((BDPAppPage *)self.page).bap_lockFrameForEditing = YES;
    [UIView animateWithDuration:duration delay:0.f options:options animations:^{
        self.page.frame = adjustFrame;
    } completion:nil];
}

- (void)adjustPageFrameForHeightChange {
    if (self.enableKeyboardOpt) {
        if ([self.keyboardHelper isKeyboardShowing]) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(KEYBOARD_ADJUST_DELAY * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self adjustPageFrame:[self.keyboardHelper getAdjustFrame] duration:KEYBOARD_ADJUST_DURATION options:UIViewAnimationOptionCurveEaseInOut];
            });
        }
    } else {
        if ([BDPKeyboardManager sharedManager].isKeyboardShow) {
            [self adjustPageContainerFrameForKeyboardFrame:[BDPKeyboardManager sharedManager].keyboardFrame duration:KEYBOARD_ADJUST_DURATION options:UIViewAnimationOptionCurveEaseInOut];
        }
    }
}

- (void)adjustAppPageFrameForKeyboardShow:(NSNotification *)notification
{
    UIViewAnimationOptions options = [self animationOptions:notification];
    CGFloat duration = [notification.userInfo bdp_doubleValueForKey:UIKeyboardAnimationDurationUserInfoKey];
    CGRect keyboardFrame = [[notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    [self adjustPageContainerFrameForKeyboardFrame:keyboardFrame duration:duration options:options];
}

- (void)adjustAppPageFrameForKeyboardHidden:(NSNotification *)notification
{
    UIViewAnimationOptions options = [self animationOptions:notification];
    CGFloat duration = [notification.userInfo bdp_doubleValueForKey:UIKeyboardAnimationDurationUserInfoKey];
    [self resetPageContainerFrameWithAnimationDuration:duration options:options];
}

- (void)adjustAppPageFrameForLineCount:(BDPTextAreaModel *)model
{
    // AutoSize为NO时，文本最大高度不能超过model.frame.size.height
    CGFloat maxHeight = model.autoSize ? model.style.maxHeight : self.frame.size.height;
    CGFloat height = [self getTextHeightWithCursor:self.selectedRange.location+self.selectedRange.length+1];
    height = [TMACustomHelper adjustHeight:height maxHeight:maxHeight minHeight:0];

    // 高度发生变化时
    if (_height != height) {
        _height = height;
        [self adjustPageFrameForHeightChange];
    }
}

- (void)adjustPageContainerFrameForKeyboardFrame: (CGRect)keyboardFrame duration: (CGFloat)duration options: (UIViewAnimationOptions)options {
    if (self.attributeChangeFix && !self.isFirstResponder) {
        return;
    }
    if (self.model.adjustPosition) {
        // 先移除所有动画，然后再设置frame，避免闪动
        [self.page.layer removeAllAnimations];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(KEYBOARD_ADJUST_DELAY * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            ((BDPAppPage *)self.page).bap_lockFrameForEditing = YES;
            [UIView animateWithDuration:duration delay:0.f options:options animations:^{
                [self adjustPageContainerFrameForKeyboardFrame:keyboardFrame];
            } completion:nil];
        });
    }
}

- (void)resetPageContainerFrameWithAnimationDuration: (CGFloat)duration options: (UIViewAnimationOptions)options {
    // 先移除所有动画，然后再设置frame，避免闪动
    [self.page.layer removeAllAnimations];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(KEYBOARD_ADJUST_DELAY * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        ((BDPAppPage *)self.page).bap_lockFrameForEditing = NO;
        [UIView animateWithDuration:duration delay:0.f options:options animations:^{
            self.page.frame = _pageOriginFrame;
        } completion:nil];
    });
}

- (void)adjustPageContainerFrameForKeyboardFrame:(CGRect)keyboardFrame {
    CGFloat offset = (CGRectGetMaxY([self textAbsFrame]) - CGRectGetMinY(keyboardFrame));
    CGRect targetFrame = self.page.frame;
    targetFrame.origin.y -= offset;
    targetFrame.origin.y = targetFrame.origin.y > _pageOriginFrame.origin.y ? _pageOriginFrame.origin.y : targetFrame.origin.y;
    CGFloat heigthOffset = self.frame.size.height - _originFrameHeight;
    targetFrame.size.height = (heigthOffset > 0 ? heigthOffset : 0) + _pageOriginFrame.size.height;
    self.page.frame = targetFrame;
}

- (CGFloat)getTextHeightWithCursor:(NSInteger)cursor
{
    cursor = MIN(MAX(0, cursor), self.text.length);
    
    UITextView *view = [[UITextView alloc] init];
    [self updatePaddingFor: view disableDefaultPadding: _model.disableDefaultPadding];
    view.font = self.font;
    view.attributedText = self.attributedText;
    view.text = [self.text substringToIndex:cursor];
    return [view sizeThatFits:CGSizeMake(self.model.style.width, MAXFLOAT)].height;
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
        if ([BDPKeyboardManager sharedManager].isKeyboardShow) {
            [self adjustPageContainerFrameForKeyboardFrame:[BDPKeyboardManager sharedManager].keyboardFrame duration:KEYBOARD_ADJUST_DURATION options:UIViewAnimationOptionCurveEaseInOut];
        }
    }
}

- (void)fixAppPageFrameWhenResignFirstResponder
{
    // Trick Code 解决部分系统半嗯的键盘无WillHide, willChange通知回调
    BOOL isNeedFixAppPageFrame = [self fixAppPageFrameSystemVersion];
    if (self.model.adjustPosition && isNeedFixAppPageFrame) {
        [self resetPageContainerFrameWithAnimationDuration:KEYBOARD_ADJUST_DURATION options:UIViewAnimationOptionCurveEaseInOut];
    }
}

#pragma mark - Variables Getters & Setters
/*-----------------------------------------------*/
//     Variables Getters & Setters - 变量相关
/*-----------------------------------------------*/

- (CGRect)textAbsFrame {
    CGRect textFrameInWindow = [self.superview convertRect:self.frame toView:nil];

    // 弹起键盘时根据文本实际高度进行高度计算，而并非以整个输入框高度计算弹起高度
    CGFloat height = [self getTextHeightWithCursor:self.selectedRange.location+self.selectedRange.length+1];
    CGFloat maxHeight = self.model.autoSize ? self.model.style.maxHeight : self.frame.size.height;
    textFrameInWindow.size.height = [TMACustomHelper adjustHeight:height maxHeight:maxHeight minHeight:0] + self.model.style.marginBottom;
    return textFrameInWindow;
}

- (BOOL)checkScrollEnabled:(CGFloat)height maxHeight:(CGFloat)maxHeight
{
    // 重新适配autoSize
    if (maxHeight && height > maxHeight) {
        return YES;
    } else {
        return (!self.model.autoSize);
    }
}

#pragma mark - Update
/*-----------------------------------------------*/
//               Update - 状态更新
/*-----------------------------------------------*/
- (void)updateText:(BDPTextAreaModel *)model
{
    NSString *value = model.value;
    if (model.maxLength && model.value.length > model.maxLength) {
        value = [value substringToIndex:model.maxLength];
    }
    self.text = value;
}

- (void)updateAttributedText:(BDPTextAreaModel *)model
{
    if (model.style) {
        // 段落样式
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.lineSpacing = model.style.lineSpace; // 行间距
        paragraphStyle.alignment = self.textAlignment; // 字对齐
        
        // 设置富文本样式来支持行距等参数
        NSMutableDictionary *textAttribute = [[NSMutableDictionary alloc] initWithCapacity:4];
        [textAttribute setValue:self.font forKey:NSFontAttributeName];
        [textAttribute setValue:self.textColor forKey:NSForegroundColorAttributeName];
        [textAttribute setValue:paragraphStyle forKey:NSParagraphStyleAttributeName];
        
        // 2019.12.4 - Fix: TextArea 组件在 [updateWithDictionary:] 触发 style 更新时导致选中高亮部分消失
        NSString *lang = [[self textInputMode] primaryLanguage];
        if ([lang isEqualToString:@"zh-Hans"]) {
            UITextRange *selectedRange = [self markedTextRange];
            UITextPosition *position = [self positionFromPosition:selectedRange.start offset:0];
            if (!position) {
                if (self.attributeChangeFix) {
                    [self.textStorage setAttributes:[textAttribute copy] range:NSMakeRange(0, self.text.length)];
                } else {
                // 2019.11.17 - Fix:TextArea 组件在 [setAttributedText:] 后可能导致输入光标跑到文字末尾
                NSUInteger location = self.selectedRange.location;
                self.attributedText = [[NSAttributedString alloc] initWithString:self.text attributes:[textAttribute copy]];
                [self setSelectedRange:NSMakeRange(location, 0)];
                }
            }
        }
        
        // PlaceHolder行距
        NSMutableDictionary *placeHolderAttribute = [[NSMutableDictionary alloc] initWithCapacity:4];
        [placeHolderAttribute setValue:self.placeHolderTextView.font forKey:NSFontAttributeName];
        [placeHolderAttribute setValue:self.placeHolderTextView.textColor forKey:NSForegroundColorAttributeName];
        [placeHolderAttribute setValue:paragraphStyle forKey:NSParagraphStyleAttributeName];
        self.placeHolderTextView.attributedText = [[NSAttributedString alloc] initWithString:self.placeHolderTextView.text attributes:placeHolderAttribute];
    }
}

- (void)updatePlaceHolder:(BDPTextAreaModel *)model
{
    // Setup PlaceHolder
    if (!self.placeHolderTextView) {
        UITextView * placeHolderTextView = [[UITextView alloc] initWithFrame:self.bounds];
        placeHolderTextView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        placeHolderTextView.backgroundColor = [UIColor clearColor];
        placeHolderTextView.userInteractionEnabled = NO;
        placeHolderTextView.editable = NO;
        placeHolderTextView.hidden = model.hidden;
        placeHolderTextView.font = [model.placeholderStyle font];
        placeHolderTextView.text = model.placeholder;
        placeHolderTextView.textColor = [UIColor colorWithHexString:model.placeholderStyle.color];
        placeHolderTextView.textAlignment = self.textAlignment;
        [self updatePaddingFor: placeHolderTextView disableDefaultPadding: model.disableDefaultPadding];
        [self addSubview:placeHolderTextView];
        self.placeHolderTextView = placeHolderTextView;
        return;
    }
    
    // Update PlaceHolder
    self.placeHolderTextView.font = [model.placeholderStyle font];
    self.placeHolderTextView.text = model.placeholder;
    self.placeHolderTextView.textColor = [UIColor colorWithHexString:model.placeholderStyle.color];
    self.placeHolderTextView.textAlignment = self.textAlignment;
    self.placeHolderTextView.hidden = model.hidden;
}

- (void)updateCursorAndSelection:(BDPTextAreaModel *)model
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
            [self setSelectedRange:range];
        });
    }
}

- (void)updateAutoSizeHeight {
    [self updateHeightForAutoSize:self.model];
}

- (void)updateHeightForAutoSize:(BDPTextAreaModel *)model
{
    // 此方法计算的高度值为文本实际高度并告知JSSDK，该高度不受控件高度的限制
    UITextView *view = self.text.length ? self : self.placeHolderTextView;
    CGFloat maxHeight = model.style.maxHeight;
    CGFloat minHeight = model.style.minHeight;
    CGFloat height = [view sizeThatFits:CGSizeMake(self.frame.size.width, MAXFLOAT)].height;
    
    // 文本高度超过最大高度时支持，需支持滑动
    self.scrollEnabled = [self checkScrollEnabled:height maxHeight:maxHeight];
    
    if (model.autoSize) {
        CGRect originFrame = self.frame;
        CGFloat textHeight = [TMACustomHelper adjustHeight:height maxHeight:maxHeight minHeight:minHeight];
        self.frame = CGRectMake(originFrame.origin.x, originFrame.origin.y, originFrame.size.width, textHeight);
    }
    
    // 高度发生变化时
    if (_textHeight != height) {
        _textHeight = height;
        [self adjustPageFrameForHeightChange];
        // 计算行数及高度，并告知JSSDK
        CGFloat lineSpace = model.style.lineSpace;
        CGFloat contentSize = height + lineSpace;
        CGFloat lineHeight = self.font.lineHeight + lineSpace;
        NSInteger lineCount = (NSInteger)(contentSize / lineHeight);
        [self fireEventToWebView:@"onTextAreaHeightChange"
                            data:@{@"inputId": BDPSafeString(self.componentID),
                                   @"lineCount": @(lineCount),
                                   @"height": @(height)}];
    }
}

/// 新逻辑下, 全量更新Model
- (void)updateWithNewModel:(BDPTextAreaModel * _Nonnull)model {
    if (model.hidden != self.model.hidden) {
        self.hidden = model.hidden;
    }
    
    if (model.autoSize != self.model.autoSize) {
        // 重新适配autoSize，文本高度超过最大高度时支持，需支持滑动
        UITextView *view = self.text.length ? self : self.placeHolderTextView;
        CGFloat maxHeight = self.model.style.maxHeight;
        CGFloat height = [view sizeThatFits:CGSizeMake(self.frame.size.width, MAXFLOAT)].height;
        self.scrollEnabled = [self checkScrollEnabled:height maxHeight:maxHeight];
    }
    
    [self updateText:model];
    [self updateAttributedText:model];
    [self updateHeightForAutoSize:model];
    
    self.placeHolderTextView.text = model.placeholder;
    
    if (model.placeholderStyle) {
        // Update PlaceHolder Style
        [self updatePlaceHolder:model];
        [self updateHeightForAutoSize:model];
    }
    
    if (model.style) {
        // Get Style Param
        
        // ⚠️该组件为同层渲染组件，SuperView 为 WKScrollView (WKWebView 解析网页生成的层级节点)
        // WKScrollView 的 [x, y] 为真实的 style.top, style.left
        // 因此该组件 View 相对于父 View 位置应设为 [0, 0]
        model.style.top = 0;
        model.style.left = 0;
        
        // Update Style
        if (model.style) {
            self.font = [model.style font];
            self.textAlignment = [model.style textAlignment];
            self.textColor = [UIColor colorWithHexString:model.style.color];
            self.backgroundColor = [UIColor colorWithHexString:model.style.backgroundColor];
            if (!CGRectIsNull(model.style.frame)) {
                if (model.autoSize) {
                    self.bdp_top = model.style.top;
                    self.bdp_left = model.style.left;
                } else {
                    self.frame = model.style.frame;
                }
                self.placeHolderTextView.frame = self.bounds;
            }
            
            [self updateAttributedText:model];
            [self updateHeightForAutoSize:model];
        }
    }

    if (model.showConfirmBar != self.model.showConfirmBar) {
        model.showConfirmBar ? [self addConfirmBar] : [self removeConfirmBar];
    }

    // 更新padding
    if (model.disableDefaultPadding != self.model.disableDefaultPadding) {
        [self updatePaddingFor: self disableDefaultPadding: model.disableDefaultPadding] ;
        if (self.placeHolderTextView) {
            [self updatePaddingFor: self.placeHolderTextView disableDefaultPadding: model.disableDefaultPadding];
        }
    }
    
    self.model = model;

    // Show or Hide PlaceHolder
    [self showOrHidePlaceHolderTextView];
    
}

- (void)updateWithDictionary:(NSDictionary * _Nullable)dict
{
    // Non-Null Dictionary
    if (BDPIsEmptyDictionary(dict)) {
        return;
    }
    
    // UpdateTextArea方法传输的参数为增量，有则更新，没有则不做处理。
    // 增量判断参数是否需要更新
    if ([dict valueForKey:@"disabled"]) {
        self.model.disabled = [dict bdp_boolValueForKey:@"disabled"];
    }
    
    if ([dict valueForKey:@"hidden"]) {
        self.model.hidden = [dict bdp_boolValueForKey:@"hidden"];
        self.hidden = self.model.hidden;
    }
    
    if ([dict valueForKey:@"autoSize"]) {
        self.model.autoSize = [dict bdp_boolValueForKey:@"autoSize"];
        
        // 重新适配autoSize，文本高度超过最大高度时支持，需支持滑动
        UITextView *view = self.text.length ? self : self.placeHolderTextView;
        CGFloat maxHeight = self.model.style.maxHeight;
        CGFloat height = [view sizeThatFits:CGSizeMake(self.frame.size.width, MAXFLOAT)].height;
        self.scrollEnabled = [self checkScrollEnabled:height maxHeight:maxHeight];
    }
    
    if ([dict valueForKey:@"confirm"]) {
        self.model.confirm = [dict bdp_boolValueForKey:@"confirm"];
    }
    
    if ([dict valueForKey:@"maxLength"]) {
        self.model.maxLength = [dict bdp_integerValueForKey:@"maxLength"];
    }
    
    if ([dict valueForKey:@"data"]) {
        self.model.data = [dict bdp_stringValueForKey:@"data"];
    }
    
    if ([dict valueForKey:@"value"]) {
        self.model.value = [dict bdp_stringValueForKey:@"value"];
        
        [self updateText:self.model];
        [self updateAttributedText:self.model];
        [self updateHeightForAutoSize:self.model];
    }
    
    if ([dict valueForKey:@"placeholder"]) {
        self.model.placeholder = [dict bdp_stringValueForKey:@"placeholder"];
        self.placeHolderTextView.text = self.model.placeholder;
        
        [self updateAttributedText:self.model];
        [self updateHeightForAutoSize:self.model];
    }
    
    // placeholderStyle参数是一个子类，如果传了placeholderStyle则内容一定为全量参数，直接全量使用即可
    if ([dict valueForKey:@"placeholderStyle"]) {
        // Get PlaceHolder Style Param
        NSDictionary *placeholderStyleDict = [dict bdp_dictionaryValueForKey:@"placeholderStyle"];
        [self.model.placeholderStyle updateWithDictionary:placeholderStyleDict];
        
        // Update PlaceHolder Style
        [self updatePlaceHolder:self.model];
        [self updateHeightForAutoSize:self.model];
    }
    
    // style参数是一个子类，如果传了style则内容一定为全量参数，直接全量使用即可
    if ([dict valueForKey:@"style"]) {
        // Get Style Param
        NSDictionary *styleDict = [dict bdp_dictionaryValueForKey:@"style"];
        [self.model.style updateWithDictionary:styleDict];
        
        // ⚠️该组件为同层渲染组件，SuperView 为 WKScrollView (WKWebView 解析网页生成的层级节点)
        // WKScrollView 的 [x, y] 为真实的 style.top, style.left
        // 因此该组件 View 相对于父 View 位置应设为 [0, 0]
        self.model.style.top = 0;
        self.model.style.left = 0;
        
        // Update Style
        if (self.model.style) {
            self.font = [self.model.style font];
            self.textAlignment = [self.model.style textAlignment];
            self.textColor = [UIColor colorWithHexString:self.model.style.color];
            self.backgroundColor = [UIColor colorWithHexString:self.model.style.backgroundColor];
            if (!CGRectIsNull(self.model.style.frame)) {
                if (self.model.autoSize) {
                    self.bdp_top = self.model.style.top;
                    self.bdp_left = self.model.style.left;
                } else {
                    self.frame = self.model.style.frame;
                }
                self.placeHolderTextView.frame = self.bounds;
            }
            
            [self updateAttributedText:self.model];
            [self updateHeightForAutoSize:self.model];
        }
    }

    if ([dict valueForKey:@("showConfirmBar")]) {
        self.model.showConfirmBar = [dict bdp_boolValueForKey:@"showConfirmBar"];
        self.model.showConfirmBar ? [self addConfirmBar] : [self removeConfirmBar];
    }

    // 更新padding
    if ([dict valueForKey:@"disableDefaultPadding"]) {
        self.model.disableDefaultPadding = [dict bdp_boolValueForKey:@"disableDefaultPadding"];
        [self updatePaddingFor: self disableDefaultPadding: _model.disableDefaultPadding] ;
        if (self.placeHolderTextView) {
            [self updatePaddingFor: self.placeHolderTextView disableDefaultPadding: _model.disableDefaultPadding];
        }
    }

    // Show or Hide PlaceHolder
    [self showOrHidePlaceHolderTextView];
}

#pragma mark - PlaceHolder
/*-----------------------------------------------*/
//         PlaceHolder - 空文本提示文字
/*-----------------------------------------------*/
- (void)showOrHidePlaceHolderTextView
{
    if (self.placeHolderTextView && !self.hidden) {
        self.placeHolderTextView.hidden = self.text.length > 0 ? YES : NO;
    }
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
    if (_engine) {
        // 新版Plugin灰度完成后，该engine要移除
        // Native Engine
        if (IsGadgetWebView(self.engine)) {
            BDPAppPage *appPage = (BDPAppPage *)self.engine;
            [appPage bdp_fireEvent:event sourceID:appPage.appPageID data:data];

        }
    } else {
        // 新版Plugin，不直接依赖engine
        if (_fireWebviewEventBlock) {
            _fireWebviewEventBlock(event, data);
        }
    }

}

- (void)fireEventToAppService:(NSString *)event data:(NSDictionary *)data
{
    if (_engine) {
        // 新版Plugin灰度完成后，该engine要移除
        // Native Engine
        if (IsGadgetWebView(self.engine)) {
            BDPAppPage *appPage = (BDPAppPage *)self.engine;
            [appPage publishEvent:event param:data];

        }
    } else {
        // 新版Plugin，不直接依赖engine
        if (_fireAppServiceEventBlock) {
            _fireAppServiceEventBlock(event, data);
        }
    }

}

- (void)updatePaddingFor:(UITextView *)textView disableDefaultPadding:(BOOL)disableDefaultPadding {
    textView.textContainer.lineFragmentPadding = disableDefaultPadding ? 0 : _originLinePadding;
    [textView setTextContainerInset: disableDefaultPadding ? UIEdgeInsetsZero : _originContainerInset];
}

@end
