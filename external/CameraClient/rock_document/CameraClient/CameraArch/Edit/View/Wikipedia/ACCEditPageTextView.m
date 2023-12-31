//
//  ACCEditPageTextView.m
//  CameraClient
//
//  Created by resober on 2020/3/2.
//

#import "ACCEditPageTextView.h"
#import <CreativeKit/ACCMacros.h>
#import <UITextView+Placeholder/UITextView+Placeholder.h>
#import <CreativeKit/ACCLanguageProtocol.h>

@interface ACCEditPageTextView() <UITextViewDelegate>
/// update `lastChangedRange` and  `replacementText` every time invoked `shouldChangeTextInRange:replacementText:`
@property (nonatomic, assign) NSRange currChangedRange;
@property (nonatomic, strong) NSString *currReplacementText;
@property (nonatomic, assign) NSInteger lastMarkedRangeOffset;
@property (nonatomic, assign) BOOL isProcessingDelete;


@end

@implementation ACCEditPageTextView

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame textContainer:(NSTextContainer *)textContainer {
    self = [super initWithFrame:frame textContainer:textContainer];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.delegate = self;
    self.layer.shadowColor = UIColor.blackColor.CGColor;
    self.layer.shadowRadius = 1.0;
    self.layer.shadowOpacity = 0.15;
    self.layer.shadowOffset = CGSizeMake(0, 1);
}

- (BOOL)hasVisibleTexts {
    __block NSString *str = self.text;
    NSArray<NSString *> *ctrlString = @[@"\b", @"\f", @"\n" , @"\r", @"\t"];
    [ctrlString enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        str = [str stringByReplacingOccurrencesOfString:obj withString:@""];
    }];
    return str.length > 0;
}

#pragma mark - Cover Text
- (void)setForCoverText:(BOOL)forCoverText
{
    if (forCoverText) {
        self.placeholder = ACCLocalizedCurrentString(@"postpage_coverselect_entertext");
        self.placeholderColor = ACCUIColorFromRGBA(0xffffff, 0.7);
    }
    _forCoverText = forCoverText;
}

- (CGSize)sizeThatFits:(CGSize)size
{
    if (self.forCoverText && (self.text.length == 0 && !self.placeholderTextView.hidden)) {
        return [self.placeholderTextView sizeThatFits:size];
    }
    return [super sizeThatFits:size];
}

- (BOOL)becomeFirstResponder
{
    BOOL superResult = [super becomeFirstResponder];
    if (self.forCoverText && superResult) {
        self.placeholderTextView.hidden = YES;
    }
    return superResult;
}

- (BOOL)resignFirstResponder
{
    BOOL superResult = [super resignFirstResponder];
    if (self.forCoverText && superResult) {
        self.placeholderTextView.hidden = YES;
    }
    return superResult;
}

#pragma mark - UITextViewDelegate Responding to Editing Notifications

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    if ([self.acc_delegate conformsToProtocol:@protocol(ACCTextViewDelegate) ] && [self.acc_delegate respondsToSelector:@selector(textViewShouldBeginEditing:)]) {
        return [self.acc_delegate textViewShouldBeginEditing:textView];
    }
    return YES;
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    if ([self.acc_delegate conformsToProtocol:@protocol(ACCTextViewDelegate) ] && [self.acc_delegate respondsToSelector:@selector(textViewDidBeginEditing:)]) {
        [self.acc_delegate textViewDidBeginEditing:textView];
    }
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
    if ([self.acc_delegate conformsToProtocol:@protocol(ACCTextViewDelegate) ] && [self.acc_delegate respondsToSelector:@selector(textViewShouldEndEditing:)]) {
        return [self.acc_delegate textViewShouldEndEditing:textView];
    }
    return YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    if ([self.acc_delegate conformsToProtocol:@protocol(ACCTextViewDelegate) ] && [self.acc_delegate respondsToSelector:@selector(textViewDidEndEditing:)]) {
        [self.acc_delegate textViewDidEndEditing:textView];
    }
}

