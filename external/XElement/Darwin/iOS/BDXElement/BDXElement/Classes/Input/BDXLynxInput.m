//
//  BDXInput.m
//  AWECloudCommand
//
//  Created by shenweizheng on 2020/5/11.
//

#import <Foundation/Foundation.h>

#import "BDXLynxInput.h"
#import "BDXLynxTextView.h"
#import "BDXLynxTextKeyListener.h"
#import "BDXLynxNumberKeyListener.h"
#import "BDXLynxDialerKeyListener.h"
#import "BDXLynxDigitKeyListener.h"
#import "BDXLynxInputShadowNode.h"
#import <Lynx/LynxRootUI.h>
#import <Lynx/LynxComponentRegistry.h>
#import <Lynx/LynxPropsProcessor.h>
#import <Lynx/LynxUIMethodProcessor.h>
#import <Lynx/LynxColorUtils.h>
#import <Lynx/LynxUnitUtils.h>
#import <Lynx/LynxShadowNodeOwner.h>
#import <objc/message.h>
#import <Lynx/LynxUICollection.h>
#import <Lynx/LynxFontFaceManager.h>

// This is a regular expression that can match some common emojis. We also need to improve it to match all emoji.
static NSString* const EMOJI_PATTERN = @"[\\u2600-\\u27BF\\U0001F300-\\U0001F77F\\U0001F900-\\U0001F9FF]|[\\u2600-\\u27BF\\U0001F300-\\U0001F77F\\U0001F900–\\U0001F9FF]\\uFE0F|[\\u2600-\\u27BF\\U0001F300-\\U0001F77F\\U0001F900–\\U0001F9FF][\\U0001F3FB-\\U0001F3FF]|[\\U0001F1E6-\\U0001F1FF][\\U0001F1E6-\\U0001F1FF]";

@interface BDXLynxTextField : UITextField

@property(nonatomic, assign) UIEdgeInsets padding;
@property(atomic, readonly) BOOL waitingDictationRecognition;

@end

@implementation BDXLynxTextField

static void BDXLynxInputClassSwizzle(Class class, SEL originalSelector, SEL swizzledSelector) {
  Method originalMethod = class_getInstanceMethod(class, originalSelector);
  Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);

  BOOL didAddMethod =
      class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod),
                      method_getTypeEncoding(swizzledMethod));

  if (didAddMethod) {
    class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod),
                        method_getTypeEncoding(originalMethod));
  } else {
    method_exchangeImplementations(originalMethod, swizzledMethod);
  }
}

#if LYNX_LAZY_LOAD
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
LYNX_LOAD_LAZY(
   BDXLynxInputClassSwizzle([self class], @selector(scrollTextFieldToVisibleIfNecessary),
                @selector(BDXLynxInput_scrollTextFieldToVisibleIfNecessary));
)

#pragma clang diagnostic pop
#endif

/* 1. [UITextField scrollTextFieldToVisibleIfNecessary] method which in turn calls [UIScrollView scrollRectToVisible] when [UITextField becomeFirstResponder] is called.
 * 2. when click gesture is recognized and UITextField is still the first responder.
 * We've used [onWillShowKeyboardChanged] to control what happens when the UITextField is covered by keyboard. So we don't need it.
 */
- (void)BDXLynxInput_scrollTextFieldToVisibleIfNecessary {
    return;
}

- (UIEditingInteractionConfiguration)editingInteractionConfiguration API_AVAILABLE(ios(13.0)){
    return UIEditingInteractionConfigurationNone;
}

- (void)setPadding:(UIEdgeInsets)padding
{
    if (UIEdgeInsetsEqualToEdgeInsets(_padding, padding)) {
        return;
    }
    
    _padding = padding;
    [self setNeedsLayout];
}

#pragma mark - override
- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    // disbale delete to fix an iOS potential crash: `[UnSelector]-[BDXLynxTextField delete:]
    if (sel_isEqual(action, @selector(delete:))) {
        return NO;
    }
    return [super canPerformAction:action withSender:sender];
}

- (CGRect)textRectForBounds:(CGRect)bounds
{
    // Extract borders & padding
    CGFloat x = self.padding.left;
    CGFloat y = self.padding.top;
    CGFloat width = bounds.size.width -self.padding.left - self.padding.right;
    CGFloat height = bounds.size.height -self.padding.top - self.padding.bottom;
    
    return CGRectMake(x, y, width, height);
}

- (CGRect)editingRectForBounds:(CGRect)bounds
{
    return [self textRectForBounds:bounds];
}

-(id)insertDictationResultPlaceholder {
    _waitingDictationRecognition = YES;
    return [super insertDictationResultPlaceholder];
}

- (void)removeDictationResultPlaceholder:(id)placeholder willInsertResult:(BOOL)willInsertResult {
    [super removeDictationResultPlaceholder:placeholder willInsertResult:willInsertResult];
    _waitingDictationRecognition = NO;
}

@end

@interface BDXLynxInput() <UITextFieldDelegate, LynxFontFaceObserver>

@property (nonatomic) NSMutableDictionary *placeholderAttributes;
@property (nonatomic) NSString* placeHolderValue;
@property (nonatomic) BOOL autoHideKeyboard;
@property (nonatomic) BOOL smartScroll;
@property (nonatomic, readonly) BOOL firstScreenLayoutDidFinished;
@property (nonatomic, readonly) BOOL shouldFocusAfterLayout;

@end

static NSInteger const kBDXInputDefaultMaxLength = 140;
// A tag to mark input
static NSInteger inputTag = 10001;

@implementation BDXLynxInput {
    CGFloat _bottomInsetAddedOnScrollView;
}

#if LYNX_LAZY_LOAD
LYNX_LAZY_REGISTER_UI("input")
#else
LYNX_REGISTER_UI("input")
#endif

- (instancetype)init {
    self = [super init];
    if (self) {
        _maxLength = kBDXInputDefaultMaxLength;
        _readonly = NO;
        _placeholderAttributes = [NSMutableDictionary new];
        _placeHolderValue = nil;
        _autoHideKeyboard = YES;
        _smartScroll = YES;
        _mIsChangeFromLynx = NO;
        _mFilterPattern = @"";
        _mAdjustMode = @"end";
        _mAutoFit = YES;
        _mBottomInset = 0;
        _mKeyboardHeight = 0;
        _mInputType = TYPE_CLASS_TEXT;
        _mKeyListener = [[BDXLynxTextKeyListener alloc] init];
        _mLetterSpacing = 0;
        _mFontSize = 14;
        _mFontWeight = UIFontWeightRegular;
        _mPlaceholderFontSize = 14;
        _mPlaceholderFontWeight = UIFontWeightRegular;
        _mPlaceholderUseCustomFontSize = NO;
        _mPlaceholderUseCustomFontWeight = NO;
        _mCompatNumberType = NO;
        _firstScreenLayoutDidFinished = NO;
        _shouldFocusAfterLayout = NO;
        _mSendComposingInputEvent = NO;
        _mFontFamilyName = nil;
        _mPlaceholderUseCustomFontFamily = NO;
        _fontStyleChanged = NO;
        _placeholderFontStyleChanged = NO;
        _bottomInsetAddedOnScrollView = 0;
        _sourceLength = 0; // In order to separate the newly input string 'source' from the current string 'dest', we need to record the length of the new input content
        _mInputAccessoryView = nil;
    }
    
    // default font-size 14px
    CGFloat defaultFontSize = [LynxUnitUtils toPtFromUnitValue: @"14px"];
    [self.view setFont:[UIFont systemFontOfSize:defaultFontSize]];
    if (!self.placeholderAttributes[NSFontAttributeName])
        self.placeholderAttributes[NSFontAttributeName] = [UIFont systemFontOfSize:defaultFontSize weight:_mPlaceholderFontWeight];
    // default text-color black
    [self.view setTextColor:[UIColor blackColor]];
    
    return self;
}

