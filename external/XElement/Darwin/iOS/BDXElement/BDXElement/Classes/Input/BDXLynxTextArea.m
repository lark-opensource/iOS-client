//
//  BDXLynxTextArea.m
//  AWEABTest
//
//  Created by annidy on 2020/5/21.
//

#import "BDXLynxTextArea.h"
#import "BDXLynxInput.h"
#import "BDXLynxTextAreaShadowNode.h"
#import "BDXLynxInputUtils.h"
#import "Emoji/BDXLynxInputBracketRichTextFormater.h"
#import <Lynx/LynxLog.h>
#import <Lynx/LynxRootUI.h>
#import <Lynx/LynxComponentRegistry.h>
#import <Lynx/LynxPropsProcessor.h>
#import <Lynx/LynxColorUtils.h>
#import <Lynx/LynxUnitUtils.h>
#import <Lynx/LynxShadowNodeOwner.h>
#import <objc/message.h> // for objc associated object
#import <Lynx/LynxFontFaceManager.h>
#import <Lynx/LynxUIComponent.h>

// Default limited to 140
static NSInteger const kBDXInputDefaultMaxLength = 140;
//static NSInteger const MAX_INT = 2147483647;
// This is a regular expression that can match some common emojis. We also need to improve it to match all emoji.
static NSString* const EMOJI_PATTERN = @"[\\u2600-\\u27BF\\U0001F300-\\U0001F77F\\U0001F900-\\U0001F9FF]|[\\u2600-\\u27BF\\U0001F300-\\U0001F77F\\U0001F900–\\U0001F9FF]\\uFE0F|[\\u2600-\\u27BF\\U0001F300-\\U0001F77F\\U0001F900–\\U0001F9FF][\\U0001F3FB-\\U0001F3FF]|[\\U0001F1E6-\\U0001F1FF][\\U0001F1E6-\\U0001F1FF]";

// A tag to mark textarea
static NSInteger gTextareaTag = 10001;

@interface BDXLynxTextArea() <UITextViewDelegate, LynxFontFaceObserver>

@property (nonatomic) BOOL smartScroll;

@end

@implementation BDXLynxTextArea {
    BOOL _firstScreenLayoutDidFinished;
    BOOL _shouldFocusAfterLayout;
    CGFloat _bottomInsetAddedOnScrollView;
}

#if LYNX_LAZY_LOAD
LYNX_LAZY_REGISTER_UI("textarea")
#else
LYNX_REGISTER_UI("textarea")
#endif

- (instancetype)init {
    self = [super init];
    if (self) {
        _maxLength = kBDXInputDefaultMaxLength;
        _readonly = NO;
        _mIsChangeFromLynx = NO;
        _mFilterPattern = @"";
        _smartScroll = YES;
        _mAdjustMode = @"end";
        _mAutoFit = YES;
        _mBottomInset = 0;
        _mKeyboardHeight = 0;
        _autoHeightInputNeedSmartScroll = NO;
        _currentUserInfo = nil;
        _mLetterSpacing = 0;
        _mFontSize = 14;
        _mFontWeight = UIFontWeightRegular;
        _mEnterShouldConfirm = NO;
        _mWidth = 0;
        _mHeight = 0;
        _firstScreenLayoutDidFinished = NO;
        _shouldFocusAfterLayout = NO;
        _richTextFormater = nil;
        _mSendComposingInputEvent = NO;
        _fontStyleChanged = NO;
        _placeholderFontStyleChanged = NO;
        _bottomInsetAddedOnScrollView = 0;
        _mInputAccessoryView = nil;
        _iosAutoHeightNewer = NO;
        _maxLines = 0;
        _sourceLength = 0;
        _iosMaxLinesNewer = NO;
    }
    
   // default font-size 14px
   CGFloat defaultFontSize = [LynxUnitUtils toPtFromUnitValue: @"14px"];
   [self.view setFont:[UIFont systemFontOfSize:defaultFontSize]];
   [self.view refreshPlaceHolderFont];
    // default text-color black
    [self.view setTextColor:[UIColor blackColor]];
    
    return self;
}

- (BDXLynxTextView*) createView {
    BDXLynxTextView* txtControl = [[BDXLynxTextView alloc] init];
    txtControl.clipsToBounds = YES;
    txtControl.delegate = self;
    txtControl.secureTextEntry = NO;
    txtControl.backgroundColor = [UIColor clearColor];
    // Default value is 5.0. UITextView(UIScrollView) did not set it to 0.
    txtControl.textContainer.lineFragmentPadding = 0;
    
    NSNotificationCenter *notifCenter = [NSNotificationCenter defaultCenter];
    [notifCenter addObserver:self selector:@selector(onWillShowKeyboard:) name:UIKeyboardWillShowNotification object:nil];
    [notifCenter addObserver:self selector:@selector(onWillHideKeyboard:) name:UIKeyboardWillHideNotification object:nil];
    
    txtControl.tag = gTextareaTag++;
    return txtControl;
}

- (void)dealloc {
}

- (void)frameDidChange {
    [super frameDidChange];
    
    // Remove mask layer to adjust the input element in content area
    self.view.layer.mask = nil;
}