#pragma mark - UITextViewDelegate Responding to Text Changes

/// @discussion: when user delete a character in text view, then will call
/// `shouldChangeTextInRange:replacementText`
/// `textViewDidChangeSelection:`
/// `textViewDidChange:`
/// in turn.
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([self.acc_delegate conformsToProtocol:@protocol(ACCTextViewDelegate) ] && [self.acc_delegate respondsToSelector:@selector(textView:shouldChangeTextInRange:replacementText:)]) {
        BOOL willChange = [self.acc_delegate textView:textView shouldChangeTextInRange:range replacementText:text];
        // fix Wikipedia Anchor Model
        if (willChange) {
            self.currChangedRange = range;
            self.currReplacementText = text;
            self.isProcessingDelete = text.length == 0;
        }
        return willChange;
    }
    self.currChangedRange = range;
    self.currReplacementText = text;
    self.isProcessingDelete = text.length == 0;
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
    if ([self.acc_delegate conformsToProtocol:@protocol(ACCTextViewDelegate) ] && [self.acc_delegate respondsToSelector:@selector(textViewDidChange:)]) {
        [self.acc_delegate textViewDidChange:textView];
    }
    self.isProcessingDelete = NO;
    self.currReplacementText = @"";
}

#pragma mark - UITextViewDelegate Responding to Selection Changes

- (void)textViewDidChangeSelection:(UITextView *)textView {
    if ([self.acc_delegate conformsToProtocol:@protocol(ACCTextViewDelegate) ] && [self.acc_delegate respondsToSelector:@selector(textViewDidChangeSelection:)]) {
        [self.acc_delegate textViewDidChangeSelection:textView];
    }
    UITextRange *markedRange = self.markedTextRange;
    NSInteger offset = [self offsetFromPosition:markedRange.start toPosition:markedRange.end];
    if (self.isProcessingDelete || offset != 0) {
        // offset != 0 means there are candidates in makedRange.
        return;
    }
}

#pragma mark - UITextViewDelegate Interacting with Text Data

- (BOOL)textView:(UITextView *)textView shouldInteractWithTextAttachment:(NSTextAttachment *)textAttachment inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction  API_AVAILABLE(ios(10.0)){
    if ([self.acc_delegate conformsToProtocol:@protocol(ACCTextViewDelegate) ] && [self.acc_delegate respondsToSelector:@selector(textView:shouldInteractWithTextAttachment:inRange:interaction:)]) {
        return [self.acc_delegate textView:textView shouldInteractWithTextAttachment:textAttachment inRange:characterRange interaction:interaction];
    }
    return NO;
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithTextAttachment:(NSTextAttachment *)textAttachment inRange:(NSRange)characterRange {
    if ([self.acc_delegate conformsToProtocol:@protocol(ACCTextViewDelegate) ] && [self.acc_delegate respondsToSelector:@selector(textView:shouldInteractWithTextAttachment:inRange:)]) {
        return [self.acc_delegate textView:textView shouldInteractWithTextAttachment:textAttachment inRange:characterRange];
    }
    return NO;
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction  API_AVAILABLE(ios(10.0)){
    if ([self.acc_delegate conformsToProtocol:@protocol(ACCTextViewDelegate) ] && [self.acc_delegate respondsToSelector:@selector(textView:shouldInteractWithURL:inRange:)]) {
        return [self.acc_delegate textView:textView shouldInteractWithURL:URL inRange:characterRange];
    }
    return NO;
}


- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange {
    if ([self.acc_delegate conformsToProtocol:@protocol(ACCTextViewDelegate) ] && [self.acc_delegate respondsToSelector:@selector(textView:shouldInteractWithURL:inRange:)]) {
        return [self.acc_delegate textView:textView shouldInteractWithURL:URL inRange:characterRange];
    }
    return NO;
}

@end