- (UITextField*)createView
{
    UITextField* txtControl = [[BDXLynxTextField alloc] init];
    txtControl.clipsToBounds = YES;
    txtControl.delegate = self;
    txtControl.secureTextEntry = NO;
    
    [txtControl addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    
    NSNotificationCenter *notifCenter = [NSNotificationCenter defaultCenter];
    [notifCenter addObserver:self selector:@selector(onWillShowKeyboard:) name:UIKeyboardWillShowNotification object:nil];
    [notifCenter addObserver:self selector:@selector(onWillHideKeyboard:) name:UIKeyboardWillHideNotification object:nil];

    txtControl.tag = inputTag++;
    return txtControl;
}

#pragma mark - override
- (void)frameDidChange {
    [super frameDidChange];
    
    // Remove mask layer to adjust the input element in content area
    self.view.layer.mask = nil;
}

- (void)updateFrame:(CGRect)frame withPadding:(UIEdgeInsets)padding border:(UIEdgeInsets)border margin:(UIEdgeInsets)margin withLayoutAnimation:(BOOL)with {
  [super updateFrame:(CGRect)frame withPadding:(UIEdgeInsets)padding border:(UIEdgeInsets)border margin:(UIEdgeInsets)margin withLayoutAnimation:(BOOL)with];
  UIEdgeInsets textPadding = UIEdgeInsetsMake(padding.top +border.top, padding.left +border.left, padding.bottom +border.bottom, padding.right +border.right);
  [(BDXLynxTextField *)self.view setPadding:textPadding];
}

- (void)updateFrame:(CGRect)frame
        withPadding:(UIEdgeInsets)padding
             border:(UIEdgeInsets)border
withLayoutAnimation:(BOOL)with
{
    [super updateFrame:frame withPadding:padding border:border withLayoutAnimation:with];
    
    UIEdgeInsets textPadding = UIEdgeInsetsMake(padding.top +border.top, padding.left +border.left, padding.bottom +border.bottom, padding.right +border.right);
    [(BDXLynxTextField *)self.view setPadding:textPadding];
}

// The layoutDidFinished callback can ensure the context has been set.
-(void) layoutDidFinished {
    [super layoutDidFinished];
    
    _firstScreenLayoutDidFinished = YES;
    
    LynxShadowNodeOwner* owner = self.context.nodeOwner;
    if (owner != nil) {
        LynxShadowNode* node = [owner nodeWithSign:self.sign];
        if (node != nil && [node isKindOfClass:[BDXLynxInputShadowNode class]]) {
            BDXLynxInputShadowNode* n = (BDXLynxInputShadowNode*)node;
            n.textHeightFromUI = @(self.textHeight);
            n.fontFromUI = [self.view.font copy];
            if ([n needRelayout]) {
                [n setNeedRelayout:NO];
                [n setNeedsLayout];
            }
        }
    }
    
    if (_shouldFocusAfterLayout) {
        _shouldFocusAfterLayout = NO;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.view becomeFirstResponder];
        });
    }
}

- (void)propsDidUpdate {
    [super propsDidUpdate];
    
    // update text font
    if (_fontStyleChanged) {
        if (_mFontFamilyName == nil) {
            [self.view setFont:[UIFont systemFontOfSize:_mFontSize weight:_mFontWeight]];
        } else {
            [self setFont];
        }
        if (self.placeHolderValue) {
            // font will cover placeholder
            // see in https://developer.apple.com/documentation/uikit/uitextfield/1619604-font
            self.view.attributedPlaceholder = [[NSAttributedString alloc] initWithString:self.placeHolderValue attributes:self.placeholderAttributes];
        }
        _fontStyleChanged = NO;
    }
    
    // update placeholder font
    if (_placeholderFontStyleChanged && self.placeHolderValue) {
        if (_mPlaceholderFontFamilyName == nil) {
            self.placeholderAttributes[NSFontAttributeName] = [UIFont systemFontOfSize:_mPlaceholderFontSize weight:_mPlaceholderFontWeight];
        } else {
            [self setPlaceholderFont];
        }
        self.view.attributedPlaceholder = [[NSAttributedString alloc] initWithString:self.placeHolderValue attributes:self.placeholderAttributes];
        _placeholderFontStyleChanged = NO;
    }
}

#pragma mark - KEYBOARD

- (void)onWillShowKeyboard:(NSNotification *)notification
{
    [self onWillShowKeyboardChanged:YES notification:notification];
}

- (void)onWillHideKeyboard:(NSNotification *)notification
{
    [self onWillShowKeyboardChanged:NO notification:notification];
}