- (bool)updateLayerMaskOnFrameChanged {
    return false;
}

// The layoutDidFinished callback can ensure the context has been set.
-(void) layoutDidFinished {
    [super layoutDidFinished];
    
    _firstScreenLayoutDidFinished = YES;
    
    // Extract borders & padding
    CGFloat x = self.frame.origin.x + self.border.left;
    CGFloat y = self.frame.origin.y + self.border.top;
    CGFloat width = self.frame.size.width - self.border.left - self.border.right;
    CGFloat height = self.frame.size.height - self.border.top - self.border.bottom;
    if([self.view isKindOfClass:UITextView.class]){
        self.view.placeHolderTextView.textContainerInset = self.padding;
        self.view.textContainerInset = self.padding;
    }
    [self.view setFrame:CGRectMake(x, y, width, height)];
    
    LynxShadowNodeOwner* owner = self.context.nodeOwner;
    if (owner != nil) {
        LynxShadowNode* node = [owner nodeWithSign:self.sign];
        if (node != nil && [node isKindOfClass:[BDXLynxTextAreaShadowNode class]]) {
            BDXLynxTextAreaShadowNode* n = (BDXLynxTextAreaShadowNode*)node;
          n.fontFromUI = [[self.view font] copy];
          n.textHeightFromUI = @(self.textHeight);
          n.heightFromUI = @(self.frame.size.height);
            if ([n needRelayout]) {
                [n setNeedRelayout:NO];
                [n setNeedsLayout];
            }
        }
    }
    _mWidth = width;
    _mHeight = height;
    
    // autoHeight need scroll
    if (self.autoHeightInputNeedSmartScroll && self.currentUserInfo != nil) {
        [self onWillShowKeyboardChanged:YES userInfo:self.currentUserInfo];
        self.autoHeightInputNeedSmartScroll = NO;
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
    
    if (_fontStyleChanged) {
        if (_mFontFamilyName == nil) {
            [self.view setFont:[UIFont systemFontOfSize:_mFontSize weight:_mFontWeight]];
        } else {
            [self setFont];
        }
        _fontStyleChanged = NO;
        _mIsChangeFromLynx = YES;
        [self textViewDidChange:self.view];
    }
    
    if (_placeholderFontStyleChanged) {
        [self.view refreshPlaceHolderFont];
        _placeholderFontStyleChanged = NO;
    }
}

# pragma mark - KEYBOARD

- (void)onWillShowKeyboard:(NSNotification *)notification
{
    self.currentUserInfo = notification.userInfo;
    [self onWillShowKeyboardChanged:YES userInfo:notification.userInfo];
}

- (void)onWillHideKeyboard:(NSNotification *)notification
{
    self.currentUserInfo = nil;
    [self onWillShowKeyboardChanged:NO userInfo:notification.userInfo];
}

- (void)onWillShowKeyboardChanged:(BOOL)showKeyboard userInfo:(NSDictionary *)userInfo
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
             | | | |       input      |   | | |
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
            [self updateScrollView:scrollView showKeyboard:YES diff:diff bottomInset:bottomInset userInfo:userInfo];
        } else if (!showKeyboard) {
            // Unlike Android, iOS ScrollView allows you to set any Offset value.
            // So when the keyboard hide, we need to reset the offset beyond the ScrollRange.
            CGFloat legalScrollRange = scrollView.contentSize.height - scrollView.frame.size.height;
            CGFloat diff = 0;
            if (scrollView.contentOffset.y > legalScrollRange) {
                diff = legalScrollRange - scrollView.contentOffset.y;
            }
            [self updateScrollView:scrollView showKeyboard:NO diff:diff bottomInset:0 userInfo:userInfo];
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

- (void)setValue:(NSString *)value index:(nullable NSNumber*)index callback:(nullable LynxUIMethodCallbackBlock)callback{
    self.mIsChangeFromLynx = YES;
    [self.view setText:value];
    _sourceLength = value.length;
    [self textViewDidChange:self.view];
    if (index != NULL) {
        NSInteger intIndex = [index intValue];
        if (intIndex >= 0 && intIndex <= self.view.text.length) {
            UITextPosition* beginning = self.view.beginningOfDocument;
            UITextPosition* newCursorPosition = [self.view positionFromPosition:beginning offset:intIndex];
            self.view.selectedTextRange = [self.view textRangeFromPosition:newCursorPosition toPosition:newCursorPosition];
            /* If the specified index is before the cursor in setValue,
             * the textarea may scroll to a position where the cursor cannot be seen.
             * So we need to show it.
             */
            [self.view scrollRangeToVisible:NSMakeRange(intIndex, 0)];
        }
    }
    if (callback != NULL) {
        callback(kUIMethodSuccess, @"Success.");
    }
    [self.view showOrHidePlaceHolder];
}

LYNX_PROP_SETTER("value", setValue, NSString*) {
    if (requestReset) {
        value = @"";
    }
    
    NSString* currentValue = self.view.text;
    if (_richTextFormater) {
        currentValue = [self.view getRawText];
    }
    if ([currentValue isEqualToString:value]) {
        return;
    }

    [self setValue:value index:NULL callback:NULL];
}

LYNX_PROP_SETTER("type", setType, NSString*) {
    if (requestReset) {
        value = @"text";
    }
    
    // only support the following types: number, text and digit, password.
    [self.view setSecureTextEntry:NO];
    
    if ([value isEqualToString:@"text"]) {
        [self.view setKeyboardType:UIKeyboardTypeDefault];
    } else if ([value isEqualToString:@"number"]) {
        [self.view setKeyboardType:UIKeyboardTypeNumberPad];
    } else if ([value isEqualToString:@"digit"]) {
        [self.view setKeyboardType:UIKeyboardTypeDecimalPad];
    } else if ([value isEqualToString:@"password"]) {
        [self.view setSecureTextEntry:YES];
    }
}

LYNX_PROP_SETTER("placeholder", setPlaceHolder, NSString*) {
    if (requestReset) {
        value = @"";
    }
    
    [self.view setPlaceHolder:value];
    [self.view syncPlaceHolderTextAligment];
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

LYNX_PROP_SETTER("maxlines", setMaxLines, int) {
    if (requestReset) {
        value = 0;
    }
    
    _maxLines = value;
    [[self.view textContainer] setMaximumNumberOfLines:value];
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
    if (requestReset) {
        _mFontSize = [LynxUnitUtils toPtFromUnitValue:@"14px"];
    } else {
        _mFontSize = value;
    }
    
    if (!self.view.isCustomPlaceHolderFontSize) {
        [self.view setMPlaceHolderFontSize:_mFontSize];
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
    
    if (!self.view.isCustomPlaceHolderFontWeight) {
        [self.view setMPlaceHolderFontWeight:_mFontWeight];
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
    
    if (!self.view.isCustomPlaceHolderFontFamily) {
        [self.view setFontFaceContext:self.context.fontFaceContext];
        [self.view setMPlaceholderFontFamilyName:_mFontFamilyName];
        _placeholderFontStyleChanged = YES;
    }
    _fontStyleChanged = YES;
}

LYNX_PROP_SETTER("placeholder-color", setPlaceHolderColor, NSString*) {
    if (requestReset) {
        // [UIColor placeholderTextColor]
        [self.view setPlaceHolderColor:[UIColor colorWithRed:0.235 green:0.263 blue:0.235 alpha:0.3]];
    } else {
        [self.view setPlaceHolderColor:[LynxColorUtils convertNSStringToUIColor:value]];
    }
}

LYNX_PROP_SETTER("placeholder-font-size", setPlaceHolderFont, NSString*) {
    if (requestReset) {
        self.view.isCustomPlaceHolderFontSize = NO;
        [self.view setMPlaceHolderFontSize:_mFontSize];
    } else {
        self.view.isCustomPlaceHolderFontSize = YES;
        [self.view setMPlaceHolderFontSize:[LynxUnitUtils toPtFromUnitValue:value]];
    }
    _placeholderFontStyleChanged = YES;
}

LYNX_PROP_SETTER("placeholder-font-weight", setPlaceHolderWeight, NSString*) {
    if (requestReset) {
        self.view.isCustomPlaceHolderFontWeight = NO;
        [self.view setMPlaceHolderFontWeight:_mFontWeight];
    } else {
        CGFloat fontWeight = UIFontWeightRegular;
        if ([value isEqual:@"normal"]   || [value isEqual:@"400"]) {
            fontWeight = UIFontWeightRegular;
        } else if ([value isEqual:@"bold"] || [value isEqual:@"700"]) {
            fontWeight = UIFontWeightBold;
        } else if ([value isEqual:@"100"]) {
            fontWeight = UIFontWeightUltraLight;
        } else if ([value isEqual:@"200"]) {
            fontWeight = UIFontWeightThin;
        } else if ([value isEqual:@"300"]) {
            fontWeight = UIFontWeightLight;
        } else if ([value isEqual:@"500"]) {
            fontWeight = UIFontWeightMedium;
        } else if ([value isEqual:@"600"]) {
            fontWeight = UIFontWeightSemibold;
        } else if ([value isEqual:@"800"]) {
            fontWeight = UIFontWeightHeavy;
        } else if ([value isEqual:@"900"]) {
            fontWeight = UIFontWeightBlack;
        }
        self.view.isCustomPlaceHolderFontWeight = YES;
        [self.view setMPlaceHolderFontWeight:fontWeight];
    }
    _placeholderFontStyleChanged = YES;
}

LYNX_PROP_SETTER("placeholder-font-family", setPlaceholderFontFamily, NSString*) {
    if (requestReset) {
        if (_mFontFamilyName != nil) {
            [self.view setFontFaceContext:self.context.fontFaceContext];
            [self.view setMPlaceholderFontFamilyName:_mFontFamilyName];
        } else {
            self.view.mPlaceholderFontFamilyName = nil;
        }
        self.view.isCustomPlaceHolderFontFamily = NO;
    } else {
        self.view.isCustomPlaceHolderFontFamily = YES;
        [self.view setFontFaceContext:self.context.fontFaceContext];
        [self.view setMPlaceholderFontFamilyName:value];
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
            [self.view setPlaceHolderColor: [UIColor colorWithRed:red/255.0f
                green:green/255.0f blue:blue/255.0f alpha:alpha/255.f]];
        }
    }
    
    if (fontWeight) {
        self.view.isCustomPlaceHolderFontWeight = YES;
        CGFloat uiFontWeight = [self convertFontWeightToUIFontWeight:[fontWeight integerValue]];
        [self.view setMPlaceHolderFontWeight:uiFontWeight];
    }
    
    if (fontSize) {
        self.view.isCustomPlaceHolderFontSize = YES;
        [self.view setMPlaceHolderFontSize:[fontSize floatValue]];
    }
    
    if (fontFamily) {
        self.view.isCustomPlaceHolderFontFamily = YES;
        [self.view setFontFaceContext:self.context.fontFaceContext];
        [self.view setMPlaceholderFontFamilyName:fontFamily];
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

LYNX_PROP_SETTER("caret-color", setCaretColor, NSString*) {
    if (requestReset) {
        value = @"blue";
    }
    
    [self.view setTintColor:[LynxColorUtils convertNSStringToUIColor:value]];
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
    _sourceLength = value.length;
    
    NSMutableAttributedString *mutableAttributedString = [self.view.attributedText mutableCopy];
    if (self.view.isFirstResponder) {
        UITextPosition* beginning = self.view.beginningOfDocument;
        UITextRange* selectedRange = self.view.selectedTextRange;
        NSInteger start = [self.view offsetFromPosition:beginning toPosition:selectedRange.start];
        NSAttributedString *insertedString = [[NSAttributedString alloc] initWithString:value attributes:self.view.typingAttributes];
        [mutableAttributedString insertAttributedString:insertedString atIndex:start];
        self.view.attributedText = mutableAttributedString;
        // set new cursor postion
        NSInteger newOffset = start + value.length;
        UITextPosition* newCursorPosition = [self.view positionFromPosition:beginning offset:newOffset];
        self.view.selectedTextRange = [self.view textRangeFromPosition:newCursorPosition toPosition:newCursorPosition];
    } else {
        NSAttributedString *insertedString = [[NSAttributedString alloc] initWithString:value attributes:self.view.typingAttributes];
        [mutableAttributedString appendAttributedString:insertedString];
        self.view.attributedText = mutableAttributedString;
    }
    [self textViewDidChange:self.view];
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
                    NSInteger deletedLength = (start - length >= 0) ? length : start;
                    NSMutableAttributedString *mutableAttributedString = [self.view.attributedText mutableCopy];
                    [mutableAttributedString deleteCharactersInRange:NSMakeRange(start, deletedLength)];
                    self.view.attributedText = mutableAttributedString;
                    _sourceLength = length;

                    // set new cursor postion
                    NSInteger newStart = (start - length >= 0) ? start - length : 0;
                    UITextPosition* newCursorPosition = [self.view positionFromPosition:beginning offset:newStart];
                    self.view.selectedTextRange = [self.view textRangeFromPosition:newCursorPosition toPosition:newCursorPosition];
                } else {
                    for (int i = 0; i < length - 1; i++) {
                        self.mIsChangeFromLynx = YES;
                        [self.view deleteBackward];
                    }
                }
                // send input event
                [self textViewDidChange:self.view];
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

LYNX_PROP_SETTER("adjust-mode", setAdjustMode, NSString*) {
    if (requestReset) {
        value = @"end";
    }
    
    self.mAdjustMode = value;
}

LYNX_PROP_SETTER("smart-scroll", setSmartScroll, BOOL) {
    if (requestReset) {
        value = YES;
    }
    
    self.smartScroll = value;
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

LYNX_PROP_SETTER("text-align", setTextAlign, LynxTextAlignType) {
    if (requestReset) {
        [self.view setMTextAlignment:NSTextAlignmentLeft];
        value = LynxTextAlignLeft;
    } else {
        [self.view setMTextAlignment:value];
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
    
    [self.view syncPlaceHolderTextAligment];
}

LYNX_PROP_SETTER("direction", setLynxDirection, LynxDirectionType) {
    if (requestReset) {
        value = LynxDirectionNormal;
    }
    
    self.directionType = value;
    [self setInputTextDirection];
}

- (void)setInputTextDirection {
    /* setBaseWritingDirection has caret bug, so we use makeTextWritingDirectionLeftToRight instead of it.
     * setBaseWritingDirection will change contentSize and _selection. It is a dangerous stupid api.
     * makeTextWritingDirectionLeftToRight will change textAlignment. stash it.
     */
    NSInteger textAlignment = [self.view textAlignment];
    if (self.directionType == LynxDirectionNormal || self.directionType == LynxDirectionLtr) {
        [self.view makeTextWritingDirectionLeftToRight:self.view];
    } else if (self.directionType == LynxDirectionRtl || self.directionType == LynxDirectionRtl) {
        [self.view makeTextWritingDirectionRightToLeft:self.view];
    }
    [self.view setTextAlignment:textAlignment];
    
    if (self.view.text.length == 0) {
        // todo move cursor to left/right
        [self.view syncPlaceHolderDirection:self.directionType];
    }
}

LYNX_PROP_SETTER("letter-spacing", setLetterSpacing, CGFloat) {
    if (requestReset) {
        value = 0;
    }
    
    self.mLetterSpacing = value;
    
    [self.view syncPlaceHolderLetterSpacing:value];
    
    self.mIsChangeFromLynx = YES;
    [self textViewDidChange:self.view];
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

LYNX_PROP_SETTER("confirm-enter", setConfirmEnter, BOOL) {
    if (requestReset) {
        _mEnterShouldConfirm = NO;
        return;
    }
    _mEnterShouldConfirm = value;
}

LYNX_PROP_SETTER("richtype", setRichType, NSString*) {
    if (requestReset) {
        self.richTextFormater = nil;
        [self.view setMEnableRichText:NO];
        return;
    }

    if ([value containsString:@"bracket"]) {
        self.richTextFormater = [BDXLynxInputBracketRichTextFormater sharedFormater];
        _mIsChangeFromLynx = YES;
        [self textViewDidChange:self.view];
        [self.view setMEnableRichText:YES];
    } else {
        self.richTextFormater = nil;
        [self.view setMEnableRichText:NO];
    }

    if ([value containsString:@"mention"]) {
        // todo
    }
}

LYNX_PROP_SETTER("send-composing-input", setSendComposingInputEvent, BOOL) {
    if (requestReset) {
        _mSendComposingInputEvent = NO;
    } else {
        _mSendComposingInputEvent = value;
    }
}

LYNX_PROPS_GROUP_DECLARE(
	LYNX_PROP_DECLARE("ios-auto-height-newer", setIosAutoHeightNewer, BOOL))

/**
 * @name: ios-auto-height-newer
 * @description: Use a new height calculation method to ensure the accuracy of autoHeight.
 * @category: different
 * @standardAction: remove
 * @supportVersion: 2.7
 * @resolveVersion: 2.11
**/
LYNX_PROP_DEFINE("ios-auto-height-newer", setIosAutoHeightNewer, BOOL) {
    if (requestReset) {
        _iosAutoHeightNewer = NO;
    } else {
        _iosAutoHeightNewer = value;
    }
}

LYNX_PROPS_GROUP_DECLARE(
    LYNX_PROP_DECLARE("ios-maxlines-newer", setIosMaxLinesNewer, BOOL))

/**
 * @name: ios-maxlines-newer
 * @description: Use a new calculation method to ensure the accuracy of lines.
 * @category: different
 * @standardAction: remove
 * @supportVersion: 2.9
 * @resolveVersion: 2.11
**/
LYNX_PROP_DEFINE("ios-maxlines-newer", setIosMaxLinesNewer, BOOL) {
    if (requestReset) {
        _iosMaxLinesNewer = NO;
    } else {
        _iosMaxLinesNewer = value;
        if (_iosMaxLinesNewer) {
            [[self.view textContainer] setMaximumNumberOfLines:0];
        }
    }
}


#pragma mark - EventEmitter

- (void) emitEvent:(NSString*) name detail:(NSDictionary*) detail {
    LynxCustomEvent *eventInfo = [[LynxDetailEvent alloc] initWithName:name
                                                                  targetSign:[self sign]
                                                                      detail:detail];
    [self.context.eventEmitter dispatchCustomEvent:eventInfo];
}

#pragma mark - UITextViewDelegate

- (BOOL)textViewShouldBeginEditing:(UITextView *)txtControl {
    if (self.readonly) {
        return NO;
    }
    return YES;
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    // textfield got focused
    NSString *value = textView.text ?: @"";
    if (_richTextFormater != nil) {
        value = [self.view getRawText];
    }
    NSDictionary *detail = @{
      @"value" : value
    };
    [self emitEvent:@"focus" detail:detail];
    [self.view showOrHidePlaceHolder];
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    NSString *value = textView.text ?: @"";
    if (_richTextFormater != nil) {
        value = [self.view getRawText];
    }
    NSDictionary *detail = @{
      @"value" : value
    };
    [self emitEvent:@"blur" detail:detail];
    [self.view showOrHidePlaceHolder];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    // There is a problem with UITextField detecting the highlighted text here. The problem is given in the comments of BDLynxInput.m.
    // Therefore, in order to avoid risks, we do not judge whether there is currently highlighted text in the UITextView.
    _sourceLength = text.length;
    
    if ([text isEqualToString:@"\n"]) {
        NSString *value = textView.text ?: @"";
        if (_richTextFormater != nil) {
            value = [self.view getRawText];
        }
        [self emitEvent:@"confirm" detail:@{
            @"value" : value
        }];
        
        // consistent with Android. keep textarea's ability to wrap lines. 
        if (self.view.returnKeyType == UIReturnKeyNext) {
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

        // iOS only, just send confirm event for continuous input
        if (_mEnterShouldConfirm) {
            return NO;
        }
    }

    // maxLength <= 0 means unlimited length
    if (self.maxLength <= 0) {
        return YES;
    }

    if ([text isEqualToString:@""] || !text)
        return YES;

    return YES;
}

- (void)applyAutoHeight {
    LynxShadowNodeOwner* owner = self.context.nodeOwner;
    if (owner == nil) {
        return;
    }
    LynxShadowNode* node = [owner nodeWithSign:self.sign];
    if (node == nil || ![node isKindOfClass:[BDXLynxTextAreaShadowNode class]]) {
        return;
    }
    BDXLynxTextAreaShadowNode* n = (BDXLynxTextAreaShadowNode*)node;
    _autoHeightInputNeedSmartScroll = [n updateSizeIfNeeded];
}

/**
 * This function creates an attributed string that limits the number of lines in a BDXLynxTextView and
 *  copies the part of source attributed string to the destination attributed string.
 *
 * The function takes the following parameters:
 *  font: the font that will be used.
 *  maxLines: An NSInteger that specifies the maximum number of lines to be stored in textContainer.
 *  source: The attributed string that will be insert to the dest(destination attributed string).
 *  dest: The destination attributed string, source will be inserted into it to calculate the current line.
 *  dStart: An NSInteger that specifies the starting position of the text in the dest.
 *  dEnd: An NSInteger that specifies the ending position of the text in the dest.
 *  index: A pointer to a cursor that will be used to change cursor position.
 *  constraints: max size of text
 *
 * The function returns the attributed string which meets maxlines constraint. It could be nil.
 *
**/
- (NSAttributedString *)getContentWithLimitedLines:(UIFont*)font
                                             lines:(NSInteger)maxLines
                                            source:(NSAttributedString*)source
                                              dest:(NSAttributedString*)dest
                                            dStart:(NSInteger)dStart
                                              dEnd:(NSInteger)dEnd
                                             index:(NSInteger*)cursor
                                       constraints:(CGSize)constraints
{
    if (source == nil) {
        return nil;
    }
    if (font.lineHeight == 0) {
        LLogError(@"font's lineHeight is 0.");
        return source;
    }
    
    NSInteger left = 0;
    NSInteger right = source.length;
    NSMutableAttributedString *mutableSource = [source mutableCopy];
    // Binary search. Find the largest substring that does not exceed maxlines.
    while (left < right) {
        NSInteger middle = (left + right) / 2;
        
        // Calculate the number of lines by continuously inserting part of the source into dest.
        NSAttributedString *partOfSource = [mutableSource attributedSubstringFromRange:NSMakeRange(0, middle + 1)];
        NSMutableAttributedString *mutableDest = [dest mutableCopy];
        [mutableDest insertAttributedString:partOfSource atIndex:dStart];
        CGSize textSize = [BDXLynxInputUtils getAttributedStringSize:mutableDest constraints:constraints];
        NSInteger lines = (NSInteger)(textSize.height / font.lineHeight + 0.5);
        
        if (lines <= maxLines) {
            left = middle + 1;
        } else {
            right = middle;
        }
    }
    
    // If the source is clipped, then the cursor needs to move forward a certain distance.
    if (right < source.length) {
        *cursor -= (source.length - right);
        if (*cursor < 0) {
            *cursor = 0;
        }
        // send bindline event.
        [self textViewLineEvent:nil];
    }
    
    return [mutableSource attributedSubstringFromRange:NSMakeRange(0, right)];
}

- (void)textViewLineEvent:(UITextView *)textView {
    NSDictionary *detail = @{
    };
    [self emitEvent:@"line" detail:detail];
}

- (void)textViewDidChange:(BDXLynxTextView *)textView {
    if (textView.waitingDictationRecognition) {
        return;
    }
    
    // Above iOS 9, shouldChangeTextInRange will not be triggered when inputing Chinese suggestion words.
    // Therefore, all text filtering is performed in `textViewDidChange`, and only processed when there is no highlighted text.
    UITextRange *selectedRange = [textView markedTextRange];
    UITextPosition *position = [textView positionFromPosition:selectedRange.start offset:0];
    UITextPosition *beginning = textView.beginningOfDocument;
    UITextPosition *ending = textView.endOfDocument;
    
    //calc cursor position, offset will be 0 if position is nil
    UITextPosition *selectedEnd = [textView positionFromPosition:selectedRange.end offset:0];
    NSInteger cursorPositionOfInputEvent = [textView offsetFromPosition:beginning toPosition:selectedEnd];
    // isComposing 0: no; 1: yes;
    NSInteger isComposing = 1;
    
    UITextRange *selectedTextRange = textView.selectedTextRange;
    NSInteger cursorPosition = [textView offsetFromPosition:beginning toPosition:selectedTextRange.start];
    
    if (_iosMaxLinesNewer) {
        // Separate the newly input string 'source' from the current string 'dest'. We only filter the 'source'.
        // We consider the _mSourceLength characters before the cursor to be 'source'.
        NSInteger dStart = cursorPosition - _sourceLength > 0 ? cursorPosition - _sourceLength : 0;
        NSAttributedString *source = textView.attributedText;
        NSInteger leftLen = dStart;
        NSInteger rightLen = textView.text.length - cursorPosition;
        NSMutableAttributedString *dest = [[source attributedSubstringFromRange:NSMakeRange(0, leftLen)] mutableCopy];
        [dest appendAttributedString:[source attributedSubstringFromRange:NSMakeRange(cursorPosition, rightLen)]];
        source = [source attributedSubstringFromRange:NSMakeRange(leftLen, _sourceLength)];
        
        // maxlines filter
        if (_maxLines != 0) {
            source = [self getContentWithLimitedLines:textView.font lines:_maxLines source:source 
                                                 dest:dest dStart:dStart dEnd:dStart index:&cursorPosition
                                          constraints:CGSizeMake(_mWidth, CGFLOAT_MAX)];
            [dest insertAttributedString:source atIndex:dStart];
            textView.attributedText = dest;
        }
    }

    if (!position) {
        // Do not filter text when there is highlighted text
        
        /* The sequence of the filter is: maxlines -> length -> customRegex
         * Input runs the length filter first, because it relies heavily on the exact cursor position.
         */
        cursorPositionOfInputEvent = cursorPosition;
        
        NSInteger cursorPositionAfterLengthFilter = cursorPositionOfInputEvent;
        if (_richTextFormater) {
            // if richtype enable, should use origin rawText when calc length.
            const NSInteger locationLeft = 0;
            const NSInteger lengthLeft = [textView offsetFromPosition:beginning toPosition:selectedTextRange.start];
            NSRange leftRange = NSMakeRange(locationLeft, lengthLeft);
            NSMutableAttributedString *mutableAttributedString = [textView.attributedText mutableCopy];
            NSAttributedString *leftAttributedString = [mutableAttributedString attributedSubstringFromRange:leftRange];
            NSString *leftRawText = [self.view getRawTextInAttributedString:leftAttributedString];
            
            const NSInteger locationRight = [textView offsetFromPosition:beginning toPosition:selectedTextRange.start];
            const NSInteger lengthRight = [textView offsetFromPosition:selectedTextRange.start toPosition:ending];
            NSRange rightRange = NSMakeRange(locationRight, lengthRight);
            NSAttributedString *rightAttributedString = [mutableAttributedString attributedSubstringFromRange:rightRange];
            NSString *rightRawText = [self.view getRawTextInAttributedString:rightAttributedString];
            
            NSString *text = [NSString stringWithFormat:@"%@%@", leftRawText, rightRawText];
            textView.text = text;
            cursorPosition = leftRawText.length;
            cursorPositionOfInputEvent = cursorPosition;
            cursorPositionAfterLengthFilter = cursorPosition;
        }
        
        // length filter
        if (self.maxLength > 0 && textView.text.length > self.maxLength) {
            NSString* newContent;
            // The first half of the reserved length "self.maxLength - (textView.text.length - cursorPosition)"
            NSInteger availableLength = self.maxLength - ((NSInteger)textView.text.length - cursorPosition);
            NSRange firstHalfRangeAfterLengthFilter = NSMakeRange(0, availableLength > 0 ? availableLength : 0);
            // rangeOfComposedCharacterSequencesForRange will transfroming 0 character range into 1 character range
            NSRange newChangedRange = availableLength > 0 ? [textView.text rangeOfComposedCharacterSequencesForRange:firstHalfRangeAfterLengthFilter] : NSMakeRange(0, 0);
            // We need to find and filter emoji within the scope of newChangeRange.
            // Simple filtering is not feasible because the combined emoji is too long.
            NSMutableString* emojiFilteredText = [NSMutableString stringWithString:[textView.text substringWithRange:newChangedRange]];
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
                        if (matchRange.location > cursorPosition) {
                            break;
                        }
                        if (matchRange.location + matchRange.length > firstHalfRangeAfterLengthFilter.length) {
                            emojiFilteredText = [[emojiFilteredText substringToIndex:matchRange.location > firstHalfRangeAfterLengthFilter.length ? firstHalfRangeAfterLengthFilter.length : matchRange.location] mutableCopy];
                            break;
                        }
                    }
                }
            }
            // The new emoji may be failed to filter, simply make up for it
            NSRange emojiFilteredRange = NSMakeRange(0, emojiFilteredText.length);

            // If we miss some emojis in the regular rules for some reason, then we need to make up for it.
            if (emojiFilteredRange.length == firstHalfRangeAfterLengthFilter.length + 1 && emojiFilteredRange.length >= 2) {
                emojiFilteredRange = NSMakeRange(emojiFilteredRange.location, emojiFilteredRange.length - 2); //emoji
            }
            NSString* lengthFilteredText = [emojiFilteredText substringWithRange:emojiFilteredRange];

            cursorPositionAfterLengthFilter = (lengthFilteredText.length >= 0) ? lengthFilteredText.length : 0;
            NSString* content = textView.text;
            newContent = [NSString stringWithFormat:@"%@%@",
                                    lengthFilteredText,
                                    [content substringFromIndex:cursorPosition]];

            textView.text = newContent;
        }
        NSInteger textLengthAfterLengthFilter = textView.text.length;

        // input filter
        NSMutableString* filteredText = [NSMutableString stringWithString:textView.text];
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
                textView.text = filteredText;
            }
        }

        /* Why do we need to recalculate the cursor position here?
         * Because setText in UITextField will place cursor at the end!!!
         * So we need calc a new cursor position after type and customRegex filter has deleted some text.
         */
        NSInteger textLengthAfterOtherFilter = textView.text.length;
        NSInteger lengthOfCursorPositionShouldBackward = textLengthAfterLengthFilter - textLengthAfterOtherFilter;
        NSInteger cursorPositionAfterFilters = cursorPositionAfterLengthFilter - lengthOfCursorPositionShouldBackward;
        
        if (self.mLetterSpacing != 0) {
            NSMutableAttributedString *newAttributedText = [textView.attributedText mutableCopy];
            [newAttributedText addAttribute:NSKernAttributeName value:@(self.mLetterSpacing) range:NSMakeRange(0, textView.text.length)];
            textView.attributedText = newAttributedText;
        }
        
        // This value should not be subtracted from offset. For the rawText obtained by the front end, the cursor is at this position!
        cursorPositionOfInputEvent = cursorPositionAfterFilters;

        // iOS replacement is a placeholder of length 1 instead of the rawText. So when processing the text you need to convert it to rawText
        if (self.richTextFormater != nil) {
            NSError *error = NULL;
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(\\[)([^\\[\\]]+)(])" options:NSRegularExpressionCaseInsensitive error:&error];
            NSArray<NSTextCheckingResult *> *result = [regex matchesInString:[textView.attributedText string] options:0 range:NSMakeRange(0, textView.attributedText.length)];
            __block NSInteger offset = 0;
            [result enumerateObjectsUsingBlock:^(NSTextCheckingResult * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (obj.range.location < cursorPositionAfterFilters) {
                    offset += (obj.range.length - LynxInputTextAttachmentToken.length);
                }
            }];
            // Since there is a text replacement here, we need to subtract the offset when we set the cursor position
            cursorPositionAfterFilters -= offset;

            NSMutableAttributedString *text = [[NSMutableAttributedString alloc] init];
            text = (NSMutableAttributedString *)[self.richTextFormater formateRawText:((NSString *)(textView.attributedText)) defaultAttibutes:((NSDictionary<NSAttributedStringKey , id> *)(textView.typingAttributes))];
            textView.attributedText = text;
        }
        
        // set new cursor postion
        UITextPosition* newCursorPosition = [textView positionFromPosition:beginning offset:cursorPositionAfterFilters];
        textView.selectedTextRange = [textView textRangeFromPosition:newCursorPosition toPosition:newCursorPosition];

        isComposing = 0;
        
        _sourceLength = 0;
    }
    
    if ((!position || !selectedRange) || _mSendComposingInputEvent) {
        if (!self.mIsChangeFromLynx) {
            NSString *value = textView.text ?: @"";
            if (_richTextFormater != nil) {
                value = [self.view getRawText];
            }
            NSDictionary *detail = @{
                @"value" : value,
                @"textLength": @(value.length),
                @"isComposing": @(isComposing),
                @"cursor": @(cursorPositionOfInputEvent)
            };
            [self emitEvent:@"input" detail:detail];
        }
        if (self.mIsChangeFromLynx) {
            self.mIsChangeFromLynx = NO;
        }
    }

    [self.view showOrHidePlaceHolder];
    [self applyAutoHeight];
}

- (CGFloat)textHeight {
    CGSize sizeFitsText = CGSizeZero;
    CGSize sizeFitsPlaceHolder = CGSizeZero;
    if (_iosAutoHeightNewer) {
        if ([self.view text].length <= 0) {
            // Directly returns the lineHeight to fit the cursor
            sizeFitsText = CGSizeMake(_mWidth, [[self.view font] lineHeight]);
        } else {
            NSAttributedString *text = [self.view attributedText];
            sizeFitsText = [BDXLynxInputUtils getAttributedStringSize:text constraints:CGSizeMake(_mWidth, CGFLOAT_MAX)];
        }
        
        if ([self.view.placeHolderTextView text].length > 0) {
            NSAttributedString *placeholder = [self.view.placeHolderTextView attributedText];
            sizeFitsPlaceHolder = [BDXLynxInputUtils getAttributedStringSize:placeholder constraints:CGSizeMake(_mWidth, CGFLOAT_MAX)];
        }
    } else {
        /* onCreate _mWidth is 0, and the result of sizeFitsText is wrong.
        * So should call setNeedsLayout when width is not 0. (assume that width in style is not 0
        */
        CGSize intrinsicTextHeight = CGSizeMake(_mWidth, CGFLOAT_MAX);
        sizeFitsText = [self.view sizeThatFits:intrinsicTextHeight];
        sizeFitsPlaceHolder = [self.view.placeHolderTextView sizeThatFits:intrinsicTextHeight];
    }

    return MAX(sizeFitsText.height, sizeFitsPlaceHolder.height) - self.padding.top - self.padding.bottom;
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

- (void)onFontFaceLoad {
    if (_mFontFamilyName != nil) {
        [self setFont];
    }
    
    if ([self.view mPlaceholderFontFamilyName] != nil) {
        [self.view setFontFaceContext:self.context.fontFaceContext];
        [self.view refreshPlaceHolderFont];
    }
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

