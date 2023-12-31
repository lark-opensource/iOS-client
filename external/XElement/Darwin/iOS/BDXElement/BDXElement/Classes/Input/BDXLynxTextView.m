//
//  BDXLynxTextView.m
//  AWECloudCommand
//
//  Created by shenweizheng on 2020/5/11.
//

#import "BDXLynxTextView.h"
#import "BDXLynxInput.h"

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "BDXLynxInputBracketRichTextFormater.h"

@interface BDXLynxTextView() <LynxFontFaceObserver>

@end

@implementation BDXLynxTextView

@synthesize placeHolder = _placeHolder;
@synthesize placeHolderColor = _placeHolderColor;
@synthesize placeHolderFont = _placeHolderFont;

- (UIEditingInteractionConfiguration)editingInteractionConfiguration API_AVAILABLE(ios(13.0)){
    return UIEditingInteractionConfigurationNone;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _mTextAlignment = NSTextAlignmentLeft;
        _isCustomPlaceHolderFontSize = NO;
        _isCustomPlaceHolderFontWeight = NO;
        _mPlaceHolderFontSize = 14;
        _mPlaceHolderFontWeight = UIFontWeightRegular;
        _placeHolderColor = [UIColor colorWithRed:0.235 green:0.263 blue:0.235 alpha:0.3]; // [UIColor placeholderTextColor]
    }
    return self;
}

- (void)setTextAlignment:(NSTextAlignment)textAlignment {
    /* to cover bug:
     * sometimes UITextView's textAlignment will be nil(NSTextAlignmentLeft) unexpectedly
     */
    if (textAlignment != _mTextAlignment) {
        [super setTextAlignment:_mTextAlignment];
    } else {
        [super setTextAlignment:textAlignment];
    }
}

/* override caretRectForPosition to fix bug since iOS7:
 * If you are in the middle of the multiline text in UITextView and there is a newline after the caret,
 * the caret will appear in the left side of UITextView.
 */
- (CGRect)caretRectForPosition:(UITextPosition *)position {
    CGRect stupidAppleCaretRectForPosition = [super caretRectForPosition:position];
    NSRange selectedRange = [self selectedRange];
    NSRange rangeOfCaret = NSMakeRange(selectedRange.location + selectedRange.length, 0);

    /* there are two knowns situations:
     * 1. insert a new line in the mid of two lines
     * 2. delete pre line to blank before the new line inserted like above
     */
    if (rangeOfCaret.location > 0) {
        NSRange rangeOfCharBeforeCaret = NSMakeRange(rangeOfCaret.location - 1, 1);
        NSRange rangeOfCharAfterCaret = NSMakeRange(rangeOfCaret.location, 1);
        NSRange rangeOfText = NSMakeRange(0, self.text.length);
    
        if (NSLocationInRange(NSMaxRange(rangeOfCharBeforeCaret), rangeOfText) && NSLocationInRange(NSMaxRange(rangeOfCharAfterCaret), rangeOfText) &&
            [[self.text substringWithRange:rangeOfCharBeforeCaret] isEqualToString:@"\n"] && [[self.text substringWithRange:rangeOfCharAfterCaret] isEqualToString:@"\n"]) {
            // Make sure that the caret is before and after the \n
            return [self calcCorrectCaretRectFromSuperClassCaretRect:stupidAppleCaretRectForPosition];
        }
    } else if (rangeOfCaret.location == 0){
        NSRange rangeOfCharAfterCaret = NSMakeRange(rangeOfCaret.location, 1);
        NSRange rangeOfText = NSMakeRange(0, self.text.length);
    
        // Make sure that the caret is before the \n while caret is place in first location
        if (NSLocationInRange(NSMaxRange(rangeOfCharAfterCaret), rangeOfText) && [[self.text substringWithRange:rangeOfCharAfterCaret] isEqualToString:@"\n"]) {
            return [self calcCorrectCaretRectFromSuperClassCaretRect:stupidAppleCaretRectForPosition];
        }
    }

     return stupidAppleCaretRectForPosition;
}