- (void)onWillShowKeyboardChanged:(BOOL)showKeyboard notification:(NSNotification *)notification
{
    if ((!self.view.isFirstResponder && showKeyboard) || !self.smartScroll || [self.mAdjustMode isEqualToString:@"none"])
        return;

    /* The following logic is to ensure the input control is always above keyboard's position:
     * 1. we adjust the coordinates' origin to scrollview's
     * 2. check whether the bottom of the input is below the top of the keyboard
     *    if yes, then adjust the scroll offset; otherwise, keep it asis.
     */
    UIView *superView = self.view.superview;
    while (superView && ![superView isKindOfClass:UIScrollView.class] && ![superView isEqual:self.context.rootView]) {
        superView = superView.superview;
    }
    
    if ([superView isKindOfClass:UIScrollView.class]) {
        NSDictionary *userInfo = notification.userInfo;
        // TODO should make a inputUtil for same codes in input and textarea
        /*
         * iOS9-iOS15. Be careful!
             [UIWindow
                [UITextEffectsWindow
                    [UIInputSetContainerView
                        [UIInputSetHostView]]]]
             and
             [UIRemoteKeyboardWindow
                [UIInputSetContainerView
                    [UIInputSetHostView]]]
             both exist.
         * Then, when the UIWindow is portrait and the child uiController is landscape, onWillShowKeyboard will get the width and height of UIInputSetHostView in UIWindow.
         * Then, the originKeyboardRect should be updated to the rect of UIInputSetHostView of UIRemoteKeyboardWindow.
         *
         * Above iOS16, Reminder!
         * UIRemoteKeyboardWindow has been renamed to UITextEffectsWindow and UIWindow no longer has its own UITextEffectsWindow.
         * But there is still a situation where UIWindow and uiController have different orientation.
         * So we still use the private API to find UITextEffectsWindow and use it as the base coordinate system.
         */
        CGRect originKeyboardRect = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
        UIScrollView *scrollView = (UIScrollView *)superView;
        
        if (showKeyboard) {
            // Get the KeyboardWindow
            UIWindow *keyboardWindow = self.view.window;
            int systemVersion = [[UIDevice currentDevice] systemVersion].intValue;
            for (UIWindow *window in [[UIApplication sharedApplication] windows])
            {
                NSString *windowName = NSStringFromClass(window.class);
                if (systemVersion < 9 || systemVersion >= 16) {
                    // UITextEffectsWindow
                    if (windowName.length != 19) continue;
                    if (![windowName hasPrefix:@"UI"]) continue;
                    if (![windowName hasSuffix:@"TextEffectsWindow"]) continue;
                } else {
                    // UIRemoteKeyboardWindow
                    if (windowName.length != 22) continue;
                    if (![windowName hasPrefix:@"UI"]) continue;
                    if (![windowName hasSuffix:@"RemoteKeyboardWindow"]) continue;
                }
                keyboardWindow = window;
                break;
            }
            // Get the KeyboardView
            UIView *keyboardView = nil;
            if (systemVersion < 8) {
                // UIPeripheralHostView
                for (UIView *view in [keyboardWindow subviews]) {
                    NSString *viewName = NSStringFromClass(view.class);
                    if (viewName.length != 20) continue;
                    if (![viewName hasPrefix:@"UI"]) continue;
                    if (![viewName hasSuffix:@"PeripheralHostView"]) continue;
                    keyboardView = view;
                    break;
                }
            } else {
                // UIInputSetContainerView
                for (UIView *view in [keyboardWindow subviews]) {
                    NSString *viewName = NSStringFromClass(view.class);
                    if (viewName.length != 23) continue;
                    if (![viewName hasPrefix:@"UI"]) continue;
                    if (![viewName hasSuffix:@"InputSetContainerView"]) continue;
                    for (UIView *subView in [view subviews]) {
                        // UIInputSetHostView
                        NSString *subViewName = NSStringFromClass(subView.class);
                        if (subViewName.length != 18) continue;
                        if (![subViewName hasPrefix:@"UI"]) continue;
                        if (![subViewName hasSuffix:@"InputSetHostView"]) continue;
                        keyboardView = subView;
                        originKeyboardRect = keyboardView.frame;
                        _mKeyboardHeight = keyboardView.frame.size.height;
                        break;
                    }
                    break;
                }
            }
            if (keyboardView == nil) {
                return;
            }

            // Calculate the distance between the bottom of the input and the top of the keyboard
            CGRect screenRect = [[UIScreen mainScreen] bounds];
            // Convert all rects to the UIWindow
            CGRect scrollViewRectOnOriginWindow = [scrollView.superview convertRect:scrollView.frame toView:nil];
            CGRect inputRectOnOriginWindow = [self.view.superview convertRect:self.view.frame toView:nil];
            LynxRootUI *rootUI = [[self context] rootUI];
            LynxView *lynxView = nil;
            if (rootUI != nil) {
                lynxView = rootUI.lynxView;
            }
            CGRect LynxViewRectOnOriginWindow = [lynxView convertRect:lynxView.frame toView:nil];
            // Convert the rect based on the UIWindow to the KeyboardWindow
            CGRect scrollViewRectOnKeyboardWindow = [scrollView.window convertRect:scrollViewRectOnOriginWindow toWindow:keyboardWindow];
            CGRect inputRectInScrollViewOnKeyboardWindow = [self.view.window convertRect:inputRectOnOriginWindow toWindow:keyboardWindow];
            CGRect LynxViewRectOnKeyboardWindow = [lynxView.window convertRect:LynxViewRectOnOriginWindow toWindow:keyboardWindow];
            CGFloat inputBottomOnKeyboardWindow = inputRectInScrollViewOnKeyboardWindow.origin.y + inputRectInScrollViewOnKeyboardWindow.size.height;
            // at the end of the right swipe exit gesture, the y sent by onWillShowKeyboard is screenRect.bottom
            CGFloat keyboardViewRealY = screenRect.size.height - keyboardView.frame.size.height;
            
            CGFloat diff = keyboardViewRealY - inputBottomOnKeyboardWindow;
            CGFloat displayHeight = screenRect.size.height - scrollViewRectOnKeyboardWindow.origin.y - _mKeyboardHeight;
            
            CGFloat extraHeight = 0;
            if ([self.mAdjustMode isEqualToString:@"center"]) {
                diff -= (displayHeight - inputRectInScrollViewOnKeyboardWindow.size.height) / 2;
                extraHeight = (displayHeight - inputRectInScrollViewOnKeyboardWindow.size.height) / 2;
            } else if ([self.mAdjustMode isEqualToString:@"end"]) {
                diff -= self.mBottomInset;
                extraHeight = _mBottomInset;
            }
            
            // ui above keyboard
            if (diff >= 0 ) {
                return;
            }
            
            /* Only add (_mKeyboardHeight + extraHeight - remainingDistance) to paddingBottom in iOS.
             * Because UIScrollView.contentInset will change contentOffset, so we can't make an independent contentOffset when contentInset make a delay animation to contentOffset.
             * We need a padding that just puts the input above the keyboard and allows the ScrollView to continue scrolling to the end.
             * assume height: inputView <= scrollView <= lynxView <= screen
             | |---------LynxView-----------| |
             | | |-------ScrollView-------| | |
             | | |                        | | |
             | | | |------------------|   | | |
             | | | |        input     |   | | |
             |------------Keyboard------------|
             | | | |                  |   | | |diff
             | | | |------------------|   | | |
             | | |                        | | |remainingScrollDistance
             | | |                        | | |
             | | |-------ScrollView---------| |
             | |                            | |offsetScrollViewAndLynxView
             | |                            | |
             | |---------LynxView-----------| |
             |                                |offsetLynxViewAndScreen
             |                                |
             |------------Screen--------------|
             */
            CGFloat bottomInset = 0;
            CGRect inputRectInScrollView = [self.view.superview convertRect:self.view.frame toView:scrollView];
            CGFloat inputBottomInScrollView = scrollView.frame.origin.y + inputRectInScrollView.origin.y + inputRectInScrollView.size.height;
            CGFloat remainingScrollDistance = scrollView.contentSize.height - inputBottomInScrollView;
            CGFloat offsetScrollViewAndLynxView = LynxViewRectOnKeyboardWindow.origin.y + LynxViewRectOnKeyboardWindow.size.height - scrollViewRectOnKeyboardWindow.origin.y - scrollViewRectOnKeyboardWindow.size.height;
            CGFloat offsetLynxViewAndScreen = screenRect.origin.y + screenRect.size.height - LynxViewRectOnKeyboardWindow.origin.y - LynxViewRectOnKeyboardWindow.size.height;
            CGFloat remainingDistance = remainingScrollDistance + offsetLynxViewAndScreen + offsetScrollViewAndLynxView;
            if (_mKeyboardHeight + extraHeight <= remainingDistance) {
                bottomInset = 0;
            } else {
                bottomInset = _mKeyboardHeight + extraHeight - remainingDistance;
            }
            
            // be consistent with the effect of Android Resize, just scrollToEnd
            if (!self.mAutoFit) {
                CGFloat remainingScrollDistance = scrollView.contentSize.height - scrollView.bounds.size.height - scrollView.contentInset.bottom - scrollView.contentOffset.y;
                if (-diff > remainingScrollDistance + self.mKeyboardHeight) {
                    diff = -(remainingScrollDistance + self.mKeyboardHeight);
                }
            }
            [self updateScrollView:scrollView showKeyboard:YES diff:diff bottomInset:bottomInset userInfo:notification.userInfo];
        } else if (!showKeyboard) {
            // Unlike Android, iOS ScrollView allows you to set any Offset value.
            // So when the keyboard hide, we need to reset the offset beyond the ScrollRange.
            CGFloat legalScrollRange = scrollView.contentSize.height - scrollView.frame.size.height;
            CGFloat diff = 0;
            if (scrollView.contentOffset.y > legalScrollRange) {
                diff = legalScrollRange - scrollView.contentOffset.y;
            }
            [self updateScrollView:scrollView showKeyboard:NO diff:diff bottomInset:0 userInfo:notification.userInfo];
        }
    }
}

- (void)updateScrollView:(UIScrollView *)scrollView showKeyboard:(BOOL)showKeyboard
                    diff:(CGFloat)diff bottomInset:(CGFloat)bottomInset userInfo:(NSDictionary *)userInfo
{
    if (showKeyboard) {
        UIEdgeInsets insets = scrollView.contentInset;
        CGPoint scrollOffset = [scrollView contentOffset];
        scrollOffset.y += -diff;
        insets.bottom = bottomInset;
        _bottomInsetAddedOnScrollView = bottomInset;
        
        /* usually, setContentInset post setContentOffset, so this just does for no-autoFit
         * But if the setContentInset at the end of the right swipe exit gesture, it will not do so
         */
        scrollView.contentInset = insets;
        scrollView.contentOffset = scrollOffset;
    } else {
        CGPoint scrollOffset = [scrollView contentOffset];
        UIEdgeInsets insets = scrollView.contentInset;
        CGFloat y = scrollOffset.y + diff - _bottomInsetAddedOnScrollView;
        scrollOffset.y =  y > 0 ? y : 0;
        insets.bottom = 0;
        _bottomInsetAddedOnScrollView = 0;

        scrollView.contentInset = insets;
        scrollView.contentOffset = scrollOffset;
    }
}

#pragma mark - LYNX_PROP_SETTER

LYNX_UI_METHOD(setInputFilter) {
    if ([[params allKeys] containsObject:@"pattern"]) {
        self.mFilterPattern = [params objectForKey:@"pattern"];
    }
    // else keep it as @""
}

LYNX_UI_METHOD(setValue) {
    if (![params isKindOfClass:[NSDictionary class]]) {
        callback(kUIMethodParamInvalid, @"Param is not a map.");
        return;
    }
    
    NSArray* keys = [params allKeys];
    NSString* value = @"";
    NSNumber* index = NULL;
    if ([keys containsObject:@"value"]) {
        value = [params objectForKey:@"value"];
    }
    if ([keys containsObject:@"index"]) {
        index = [params objectForKey:@"index"];
    }
    [self setValue:value index:index callback:callback];
}

LYNX_PROP_SETTER("value", setTextValue, NSString*) {
    if (requestReset) {
        value = @"";
    }
    
    if ([self.view.text isEqualToString:value]) {
        return;
    }

    [self setValue:value index:NULL callback:NULL];
}

