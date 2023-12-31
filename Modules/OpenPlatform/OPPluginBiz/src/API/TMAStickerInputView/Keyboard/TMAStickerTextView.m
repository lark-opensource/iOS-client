//
//  TMAStickerTextView.m
//  TMAStickerKeyboard
//
//  Created by houjihu on 2018/8/19.
//  Copyright © 2018年 ZAKER. All rights reserved.
//

#import "TMAStickerTextView.h"
#import "TMAStickerDataManager.h"
#import <ECOInfra/NSString+BDPExtension.h>
#import "NSAttributedString+TMASticker.h"
#import <OPFoundation/OPFoundation-Swift.h>
#import <OPFoundation/CGGeometry+EMA.h>

@interface TMAStickerTextView ()

@property (nonatomic, strong) UILabel *emaPlaceholderLabel;
@property (nonatomic, assign) BOOL returnKeyOpt;

@end

@implementation TMAStickerTextView

- (instancetype)initWithFrame:(CGRect)frame returnKeyOpt:(BOOL)returnKeyOpt {
    self = [super initWithFrame:frame];
    if (self) {
        _returnKeyOpt = returnKeyOpt;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tma_textDidChange:) name:UITextViewTextDidChangeNotification object:self];
    }
    return self;
}

- (void)setFont:(UIFont *)font {
    [super setFont:font];

    self.emaPlaceholderLabel.font = font;
}

- (void)setText:(NSString *)text {
    [super setText:text];
    [self showPlaceholderIfNeeded];
}

- (void)setAttributedText:(NSAttributedString *)attributedText {
    [super setAttributedText:attributedText];
    [self showPlaceholderIfNeeded];
}

- (UILabel *)emaPlaceholderLabel {
    if (!_emaPlaceholderLabel) {
        _emaPlaceholderLabel = [[UILabel alloc] init];
        _emaPlaceholderLabel.backgroundColor = [UIColor clearColor];
        _emaPlaceholderLabel.font = self.font;
        _emaPlaceholderLabel.hidden = YES;
        _emaPlaceholderLabel.numberOfLines = 0;
        [self addSubview:_emaPlaceholderLabel];
    }

    return _emaPlaceholderLabel;
}

- (void)setEmaPlaceholderColor:(UIColor *)placeholderColor {
    self.emaPlaceholderLabel.textColor = placeholderColor;
}

- (UIColor *)emaPlaceholderColor {
    return self.emaPlaceholderLabel.textColor;
}

- (void)setPlaceholderStr:(NSString *)placeholder {
    self.emaPlaceholderLabel.text = placeholder;
    [self setNeedsLayout];
}

- (NSString *)placeholderStr {
    return self.emaPlaceholderLabel.text;
}

- (void)showPlaceholderIfNeeded {
    if ([self shouldShowPlaceholder]) {
        [self showPlaceholder];
    } else {
        [self hidePlaceholder];
    }
}

- (BOOL)shouldShowPlaceholder {
    if (self.text.length == 0 && self.placeholderStr.length > 0) {
        return YES;
    }

    return NO;
}

- (void)showPlaceholder {
    self.emaPlaceholderLabel.hidden = NO;
}

- (void)hidePlaceholder {
    self.emaPlaceholderLabel.hidden = YES;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    [self showPlaceholderIfNeeded];
    self.emaPlaceholderLabel.frame = [self placeholderFrame];
    [self sendSubviewToBack:self.emaPlaceholderLabel];
}

- (CGSize)placeholderFitSize {
    UIEdgeInsets insets = [self retainedContentInsets];
    CGRect bounds = EMARectInsetEdges(self.bounds, insets);
    CGSize placeholderSize = [self.placeholderStr tma_sizeForFont:self.emaPlaceholderLabel.font size:CGSizeMake(bounds.size.width, CGFLOAT_MAX) mode:NSLineBreakByCharWrapping];
    return placeholderSize;
}

- (CGRect)placeholderFrame {
    CGSize placeholderFitSize = [self placeholderFitSize];
    CGRect caretRect = [self caretRectForPosition:self.beginningOfDocument];

    CGRect frame;
    frame.size = placeholderFitSize;
    frame.size.height = MAX([self textRectForContent].size.height, placeholderFitSize.height);
    frame.origin.x = caretRect.origin.x;
    frame.origin.y = caretRect.origin.y;
    return frame;
}

- (UIEdgeInsets)retainedContentInsets {
    return UIEdgeInsetsMake(8, 4, 8, 4);
}

- (void)tma_textDidChange:(NSNotification *)notif {
    [self showPlaceholderIfNeeded];
}

- (CGRect)textRectForContent {
    NSTextContainer *container = self.textContainer;
    NSLayoutManager *layoutManager = container.layoutManager;
    CGRect textRect = [layoutManager usedRectForTextContainer:container];
    return textRect;
}

- (CGRect)verticalCenterContentSizeToFit {
    [self showPlaceholderIfNeeded];
    CGRect textRect = [self textRectForContent];
    CGSize placeholderFitSize = [self placeholderFitSize];
    if (!self.emaPlaceholderLabel.hidden) {
        textRect.size.height = MAX(textRect.size.height, placeholderFitSize.height);
    }
    UIEdgeInsets inset = self.textContainerInset;
    CGRect rect = textRect;
    rect.size.width += inset.left + inset.right;
    rect.size.height += inset.top + inset.bottom;
    return rect;
}

- (void)updateEmptyCharaterIfNeeded {
    if (!self.enablesReturnKeyAutomatically || !self.returnKeyOpt) {
        return;
    }
    
    if (self.attributedText.length <= 0 && self.hasPicture) {
        self.attributedText = [[NSAttributedString alloc] initWithString:kTMAStickerTextEmptyChar];
    } else {
        NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithAttributedString:self.attributedText];
        [attrStr.mutableString replaceOccurrencesOfString:kTMAStickerTextEmptyChar withString:@"" options:NSCaseInsensitiveSearch range:attrStr.tma_rangeOfAll];
        self.attributedText = attrStr;
    }
}

#pragma mark - override

- (void)cut:(id)sender {
    NSString *string = [self.attributedText tma_plainTextForRange:self.selectedRange];
    if (string.length) {
        [SCPasteboardOCBridge setGeneralWithToken:OPSensitivityEntryTokenTMAStickerTextViewCut string: string];
        NSRange selectedRange = self.selectedRange;
        NSMutableAttributedString *attributeContent = [[NSMutableAttributedString alloc] initWithAttributedString:self.attributedText];
        [attributeContent replaceCharactersInRange:self.selectedRange withString:@""];
        self.attributedText = attributeContent;
        self.selectedRange = NSMakeRange(selectedRange.location, 0);

        if (self.delegate && [self.delegate respondsToSelector:@selector(textViewDidChange:)]) {
            [self.delegate textViewDidChange:self];
        }
    }
}

- (void)copy:(id)sender {
    NSString *string = [self.attributedText tma_plainTextForRange:self.selectedRange];
    if (string.length) {
        [SCPasteboardOCBridge setGeneralWithToken:OPSensitivityEntryTokenTMAStickerTextViewCopy string: string];
    }
}

- (void)setHasPicture:(BOOL)hasPicture {
    _hasPicture = hasPicture;
    [self updateEmptyCharaterIfNeeded];
}

@end