- (CGRect)calcCorrectCaretRectFromSuperClassCaretRect:(CGRect) superClassCaretRect {
    CGRect newCaretRect = superClassCaretRect;
    if (self.textAlignment == NSTextAlignmentCenter) {
        CGFloat currentCenterXOfCaret = CGRectGetMidX(superClassCaretRect);
        CGFloat centerXOfCenteredCaret = CGRectGetMidX(self.bounds);
        CGFloat correction = centerXOfCenteredCaret - currentCenterXOfCaret;
        newCaretRect = CGRectOffset(superClassCaretRect, correction, 0);
    } else if (self.textAlignment == NSTextAlignmentRight) {
        CGFloat currentRightXOfCaret = CGRectGetMaxX(superClassCaretRect);
        CGFloat rightXOfRightCaret = CGRectGetMaxX(self.bounds);
        CGFloat correction = rightXOfRightCaret - currentRightXOfCaret;
        newCaretRect = CGRectOffset(superClassCaretRect, correction, 0);
    }

    return newCaretRect;
}

- (void)setPlaceHolder:(NSString *)placeHolderStr {
    
    if (![self.placeHolder isEqualToString:placeHolderStr]) {
        
        _placeHolder = placeHolderStr;
        
        if (!self.placeHolderTextView) {
            UITextView * placeHolderTextView = [[UITextView alloc] initWithFrame:UIEdgeInsetsInsetRect(CGRectZero, self.placeHolderEdgeInsets)];
            placeHolderTextView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
            placeHolderTextView.backgroundColor = [UIColor clearColor];
            placeHolderTextView.userInteractionEnabled = NO;
            placeHolderTextView.editable = NO;
            placeHolderTextView.font = self.placeHolderFont;
            placeHolderTextView.textColor = self.placeHolderColor;
            placeHolderTextView.textAlignment = self.textAlignment;
            // Default value is 5.0. UITextView(UIScrollView) did not set it to 0.
            placeHolderTextView.textContainer.lineFragmentPadding = 0;
            [self addSubview:placeHolderTextView];
            self.placeHolderTextView = placeHolderTextView;
        }
        
        self.placeHolderTextView.text = placeHolderStr;
        
        [self showOrHidePlaceHolder];
    }
}

- (void)setPlaceHolderColor:(UIColor *)placeHolderColor {
    if (![self.placeHolderColor isEqual:placeHolderColor]) {
        
        _placeHolderColor = placeHolderColor;
        
        if (self.placeHolderTextView) {
            self.placeHolderTextView.textColor = placeHolderColor;
        }
    }
}

- (void)refreshPlaceHolderFont {
    UIFont *placeHolderFont;
    if (_mPlaceholderFontFamilyName== nil || _fontFaceContext == nil) {
        placeHolderFont = [UIFont systemFontOfSize:_mPlaceHolderFontSize weight:_mPlaceHolderFontWeight];
    } else {
        LynxFontFaceContext* fontFaceContext = _fontFaceContext;
        placeHolderFont = [[LynxFontFaceManager sharedManager]
                    generateFontWithSize:_mPlaceHolderFontSize
                    weight:_mPlaceHolderFontWeight
                    style:LynxFontStyleNormal
                    fontFamilyName:_mPlaceholderFontFamilyName
                    fontFaceContext:fontFaceContext
                    fontFaceObserver:self];
    }
    if (![_placeHolderFont isEqual:placeHolderFont]) {
        _placeHolderFont = placeHolderFont;
        
        if (self.placeHolderTextView) {
            self.placeHolderTextView.font = placeHolderFont;
        }
    }
}

- (void)showOrHidePlaceHolder {
    if (self.placeHolderTextView) {
        self.placeHolderTextView.hidden = self.text.length == 0 ? NO : YES;
    }
}

- (void)syncPlaceHolderTextAligment {
    if (self.placeHolderTextView) {
        self.placeHolderTextView.textAlignment = self.textAlignment;
    }
}

- (void)syncPlaceHolderDirection:(NSInteger) directionType {
    if (self.placeHolderTextView) {
        UITextPosition *beginning = self.placeHolderTextView.beginningOfDocument;
        UITextPosition *ending = self.placeHolderTextView.endOfDocument;
        UITextRange *textRange = [self.placeHolderTextView textRangeFromPosition:beginning toPosition:ending];
        
        NSInteger textAlignment = [self.placeHolderTextView textAlignment];
        if (directionType == LynxDirectionNormal) {
            [self.placeHolderTextView setBaseWritingDirection:NSWritingDirectionNatural forRange:textRange];
        } else if (directionType == LynxDirectionRtl) {
            [self.placeHolderTextView setBaseWritingDirection:NSWritingDirectionRightToLeft forRange:textRange];
        } else if (directionType == LynxDirectionLtr) {
            [self.placeHolderTextView setBaseWritingDirection:NSWritingDirectionLeftToRight forRange:textRange];
        }
        [self.placeHolderTextView setTextAlignment:textAlignment];
    }
}