- (void)setValue:(NSString *)value index:(nullable NSNumber*)index callback:(nullable LynxUIMethodCallbackBlock) callback{
    self.mIsChangeFromLynx = YES;
    [self.view setText:value];
    _sourceLength = value.length;

    UITextPosition* beginning = self.view.beginningOfDocument;
    UITextPosition* newCursorPosition;
    
    // UITextField::setText won't move cursor to endOfDocument
    // We move the cursor to the end to make sure we can separate the source and dest strings
    newCursorPosition = [self.view positionFromPosition:beginning offset:self.view.text.length];
    self.view.selectedTextRange = [self.view textRangeFromPosition:newCursorPosition toPosition:newCursorPosition];
    [self textFieldDidChange:(BDXLynxTextField*)self.view];
    
    if (index != NULL) {
        NSInteger intIndex = [index intValue];
        if (intIndex >= 0 && intIndex <= self.view.text.length) {
            newCursorPosition = [self.view positionFromPosition:beginning offset:intIndex];
            self.view.selectedTextRange = [self.view textRangeFromPosition:newCursorPosition toPosition:newCursorPosition];
        }
    }
    
    if (callback != NULL) {
        callback(kUIMethodSuccess, @"Success.");
    }
}

LYNX_PROP_SETTER("show-soft-input-onfocus", setShowSoftInputOnFocus, BOOL) {
    if (requestReset) {
        value = YES;
    }
    
    if (value) {
        self.view.inputView = nil;
        self.view.inputAccessoryView = _mInputAccessoryView;
    } else {
        UIView* dummyView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
        self.view.inputView = dummyView;
        self.view.inputAccessoryView = dummyView;
    }
}

LYNX_UI_METHOD(addText) {
    NSString* value = [params objectForKey:@"text"];
    
    if (self.view.isFirstResponder) {
        UITextPosition* beginning = self.view.beginningOfDocument;
        UITextRange* selectedRange = self.view.selectedTextRange;
        NSInteger start = [self.view offsetFromPosition:beginning toPosition:selectedRange.start];
        NSInteger end = [self.view offsetFromPosition:beginning toPosition:selectedRange.end];
        NSString* content = self.view.text;
        NSString* newContent = [NSString stringWithFormat:@"%@%@%@",
                                [content substringToIndex:start],
                                value,
                                [content substringFromIndex:end]];
        self.view.text = newContent;

        // set new cursor postion
        NSInteger newOffset = start + value.length;
        UITextPosition* newCursorPosition = [self.view positionFromPosition:beginning offset:newOffset];
        self.view.selectedTextRange = [self.view textRangeFromPosition:newCursorPosition toPosition:newCursorPosition];
    } else {
        NSString* newContent = [NSString stringWithFormat:@"%@%@",
                                self.view.text, value];
        self.view.text = newContent;
    }
    
    _sourceLength = value.length;
    [self textFieldDidChange:(BDXLynxTextField *)self.view];
}

LYNX_UI_METHOD(sendDelEvent) {
    NSInteger action = NO;
    if ([[params allKeys] containsObject:@"action"]) {
        action = [[params objectForKey:@"action"] intValue];
        switch (action) {
            case 0:
            {
                NSInteger length = NO;
                 if (![[params allKeys] containsObject:@"length"]) {
                    return;
                } else {
                    length = [[params objectForKey:@"length"] intValue];
                }
                
                if (self.view.isFirstResponder) {
                    UITextPosition* beginning = self.view.beginningOfDocument;
                    UITextRange* selectedRange = self.view.selectedTextRange;
                    NSInteger start = [self.view offsetFromPosition:beginning toPosition:selectedRange.start];
                    NSInteger newStart = (start - length >= 0) ? start - length : 0;
                    NSString* content = self.view.text;
                    NSString* newContent = [NSString stringWithFormat:@"%@%@",
                                            [content substringToIndex:newStart],
                                            [content substringFromIndex:start]];
                    _sourceLength = length;
                    self.view.text = newContent;

                    // set new cursor postion
                    UITextPosition* newCursorPosition = [self.view positionFromPosition:beginning offset:newStart];
                    self.view.selectedTextRange = [self.view textRangeFromPosition:newCursorPosition toPosition:newCursorPosition];
                } else {
                    for (int i = 0; i < length - 1; i++) {
                        _mIsChangeFromLynx = YES;
                        [self.view deleteBackward];
                    }
                }
                
                [self textFieldDidChange:(BDXLynxTextField *)self.view];
                break;
            }
            case 1:
                [self.view deleteBackward];
                break;
            default:
                break;
        }
    }
}

LYNX_PROP_SETTER("type", setType, NSString*) {
    if (requestReset) {
        value = @"text";
    }
    
    if ([value isEqualToString:@"text"]) {
        [self.view setKeyboardType:UIKeyboardTypeDefault];
        self.mInputType = TYPE_CLASS_TEXT;
        self.mKeyListener = [[BDXLynxTextKeyListener alloc] init];
    } else if ([value isEqualToString:@"number"]) {
        [self.view setKeyboardType:UIKeyboardTypeNumberPad];
        self.mInputType = TYPE_CLASS_NUMBER;
        if (_mCompatNumberType) {
            _mKeyListener = [[BDXLynxDigitKeyListener alloc] initWithParamsNeedsDecimal:NO sign:NO];
        } else {
            _mKeyListener = [[BDXLynxDigitKeyListener alloc] initWithParamsNeedsDecimal:YES sign:YES];
        }
    } else if ([value isEqualToString:@"digit"]) {
        [self.view setKeyboardType:UIKeyboardTypeDecimalPad];
        self.mInputType = TYPE_NUMBER_FLAG_DECIMAL;
        self.mKeyListener = [[BDXLynxDigitKeyListener alloc] initWithParamsNeedsDecimal:YES sign:NO];
    } else if ([value isEqualToString:@"tel"]) {
        [self.view setKeyboardType:UIKeyboardTypePhonePad];
        self.mInputType = TYPE_CLASS_PHONE;
        self.mKeyListener = [[BDXLynxDialerKeyListener alloc] init];
    } else if ([value isEqualToString:@"email"]) {
        [self.view setKeyboardType:UIKeyboardTypeEmailAddress];
        self.mInputType = TYPE_CLASS_TEXT;
        self.mKeyListener = [[BDXLynxTextKeyListener alloc] init];
    }
    if ([value isEqualToString:@"password"]) {
        [self.view setSecureTextEntry:YES];
        self.mInputType = TYPE_CLASS_TEXT;
        self.mKeyListener = [[BDXLynxTextKeyListener alloc] init];
    } else {
        [self.view setSecureTextEntry:NO];
    }

    // performance in the Android system is filtered once after the type is defined
    if (![self.view.text isEqualToString:@""]) {
        // TODO After the content has passed any filter, the filter result should be notified to the front end
        self.mIsChangeFromLynx = YES;
        [self textFieldDidChange:(BDXLynxTextField *)self.view];
    }
}

LYNX_PROP_SETTER("password", setPassword, BOOL) {
    if (requestReset) {
        value = NO;
    }
    
    [self.view setSecureTextEntry:value];
}

LYNX_PROP_SETTER("text-align", setTextAlign, LynxTextAlignType) {
    if (requestReset) {
        value = LynxTextAlignLeft;
    }
    
    if (value == LynxTextAlignCenter) {
        [self.view setTextAlignment:NSTextAlignmentCenter];
    } else if (value == LynxTextAlignLeft) {
        [self.view setTextAlignment:NSTextAlignmentLeft];
    } else if (value == LynxTextAlignRight) {
        [self.view setTextAlignment:NSTextAlignmentRight];
    } else if (value == LynxTextAlignStart) {
        [self.view setTextAlignment:NSTextAlignmentNatural];
    }
}

LYNX_PROP_SETTER("placeholder", setPlaceHolder, NSString*) {
    if (requestReset) {
        value = @"";
    }
    
    if (!value) {
        self.view.attributedPlaceholder = nil;
        self.placeHolderValue = nil;
    } else {
        self.view.attributedPlaceholder = [[NSAttributedString alloc] initWithString:value attributes:self.placeholderAttributes];
        self.placeHolderValue = value;
    }
    _placeholderFontStyleChanged = YES;
}

LYNX_PROP_SETTER("disabled", setDisabled, BOOL) {
    if (requestReset) {
        value = NO;
    }
    
    [self.view setUserInteractionEnabled:!value];
}

LYNX_PROP_SETTER("maxlength", setMaxLen, int) {
    if (requestReset) {
        value = kBDXInputDefaultMaxLength;
    }
    
    self.maxLength = value;
}

LYNX_PROP_SETTER("readonly", setReadOnly, BOOL) {
    if (requestReset) {
        value = NO;
    }
    
    self.readonly = value;
}

LYNX_PROP_SETTER("color", setColor, UIColor*) {
    if (requestReset) {
        value = [UIColor blackColor];
    }
    
    [self.view setTextColor:value];
}

LYNX_PROP_SETTER("font-size", setFontSize, CGFloat) {
    // TODO should we need to support NSString and CGFloat here?
    if (requestReset) {
        _mFontSize = [LynxUnitUtils toPtFromUnitValue: @"14px"];
    } else {
        _mFontSize = value;
    }
    
    /* The font-size inside attributedPlaceholder will be overrode after calling setFont
     * Therefore, we have to syncPlaceholderFont everytime.
     */
    if (!_mPlaceholderUseCustomFontSize) {
        _mPlaceholderFontSize = _mFontSize;
        _placeholderFontStyleChanged = YES;
    }
    _fontStyleChanged = YES;
}

LYNX_PROP_SETTER("font-weight", setFontWeight, LynxFontWeightType) {
    if (requestReset) {
        _mFontWeight = UIFontWeightRegular;
    } else {
        _mFontWeight = [self convertFontWeightToUIFontWeight:value];
    }
    
    if (!_mPlaceholderUseCustomFontWeight) {
        _mPlaceholderFontWeight = _mFontWeight;
        _placeholderFontStyleChanged = YES;
    }
    _fontStyleChanged = YES;
}

LYNX_PROP_SETTER("font-family", setFontFamily, NSString*) {
    if (requestReset) {
        _mFontFamilyName = nil;
    } else {
        _mFontFamilyName = value;
    }
    
    if (!_mPlaceholderUseCustomFontFamily) {
        _mPlaceholderFontFamilyName = _mFontFamilyName;
        _placeholderFontStyleChanged = YES;
    }
    _fontStyleChanged = YES;
}

LYNX_PROP_SETTER("placeholder-color", setPlaceHolderColor, NSString*) {
    if (requestReset) {
        // [UIColor placeholderTextColor]
        self.placeholderAttributes[NSForegroundColorAttributeName] = [UIColor colorWithRed:0.235 green:0.263 blue:0.235 alpha:0.3];
    } else {
        self.placeholderAttributes[NSForegroundColorAttributeName] = [LynxColorUtils convertNSStringToUIColor: value];
    }
    _placeholderFontStyleChanged = YES;
}

LYNX_PROP_SETTER("placeholder-font-family", setPlaceHolderFamily, NSString*) {
    if (requestReset) {
        if (_mFontFamilyName != nil) {
            _mPlaceholderFontFamilyName = _mFontFamilyName;
        } else {
            _mPlaceholderFontFamilyName = nil;
        }
        _mPlaceholderUseCustomFontFamily = NO;
    } else {
        _mPlaceholderUseCustomFontFamily = YES;
        _mPlaceholderFontFamilyName = value;
    }
    _placeholderFontStyleChanged = YES;
}

LYNX_PROP_SETTER("placeholder-font-size", setPlaceHolderFont, NSString*) {
    if (requestReset) {
        _mPlaceholderFontSize = _mFontSize;
        _mPlaceholderUseCustomFontSize = NO;
    } else {
        _mPlaceholderFontSize = [LynxUnitUtils toPtFromUnitValue:value];
        _mPlaceholderUseCustomFontSize = YES;
    }
    _placeholderFontStyleChanged = YES;
}

LYNX_PROP_SETTER("placeholder-font-weight", setPlaceHolderWeight, NSString*) {
    if (requestReset) {
        _mPlaceholderFontWeight = _mFontWeight;
        _mPlaceholderUseCustomFontWeight = NO;
    } else {
        if ([value isEqual:@"normal"]   || [value isEqual:@"400"]) {
            _mPlaceholderFontWeight = UIFontWeightRegular;
        } else if ([value isEqual:@"bold"] || [value isEqual:@"700"]) {
            _mPlaceholderFontWeight = UIFontWeightBold;
        } else if ([value isEqual:@"100"]) {
            _mPlaceholderFontWeight = UIFontWeightUltraLight;
        } else if ([value isEqual:@"200"]) {
            _mPlaceholderFontWeight = UIFontWeightThin;
        } else if ([value isEqual:@"300"]) {
            _mPlaceholderFontWeight = UIFontWeightLight;
        } else if ([value isEqual:@"500"]) {
            _mPlaceholderFontWeight = UIFontWeightMedium;
        } else if ([value isEqual:@"600"]) {
            _mPlaceholderFontWeight = UIFontWeightSemibold;
        } else if ([value isEqual:@"800"]) {
            _mPlaceholderFontWeight = UIFontWeightHeavy;
        } else if ([value isEqual:@"900"]) {
            _mPlaceholderFontWeight = UIFontWeightBlack;
        }
        _mPlaceholderUseCustomFontWeight = YES;
    }
    _placeholderFontStyleChanged = YES;
}

LYNX_PROP_SETTER("placeholder-style", setPlaceHolderStyle, NSDictionary*) {
    if (![value isKindOfClass:[NSDictionary class]]) {
        return;
    }
    
    NSNumber* colorValue = value[@"color"];
    NSNumber* fontSize = value[@"font-size"];
    NSNumber* fontWeight = value[@"font-weight"];
    NSString* fontFamily = value[@"font-family"];
    if (colorValue) {
        int red, green, blue, alpha;
        
        NSInteger hex = [colorValue integerValue];
        if (hex) {
            blue = hex & 0x000000FF;
            green = ((hex & 0x0000FF00) >> 8);
            red = ((hex & 0x00FF0000) >> 16);
            alpha = ((hex & 0xFF000000) >> 24);
            self.placeholderAttributes[NSForegroundColorAttributeName] = [UIColor colorWithRed:red/255.0f
                                                                                         green:green/255.0f blue:blue/255.0f alpha:alpha/255.f];
        }
    }
    
    if (fontSize) {
        _mPlaceholderUseCustomFontSize = YES;
        _mPlaceholderFontSize = [fontSize floatValue];
    }
    
    if (fontWeight) {
        _mPlaceholderUseCustomFontWeight = YES;
        _mPlaceholderFontWeight = [self convertFontWeightToUIFontWeight:[fontWeight integerValue]];
    }
    
    if (fontFamily) {
        _mPlaceholderUseCustomFontFamily = YES;
        _mPlaceholderFontFamilyName = fontFamily;
    }
    
    _placeholderFontStyleChanged = YES;
}

- (CGFloat)convertFontWeightToUIFontWeight:(NSUInteger) value {
    CGFloat fontWeight = UIFontWeightRegular;
    if (value == LynxFontWeightNormal) {
        fontWeight = UIFontWeightRegular;
    } else if (value == LynxFontWeightBold) {
        fontWeight = UIFontWeightBold;
    } else if (value == LynxFontWeight100) {
        fontWeight = UIFontWeightUltraLight;
    } else if (value == LynxFontWeight200) {
        fontWeight = UIFontWeightThin;
    } else if (value == LynxFontWeight300) {
        fontWeight = UIFontWeightLight;
    } else if (value == LynxFontWeight400) {
        fontWeight = UIFontWeightRegular;
    } else if (value == LynxFontWeight500) {
        fontWeight = UIFontWeightMedium;
    } else if (value == LynxFontWeight600) {
        fontWeight = UIFontWeightSemibold;
    } else if (value == LynxFontWeight700) {
        fontWeight = UIFontWeightBold;
    } else if (value == LynxFontWeight800) {
        fontWeight = UIFontWeightHeavy;
    } else if (value == LynxFontWeight900) {
        fontWeight = UIFontWeightBlack;
    }
    
    return fontWeight;
}

LYNX_PROP_SETTER("focus", setFocus, BOOL) {
    if (requestReset) {
        value = NO;
    }
    
    if (value) {
        if (_firstScreenLayoutDidFinished) {
            [self.view becomeFirstResponder];
        } else {
            _shouldFocusAfterLayout = YES;
        }
    } else {
        [self.view resignFirstResponder];
    }
}

LYNX_PROP_SETTER("auto-hide-keyboard", setAutoHideKeyboard, BOOL) {
    if (requestReset) {
        value = YES;
    }
    
    self.autoHideKeyboard = value;
}

LYNX_PROP_SETTER("smart-scroll", setSmartScroll, BOOL) {
    if (requestReset) {
        value = YES;
    }
    
    self.smartScroll = value;
}

LYNX_PROP_SETTER("adjust-mode", setAdjustMode, NSString*) {
    if (requestReset) {
        value = @"end";
    }
    
    self.mAdjustMode = value;
}

LYNX_PROP_SETTER("auto-fit", setAutoFit, BOOL) {
    if (requestReset) {
        value = YES;
    }
    
    self.mAutoFit = value;
}