- (void)syncPlaceHolderLetterSpacing:(CGFloat)letterSpacing {
    if (self.placeHolderTextView) {
        NSMutableAttributedString *newAttributedText = [self.placeHolderTextView.attributedText mutableCopy];
        [newAttributedText addAttribute:NSKernAttributeName value:@(letterSpacing) range:NSMakeRange(0, self.placeHolderTextView.text.length)];
        self.placeHolderTextView.attributedText = newAttributedText;
    }
}

- (NSString *)getRawText {
    return [self getRawTextInAttributedString:self.attributedText];
}


- (NSString *)getRawTextInAttributedString:(NSAttributedString *)attributedString {
    // use emojiName to replace placeholder
    NSMutableAttributedString *mutableAttributedString = [attributedString mutableCopy];
    NSRange searchRange = NSMakeRange(0, mutableAttributedString.length);
    NSRange foundRange = NSMakeRange(0, 0);
    while (searchRange.location < mutableAttributedString.length) {
        searchRange.length = mutableAttributedString.length - searchRange.location;
        foundRange = [[mutableAttributedString string] rangeOfString:LynxInputTextAttachmentToken options:NSCaseInsensitiveSearch range:searchRange];
        if (foundRange.location != NSNotFound) {
            LynxTextareaAttachment *attachment = [mutableAttributedString attribute:NSAttachmentAttributeName atIndex:foundRange.location effectiveRange:nil];
            if ([attachment isMemberOfClass:LynxTextareaAttachment.class]) {
                NSString *imageName = [attachment getAttachmentName];
                searchRange.location = foundRange.location + imageName.length;
                [mutableAttributedString replaceCharactersInRange:foundRange withString:imageName];
            }
        } else {
            break;
        }
    }
    return [mutableAttributedString string];
}

// Rewrite the copy method to ensure that only rawText is obtained from textarea
- (void)copy:(id)sender {
    if (!_mEnableRichText) {
        [super copy:sender];
        return;
    }

    UIPasteboard *gpBoard = [UIPasteboard generalPasteboard];

    UITextRange *selectedTextRange = self.selectedTextRange;
    if (selectedTextRange.empty) {
        [super copy:sender];
        return;
    }
    UITextPosition* beginning = self.beginningOfDocument;
    const NSInteger location = [self offsetFromPosition:beginning toPosition:selectedTextRange.start];
    const NSInteger length = [self offsetFromPosition:selectedTextRange.start toPosition:selectedTextRange.end];
    NSRange selectedRange = NSMakeRange(location, length);
    NSMutableAttributedString *mutableAttributedString = [self.attributedText mutableCopy];
    NSAttributedString *selectedAttributedString = [mutableAttributedString attributedSubstringFromRange:selectedRange];
    NSString *selectedText = [self getRawTextInAttributedString:selectedAttributedString];
    if (selectedText == nil) {
        [super copy:sender];
    } else {
        [gpBoard setString:selectedText];
    }
}

// Rewrite the cut method to ensure that only rawText is obtained from textarea
- (void)cut:(id)sender {
    if (!_mEnableRichText) {
        [super cut:sender];
        return;
    }
    
    UITextRange *selectedTextRange = self.selectedTextRange;
    // 1. copy rawText
    [self copy:sender];
    
    // 2. remove selectedText
    UITextPosition* beginning = self.beginningOfDocument;
    const NSInteger location = [self offsetFromPosition:beginning toPosition:selectedTextRange.start];
    const NSInteger length = [self offsetFromPosition:selectedTextRange.start toPosition:selectedTextRange.end];
    NSRange selectedRange = NSMakeRange(location, length);
    NSMutableAttributedString *mutableAttributedString = [[NSMutableAttributedString alloc] initWithAttributedString:self.attributedText];
    [mutableAttributedString deleteCharactersInRange:selectedRange];
    self.attributedText = mutableAttributedString;
}

- (void)paste:(id)sender {
    if (!_mEnableRichText) {
        [super paste:sender];
        return;
    }
    
    // bug: Paste will modify cursor position once after textViewDidChanged
    [super paste:sender];
}

- (void)onFontFaceLoad {
    [self refreshPlaceHolderFont];
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