LYNX_PROP_SETTER("bottom-inset", setBottomInset, NSString*) {
    if (requestReset) {
        value = @"0px";
    }
    
    self.mBottomInset = [LynxUnitUtils toPtFromUnitValue: value];
}

LYNX_PROP_SETTER("caret-color", setCaretColor, NSString*) {
    if (requestReset) {
        value = @"blue";
    }
    
    [self.view setTintColor:[LynxColorUtils convertNSStringToUIColor:value]];
}

LYNX_PROP_SETTER("confirm-type", setConfirmType, NSString*) {
    if (requestReset) {
        value = @"done";
    }
    
    NSString *title = value.lowercaseString;
    UIReturnKeyType returnKeyType = UIReturnKeyDefault;
    if ([title isEqualToString:@"send"]) {
        returnKeyType = UIReturnKeySend;
    } else if ([title isEqualToString:@"search"]) {
        returnKeyType = UIReturnKeySearch;
    } else if ([title isEqualToString:@"next"]) {
        returnKeyType = UIReturnKeyNext;
    } else if ([title isEqualToString:@"go"]) {
        returnKeyType = UIReturnKeyGo;
    } else if ([title isEqualToString:@"done"]) {
        returnKeyType = UIReturnKeyDone;
    }
    self.view.returnKeyType = returnKeyType;
}

LYNX_UI_METHOD(resetSelectionMenu) {
  UIMenuController *theMenu = [UIMenuController sharedMenuController];
  if (theMenu.isMenuVisible && [self.view isFirstResponder]) {
    UITextRange* range = self.view.selectedTextRange;
    self.view.selectedTextRange = nil;
    [theMenu setMenuVisible:NO animated:YES];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 16 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
        self.view.selectedTextRange = range;
        CGRect startRect = [self.view caretRectForPosition:self.view.selectedTextRange.start];
        CGRect endRect = [self.view caretRectForPosition:self.view.selectedTextRange.end];
        CGRect rect = endRect;
        if (startRect.origin.y != endRect.origin.y) {
          rect = CGRectMake(self.view.frame.size.width/2.0, startRect.origin.y, startRect.size.width, startRect.size.height);
        } else {
          rect = CGRectMake((startRect.origin.x + endRect.origin.x)/2.0, startRect.origin.y, startRect.size.width, startRect.size.height);
        }
        [theMenu setTargetRect:rect inView:self.view];
        [theMenu setMenuVisible:YES animated:YES];
    });
  }
}

LYNX_PROP_SETTER("direction", setLynxDirection, LynxDirectionType) {
    if (requestReset) {
        value = LynxDirectionNormal;
    }
    
    self.directionType = value;
    [self setInputTextDirection];
}

LYNX_PROP_SETTER("letter-spacing", setLetterSpacing, CGFloat) {
    if (requestReset) {
        value = 0;
    }
    
    self.mLetterSpacing = value;
    
    self.placeholderAttributes[NSKernAttributeName] = @(value);
    if (self.placeHolderValue)
        self.view.attributedPlaceholder = [[NSAttributedString alloc] initWithString:self.placeHolderValue attributes:self.placeholderAttributes];
    
    [self textFieldDidChange:(BDXLynxTextField *)self.view];
}

LYNX_UI_METHOD(select) {
    UITextPosition* beginning = self.view.beginningOfDocument;
    UITextPosition* ending = self.view.endOfDocument;
    self.view.selectedTextRange = [self.view textRangeFromPosition:beginning toPosition:ending];
    callback(kUIMethodSuccess, @"Success.");
}

LYNX_UI_METHOD(setSelectionRange) {
    if (![params isKindOfClass:[NSDictionary class]]) {
        callback(kUIMethodParamInvalid, @"Param is not a map.");
        return;
    }
    
    NSInteger selectionStart = -1;
    NSInteger selectionEnd = -1;
    if ([[params allKeys] containsObject:@"selectionStart"]) {
        selectionStart = [[params objectForKey:@"selectionStart"] intValue];
    }
    if ([[params allKeys] containsObject:@"selectionEnd"]) {
        selectionEnd = [[params objectForKey:@"selectionEnd"] intValue];
    }
    
    NSInteger length = self.view.text.length;
    if (selectionStart > length || selectionEnd > length || selectionStart < 0 || selectionEnd < 0) {
        callback(kUIMethodParamInvalid, @"Range does not meet expectations.");
        return;
    }
    UITextPosition* beginning = self.view.beginningOfDocument;
    UITextPosition* start = [self.view positionFromPosition:beginning offset:selectionStart];
    UITextPosition* end = [self.view positionFromPosition:beginning offset:selectionEnd];
    self.view.selectedTextRange = [self.view textRangeFromPosition:start toPosition:end];
    callback(kUIMethodSuccess, @"Success.");
}

- (void)setInputTextDirection {
    UITextPosition *beginning = self.view.beginningOfDocument;
    UITextPosition *ending = self.view.endOfDocument;
    UITextRange *textRange = [self.view textRangeFromPosition:beginning toPosition:ending];
    
    // setBaseWritingDirection will change textAlignment. stash it.
    NSInteger textAlignment = [self.view textAlignment];
    if (self.directionType == LynxDirectionNormal) {
        [self.view setBaseWritingDirection:NSWritingDirectionNatural forRange:textRange];
    } else if (self.directionType == LynxDirectionLtr) {
        [self.view setBaseWritingDirection:NSWritingDirectionLeftToRight forRange:textRange];
    } else if (self.directionType == LynxDirectionRtl) {
        [self.view setBaseWritingDirection:NSWritingDirectionRightToLeft forRange:textRange];
    }
    [self.view setTextAlignment:textAlignment];
    
    if (self.view.text.length == 0) {
        [self syncPlaceHolderDirection];
    }
}

- (void)syncPlaceHolderDirection {
    // set i18n format
    if (self.directionType == LynxDirectionNormal) {
        if ([[[UIDevice currentDevice] systemVersion] intValue] >= 9) {
            self.placeholderAttributes[NSWritingDirectionAttributeName] = @[[NSNumber numberWithInt:NSWritingDirectionNatural|NSWritingDirectionEmbedding]];
        } else {
            self.placeholderAttributes[NSWritingDirectionAttributeName] = @[[NSNumber numberWithInt:NSWritingDirectionNatural]];
        }
    } else if (self.directionType == LynxDirectionLtr) {
        if ([[[UIDevice currentDevice] systemVersion] intValue] >= 9) {
            self.placeholderAttributes[NSWritingDirectionAttributeName] = @[[NSNumber numberWithInt:NSWritingDirectionLeftToRight|NSWritingDirectionEmbedding]];
        } else {
            self.placeholderAttributes[NSWritingDirectionAttributeName] = @[[NSNumber numberWithInt:NSWritingDirectionLeftToRight]];
        }
    } else if (self.directionType == LynxDirectionRtl) {
        if ([[[UIDevice currentDevice] systemVersion] intValue] >= 9) {
            self.placeholderAttributes[NSWritingDirectionAttributeName] = @[[NSNumber numberWithInt:NSWritingDirectionRightToLeft|NSWritingDirectionEmbedding]];
        } else {
            self.placeholderAttributes[NSWritingDirectionAttributeName] = @[[NSNumber numberWithInt:NSWritingDirectionRightToLeft]];
        }
    }
    
    if (self.placeHolderValue)
        self.view.attributedPlaceholder = [[NSAttributedString alloc] initWithString:self.placeHolderValue attributes:self.placeholderAttributes];
}

LYNX_UI_METHOD(focus) {
    if ([self.view becomeFirstResponder]) {
        callback(kUIMethodSuccess, @"Success to focus.");
    } else {
        callback(kUIMethodUnknown, @"Fail to focus");
    }
}

LYNX_UI_METHOD(blur) {
    if ([self.view isFirstResponder]) {
        if ([self.view resignFirstResponder]) {
            callback(kUIMethodSuccess, @"Success to focus.");
        } else {
            callback(kUIMethodUnknown, @"Fail to blur");
        }
    } else {
        callback(kUIMethodUnknown, @"Target is not focusd now.");
    }
}

LYNX_UI_METHOD(getSelection) {
    if ([self.view isFirstResponder]) {
        UITextPosition *beginning = self.view.beginningOfDocument;
        UITextRange *selectedTextRange = self.view.selectedTextRange;
        NSNumber *selectionStart = [NSNumber numberWithInteger:[self.view offsetFromPosition:beginning toPosition:selectedTextRange.start]];
        NSNumber *selectionEnd = [NSNumber numberWithInteger:[self.view offsetFromPosition:beginning toPosition:selectedTextRange.end]];
        NSDictionary *result = [NSDictionary dictionaryWithObjectsAndKeys:selectionStart, @"selectionStart", selectionEnd, @"selectionEnd", nil];
        callback(kUIMethodSuccess, result);
    } else {
        callback(kUIMethodUnknown, @"Target is not focusd now.");
    }
}

LYNX_PROP_SETTER("auto-correct", setEnableAutoCorrect, BOOL) {
    if (requestReset) {
        [self.view setAutocorrectionType:UITextAutocorrectionTypeDefault];
        return;
    }
    
    if (value) {
        [self.view setAutocorrectionType:UITextAutocorrectionTypeYes];
    } else {
        [self.view setAutocorrectionType:UITextAutocorrectionTypeNo];
    }
}

LYNX_PROP_SETTER("spell-check", setEnableSpellCheck, BOOL) {
    if (requestReset) {
        [self.view setSpellCheckingType:UITextSpellCheckingTypeDefault];
        return;
    }
    
    if (value) {
        [self.view setSpellCheckingType:UITextSpellCheckingTypeYes];
    } else {
        [self.view setSpellCheckingType:UITextSpellCheckingTypeNo];
    }
}

LYNX_PROP_SETTER("compat-number-type", setCompatNumberType, BOOL) {
    if (requestReset) {
        _mCompatNumberType = NO;
    } else {
        _mCompatNumberType = value;
    }
    [self applyCompatNumberType];
}

- (void)applyCompatNumberType {
    if (_mCompatNumberType) {
        if (_mInputType == TYPE_CLASS_NUMBER) {
            _mKeyListener = [[BDXLynxDigitKeyListener alloc] initWithParamsNeedsDecimal:NO sign:NO];
        }
    } else {
        if (_mInputType == TYPE_CLASS_NUMBER) {
            _mKeyListener = [[BDXLynxDigitKeyListener alloc] initWithParamsNeedsDecimal:YES sign:YES];
        }
    }
}

LYNX_PROP_SETTER("send-composing-input", setSendComposingInputEvent, BOOL) {
    if (requestReset) {
        _mSendComposingInputEvent = NO;
    } else {
        _mSendComposingInputEvent = value;
    }
}

#pragma mark - EventEmitter

- (void)emitEvent:(NSString*) name detail:(NSDictionary*) detail {
    LynxCustomEvent *eventInfo = [[LynxDetailEvent alloc] initWithName:name
                                                                  targetSign:[self sign]
                                                                      detail:detail];
    [self.context.eventEmitter dispatchCustomEvent:eventInfo];
}

- (void)textFieldDidChange:(BDXLynxTextField *)textField
{
    /* TODO(zhangkaijie.9): find solution for split source and dest for dictation.
     * Text from dictation will only triggers shouldChangeCharactersInRange when user confirms dictation.
     * Before that, the text will be directly set into the textfield and input will send input event.
     * Event we implement insertDictationResult, it also only be triggered when user confirms dictation.
     */
    if (textField.waitingDictationRecognition) {
        return;
    }

    UITextRange*selectedRange = [textField markedTextRange];
    UITextPosition*position = [textField positionFromPosition:selectedRange.start offset:0];
    UITextPosition* beginning = textField.beginningOfDocument;
    
    //calc cursor position, offset will be 0 if position is nil
    UITextPosition *selectedEnd = [textField positionFromPosition:selectedRange.end offset:0];
    NSInteger cursorPositionOfInputEvent = [textField offsetFromPosition:beginning toPosition:selectedEnd];
    // isComposing 0: no; 1: yes;
    NSInteger isComposing = 1;
    if(!position || !selectedRange) {
        /* The sequence of the filter is: length -> type -> customRegex
         * Input runs the length filter first, because it relies heavily on the exact cursor position.
         */
        
        // calc new cursor postion
        UITextRange *selectedTextRange = textField.selectedTextRange;
        NSInteger cursorPosition = [textField offsetFromPosition:beginning toPosition:selectedTextRange.start];
        /* there are 2 scenes:
         * 1. cursorPosition = 0 if text's width shorter than textarea's width when textarea is not firstResponder.
         * 2. cursorPosition = 'very large value' when text was truncated by UITextField if UITextField has never been focused.
         * about 1: different with UITextView, UITextField's cursor is placed at the beginning of text instead of ending.
         * about 2: ParagraphStyle.lineBreakMode cannot affect the truncate logic of UITextField, before the UITextField is focused once.
         */
        if (!textField.isFirstResponder) {
            if (cursorPosition > textField.text.length || cursorPosition == 0) {
                cursorPosition = textField.text.length;
            }
        }
        cursorPositionOfInputEvent = cursorPosition;
        
        // Separate the newly input string 'source' from the current string 'dest'. We only filter the 'source'.
        // We consider the _mSourceLength characters before the cursor to be 'source'.
        NSInteger dstart = cursorPositionOfInputEvent - _sourceLength > 0 ? cursorPositionOfInputEvent - _sourceLength : 0;
        NSString *source = textField.text;
        NSInteger leftLen = dstart;
        NSInteger rightLen = textField.text.length - cursorPositionOfInputEvent;
        NSMutableString *dest = [[source substringWithRange:NSMakeRange(0, leftLen)] mutableCopy];
        [dest appendString:[source substringWithRange:NSMakeRange(cursorPositionOfInputEvent, rightLen)]];
        source = [source substringWithRange:NSMakeRange(leftLen, _sourceLength)];
        
        /*
         * We need do this after text has been replaced because we can't detect highlight text in shouldChangeCharactersInRange in UITextField.
         */
        if(self.maxLength > 0 && textField.text.length > self.maxLength) {
            // length filter. Keep 'keep' characters in source.
            // because the text we get has been replaced, so we can assume that dstart = dend.
            // keep <=0, filter all chars. keep > sourceLength, accept all chars.
            NSInteger keep = self.maxLength - dest.length; // (dest.length - (dend - dstart))
            if (keep <= 0) {
                source = @"";
            } else if (keep < _sourceLength) {
                NSRange subRange = NSMakeRange(0, keep);
                NSRange composedSubRange = [source rangeOfComposedCharacterSequencesForRange:subRange];
                source = [source substringWithRange:composedSubRange];
            }
            
            // We need to find and filter emoji within the scope of newChangeRange.
            // Simple filtering is not feasible because the combined emoji is too long.
            NSString* emojiFilteredText = [NSMutableString stringWithString:source];
            if (emojiFilteredText != nil) {
                NSError* regexError;
                NSRegularExpression* emojis = [NSRegularExpression
                                              regularExpressionWithPattern:EMOJI_PATTERN
                                              options:NSRegularExpressionCaseInsensitive error:&regexError];
                if (regexError == nil) {
                    NSArray *matches = [emojis matchesInString:emojiFilteredText
                                                    options:0
                                                      range:NSMakeRange(0, emojiFilteredText.length)];
                    for (NSTextCheckingResult *match in matches) {
                        NSRange matchRange = [match range];
                        if (matchRange.location + matchRange.length > keep) {
                            emojiFilteredText = [emojiFilteredText substringToIndex:matchRange.location];
                            break;
                        }
                    }
                }
            }
            // The new emoji may be failed to filter, simply make up for it
            NSRange emojiFilteredRange = NSMakeRange(0, emojiFilteredText.length);

            // If we miss some emojis in the regular rules for some reason, then we need to make up for it.
            if (emojiFilteredRange.length == source.length + 1 && emojiFilteredRange.length >= 2) {
                emojiFilteredRange = NSMakeRange(emojiFilteredRange.location, emojiFilteredRange.length - 2); //emoji
            }
            NSString* lengthFilteredText = [emojiFilteredText substringWithRange:emojiFilteredRange];
            source = lengthFilteredText;
        }
        
        // type filter
        NSString* typeFilteredString = [self.mKeyListener filter:source start:0 end:source.length dest:dest dstart:dstart dend:dstart];

        // input filter
        NSMutableString* filteredText = [NSMutableString stringWithString:typeFilteredString];
        if (filteredText != nil && ![self.mFilterPattern isEqualToString:@""]) {
            NSError* regexError;
            NSRegularExpression* exclude = [NSRegularExpression
                                            regularExpressionWithPattern:self.mFilterPattern
                                            options:NSRegularExpressionCaseInsensitive error:&regexError];
            if (regexError == nil) {
                [exclude replaceMatchesInString:filteredText
                                        options:0
                                        range:NSMakeRange(0, filteredText.length)
                                        withTemplate:@""];
            }
        }
        
        // apply filterdText
        [dest insertString:filteredText atIndex:dstart];
        textField.text = dest;
        
        if (self.mLetterSpacing != 0) {
            NSMutableAttributedString *newAttributedText = [textField.attributedText mutableCopy];
            [newAttributedText addAttribute:NSKernAttributeName value:@(self.mLetterSpacing) range:NSMakeRange(0, textField.text.length)];
            textField.attributedText = newAttributedText;
        }

        // set lineBreakMode
        NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
        // TODO use prop NSLineBreakByClipping/NSLineBreakByTruncatingTail
        style.lineBreakMode = NSLineBreakByClipping;
        style.alignment = textField.textAlignment;
        NSMutableAttributedString *newAttributedText = [textField.attributedText mutableCopy];
        [newAttributedText addAttributes:[NSDictionary dictionaryWithObjectsAndKeys:style, NSParagraphStyleAttributeName, nil] range:NSMakeRange(0, textField.attributedText.length)];
        textField.attributedText = newAttributedText;

        /* Why do we need to recalculate the cursor position here?
         * Because setText in UITextField will place cursor at the end!!!
         * So we need calc a new cursor position after type and customRegex filter has deleted some text.
         */
        NSInteger lengthOfCursorPositionShouldBackward = _sourceLength - filteredText.length;
        NSInteger cursorPositionAfterFilters = cursorPositionOfInputEvent - lengthOfCursorPositionShouldBackward;
        // set new cursor postion
        UITextPosition* newCursorPosition = [textField positionFromPosition:beginning offset:cursorPositionAfterFilters];
        cursorPositionOfInputEvent = cursorPositionAfterFilters;
        textField.selectedTextRange = [textField textRangeFromPosition:newCursorPosition toPosition:newCursorPosition];
        
        // for rtl format
        // Modifying BaseWritingDirection is known to cause lineBreakMode to fail and contentSize to change. Try to revise it last
        [self setInputTextDirection];
        
        isComposing = 0;
        
        // A very annoying bad case. After entering any char, tap the space twice consecutively,
        // and the UIKeyboard will directly initiate a textFieldDidChange without initiating shouldChangeCharactersInRange.
        // The above operation will go through the following process: 'x' -> 'x ' -> 'x' -> 'x.'
        // We will get textFieldDidChange when 'x ' but _mSourceLength has not been updated in shouldChangeCharactersInRange.
        // So we need to reset _mSourceLength to 0 to prevent loss of deletion events
        _sourceLength = 0;
    }

    if ((!position || !selectedRange) || _mSendComposingInputEvent) {
        if(!self.mIsChangeFromLynx) {
            NSDictionary *detail = @{
                @"value" : [self.view text] ?: @"",
                @"textLength": @(textField.text.length),
                @"isComposing": @(isComposing),
                @"cursor": @(cursorPositionOfInputEvent)
            };
            [self emitEvent:@"input" detail:detail];
        }
        if(self.mIsChangeFromLynx) {
            self.mIsChangeFromLynx = NO;
        }
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    if (self.readonly) {
        return NO;
    }
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    return self.autoHideKeyboard;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    // textfield got focused
    NSDictionary *detail = @{
      @"value" : [self.view text] ?: @""
    };
    [self emitEvent:@"focus" detail:detail];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    NSDictionary *detail = @{
      @"value" : [self.view text] ?: @""
    };
    [self emitEvent:@"blur" detail:detail];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    NSDictionary *detail = @{
         @"value" : [self.view text] ?: @""
    };
    
    [self emitEvent:@"confirm" detail:detail];
    
    if (self.view.returnKeyType != UIReturnKeyNext) {
        [self.view resignFirstResponder];
    } else {
        NSInteger nextTag = self.view.tag + 1;
        // Try to find next responder
        UIResponder* nextResponder = [self.context.rootView viewWithTag:nextTag];
        if (nextResponder != nil) {
            // Found next responder, so set it.
            [nextResponder becomeFirstResponder];
        } else {
            [self.view resignFirstResponder];
        }
    }
    return YES;
}



- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    // Don't check for highlighted text here!
    // UITextField iOS 14.3. The first pinyin highlighted character cannot be detected by the system as being highlighted [textView markedRange]
    // Single line the return should complete input
    if([string isEqualToString:@"\n"]) {
        [self.view resignFirstResponder];
        return NO;
    }

    // avoid ios clear the SecureText text when change to SecureType
    if (textField.isSecureTextEntry) {
        NSString *newText = [textField.text stringByReplacingCharactersInRange:range withString:string];
        textField.text = newText;
        [self textFieldDidChange:(BDXLynxTextField *)textField];
        return NO;
    }

    // record the length of newly input content
    _sourceLength = string.length;
    
    // We may not be able to detect whether there is a highlighted text here by [textFiled markedTextRange],
    // and `return NO` here in the uitextfield will cause the Chinese 26-key keyboard to be unable to input Chinese,
    // so we just `return YES` here.
    return YES;
}

- (void)dealloc
{
    [self.view endEditing:YES];
}

- (void)delete:(id)sender
{
    // An empty method to fix an iOS potential crash: `[UnSelector]-[BDXLynxTextField delete:]: unrecognized selector sent to instance xxx`.
}

- (CGFloat)textHeight {
    // TODO
    return self.view.intrinsicContentSize.height;
}


- (void)onListCellDisappear:(NSString*)itemKey exist:(BOOL)isExist withList:(LynxUICollection*)list {
  [super onListCellDisappear:itemKey exist:isExist withList:list];
  // store current input text
  if (itemKey) {
    NSString *cacheKey = [NSString stringWithFormat:@"%@_input_%@", itemKey, self.idSelector];
    if (isExist) {
      if (self.view.text) {
        list.listNativeStateCache[cacheKey] = self.view.text;
      }
    } else {
      [list.listNativeStateCache removeObjectForKey:cacheKey];
    }
  }
  
}
- (void)onListCellPrepareForReuse:(NSString*)itemKey withList:(LynxUICollection*)list {
    [super onListCellPrepareForReuse:itemKey withList:list];
    // restore input text
    if (itemKey) {
        NSString *cacheKey = [NSString stringWithFormat:@"%@_input_%@", itemKey, self.idSelector];
        NSString *text = list.listNativeStateCache[cacheKey];
        _sourceLength = text.length;
        self.view.text = text;
        [self textFieldDidChange:(BDXLynxTextField *)self.view];
    }
}

- (void)onFontFaceLoad {
    if (_mFontFamilyName != nil) {
        [self setFont];
    }
    
    if (_mPlaceholderFontFamilyName != nil && self.placeHolderValue) {
        [self setPlaceholderFont];
        self.view.attributedPlaceholder = [[NSAttributedString alloc] initWithString:self.placeHolderValue attributes:self.placeholderAttributes];
    }
}

- (void)setFont {
    LynxFontFaceContext* fontFaceContext = self.context.fontFaceContext;
    UIFont *font = [[LynxFontFaceManager sharedManager]
                generateFontWithSize:_mFontSize
                weight:_mFontWeight
                style:LynxFontStyleNormal
                fontFamilyName:_mFontFamilyName
                fontFaceContext:fontFaceContext
                fontFaceObserver:self];
    [self.view setFont:font];
}

- (void)setPlaceholderFont {
    LynxFontFaceContext* fontFaceContext = self.context.fontFaceContext;
    UIFont *placeholderFont = [[LynxFontFaceManager sharedManager]
                    generateFontWithSize:_mPlaceholderFontSize
                    weight:_mPlaceholderFontWeight
                    style:LynxFontStyleNormal
                    fontFamilyName:_mPlaceholderFontFamilyName
                    fontFaceContext:fontFaceContext
                    fontFaceObserver:self];
    self.placeholderAttributes[NSFontAttributeName] = placeholderFont;
}

- (void)insertChild:(id)child atIndex:(NSInteger)index {
    UIView* view = nil;
    if ([child isKindOfClass:[LynxUI class]] || [child isKindOfClass:[LynxUIComponent class]]) {
        view = [(LynxUI *)child view];
    }
    
    if (view != nil) {
        _mInputAccessoryView = view;
        [self.view setInputAccessoryView:view];
    }
}

@end
