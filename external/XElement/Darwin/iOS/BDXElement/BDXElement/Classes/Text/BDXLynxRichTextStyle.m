//
//  BDXLynxRichTextStyle.m
//  BDXElement
//
//  Created by li keliang on 2020/6/8.
//

#import "BDXLynxRichTextStyle.h"
#import <Lynx/LynxTextUtils.h>
#import <YYText/NSAttributedString+YYText.h>
#import <YYText/YYLabel.h>
#import <ByteDanceKit/ByteDanceKit.h>

NSString * const BDXLynxRichTextTraitsAttributeKey = @"BDXLynxRichTextTraitsAttributeKey";
static NSString * const BDXLynxRichTextNoTrimAttributeKey = @"BDXLynxRichTextNoTrimAttributeKey";
static CGFloat const kLynxDefaultFontSize = 14;

NSAttributedStringKey const BDXLynxInlineElementSignKey = @"BDXLynxInlineElementSignKey";

@interface BDXLynxRichTextStyle()

@property (nonatomic, strong) NSMutableArray<NSAttributedString *> *attributeTexts;

@property (nonatomic, strong) NSMutableAttributedString *ultimateAttributedString;

@property (nonatomic, strong) UIColor *textColor;

@end

@implementation BDXLynxRichTextStyle

@synthesize textColor = _textColor;

- (instancetype)init
{
    self = [super init];
    if (self) {
        _fontSize = kLynxDefaultFontSize;
        _fontWeight = UIFontWeightRegular;
        _fontStyle = LynxFontStyleNormal;
        _fontFamily = nil;
        _attributeTexts = [NSMutableArray new];
        _defaultAttriutes = [[NSMutableDictionary alloc] initWithDictionary:@{
            NSFontAttributeName : [UIFont systemFontOfSize:14.f],
            NSForegroundColorAttributeName : [UIColor blackColor]
        }];
        _numberOfLines = 0;
        _textStrokeWidth = 0;
    }
    return self;
}

- (void)appendAttributeText:(NSAttributedString *)attributeText
{
    @synchronized (_attributeTexts) {
        [_attributeTexts addObject:attributeText];
        _ultimateAttributedString = nil;
    }
}

- (void)updateTextStyle:(BDXLynxRichTextStyle *)textStyle {
    if (_textColor == nil) {
        self.textColor = textStyle.textColor;
    }
}

#pragma mark - Accessors

- (NSMutableAttributedString *)ultimateAttributedString
{
    if (!_ultimateAttributedString) {
        NSMutableAttributedString *attributedString = [NSMutableAttributedString new];
        [self.attributeTexts enumerateObjectsUsingBlock:^(NSAttributedString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [attributedString appendAttributedString:obj];
        }];
        
        if (self.defaultAttriutes[NSUnderlineStyleAttributeName]) {
            attributedString.yy_textUnderline = [YYTextDecoration decorationWithStyle:[self.defaultAttriutes[NSUnderlineStyleAttributeName] integerValue]];
        } else if (self.defaultAttriutes[NSStrikethroughStyleAttributeName]) {
            attributedString.yy_textStrikethrough = [YYTextDecoration decorationWithStyle:[self.defaultAttriutes[NSStrikethroughStyleAttributeName] integerValue]];
        }
        if (_textStrokeWidth > 0) {
            [attributedString yy_setStrokeColor:self.textStrokeColor range:NSMakeRange(0, attributedString.length)];
            [attributedString yy_setStrokeWidth:self.fontSize > 0 ? @(-self.textStrokeWidth/self.fontSize * 100) : @(-self.textStrokeWidth) range:NSMakeRange(0, attributedString.length)];
        }
        
        [attributedString addAttribute:NSParagraphStyleAttributeName value:self.paragraphStyle range:NSMakeRange(0, attributedString.length)];

        [LynxTextUtils applyNaturalAlignmentAccordingToTextLanguage:attributedString refactor:self.enableTextLanguageAlignment];

        _ultimateAttributedString = attributedString;
    }
    return _ultimateAttributedString;
}

@end


@implementation BDXLynxRichTextStyle (DefaultAttriutes)

- (void)setFont:(UIFont *)font
{
    @synchronized (_defaultAttriutes) {
        _defaultAttriutes[NSFontAttributeName] = font;
    }
}

- (UIFont *)font
{
    @synchronized (_defaultAttriutes) {
        return _defaultAttriutes[NSFontAttributeName];
    }
}

- (void)setTextColor:(UIColor *)textColor
{
    @synchronized (_defaultAttriutes) {
        _textColor = textColor;
        _defaultAttriutes[NSForegroundColorAttributeName] = textColor;
    }
}

- (UIColor *)textColor
{
    @synchronized (_defaultAttriutes) {
        return _defaultAttriutes[NSForegroundColorAttributeName];
    }
}

- (UIColor *)backgroundColor
{
    @synchronized (_defaultAttriutes) {
        return _defaultAttriutes[NSBackgroundColorAttributeName];
    }
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    @synchronized (_defaultAttriutes) {
        _defaultAttriutes[NSBackgroundColorAttributeName] = backgroundColor;
    }
}

- (void)setLetterSpacing:(CGFloat)letterSpacing
{
    @synchronized (_defaultAttriutes) {
        _defaultAttriutes[NSKernAttributeName] = @(letterSpacing);
    }
}

- (CGFloat)letterSpacing
{
    @synchronized (_defaultAttriutes) {
        return [_defaultAttriutes[NSKernAttributeName] floatValue];
    }
}

- (void)setTextDecoration:(LynxTextDecorationType)textDecoration
{
    @synchronized (_defaultAttriutes) {
        if (textDecoration & LynxTextDecorationLineThrough) {
          _defaultAttriutes[NSStrikethroughStyleAttributeName] = @(NSUnderlineStyleSingle);
        }
        if (textDecoration & LynxTextDecorationUnderLine) {
          _defaultAttriutes[NSUnderlineStyleAttributeName] = @(NSUnderlineStyleSingle);
        }
    }
}

- (LynxTextDecorationType)textDecoration
{
    @synchronized (_defaultAttriutes) {
        if ([_defaultAttriutes[NSUnderlineStyleAttributeName] intValue] == NSUnderlineStyleSingle) {
            return LynxTextDecorationUnderLine;
        } else if ([_defaultAttriutes[NSStrikethroughStyleAttributeName] intValue] == NSUnderlineStyleSingle) {
            return LynxTextDecorationLineThrough;
        }
        return LynxTextDecorationNone;
    }
}

- (void)setTextShadow:(NSShadow *)textShadow
{
    @synchronized (_defaultAttriutes) {
        _defaultAttriutes[NSShadowAttributeName] = textShadow;
    }
}

- (NSShadow *)textShadow
{
    @synchronized (_defaultAttriutes) {
        return _defaultAttriutes[NSShadowAttributeName];
    }
}

- (NSParagraphStyle *)paragraphStyle
{
    @synchronized (_defaultAttriutes) {
        NSMutableParagraphStyle *result = _defaultAttriutes[NSParagraphStyleAttributeName];
        if (!result) {
            result = _defaultAttriutes[NSParagraphStyleAttributeName] = [NSMutableParagraphStyle new];
        }
        return result;
    }
}

- (void)setParagraphStyle:(NSParagraphStyle *)paragraphStyle
{
    @synchronized (_defaultAttriutes) {
        _defaultAttriutes[NSParagraphStyleAttributeName] = paragraphStyle;
    }
}

- (void)setNoTrim:(BOOL)noTrim
{
    @synchronized (_defaultAttriutes) {
        _defaultAttriutes[BDXLynxRichTextNoTrimAttributeKey] = @(noTrim);
    }
}

- (BOOL)noTrim
{
    @synchronized (_defaultAttriutes) {
        return [_defaultAttriutes[BDXLynxRichTextNoTrimAttributeKey] boolValue];
    }
}

@end

@interface BDXLynxTextLayoutModel()

@property (nonatomic, weak) BDXLynxRichTextStyle *textStyle;

@end

@implementation BDXLynxTextLayoutModel {
    YYLabel * _truncationLabel;
}

+ (instancetype)createTextModelWithStyle:(BDXLynxRichTextStyle *)textStyle {
    BDXLynxTextLayoutModel *model = [BDXLynxTextLayoutModel new];
    model.textStyle = textStyle;
    return model;
}

- (void)createTruncationToken:(NSAttributedString *)truncationAttributeString {
    if (truncationAttributeString) {
        _truncationLabel = [YYLabel new];
        _truncationLabel.attributedText = truncationAttributeString;
        [_truncationLabel sizeToFit];
        _truncationToken = [NSAttributedString yy_attachmentStringWithContent:_truncationLabel contentMode:UIViewContentModeCenter attachmentSize:_truncationLabel.bounds.size alignToFont:self.textStyle.font alignment:YYTextVerticalAlignmentCenter];
    } else {
        _truncationLabel = nil;
    }
}

- (YYLabel *)truncationLabel {
    return _truncationLabel;
}

- (void)createLayoutWithContainerSize:(CGSize)size {
    YYTextContainer* container = [YYTextContainer containerWithSize:size];
    [self createTruncationToken:self.textStyle.truncationAttributeString];
    container.truncationToken = self.truncationToken;
    container.truncationType = YYTextTruncationTypeEnd;
    switch(self.textStyle.truncatingMode) {
        case BDXLynxRichTextTruncatingHead:
            container.truncationType = YYTextTruncationTypeStart; break;
        case BDXLynxRichTextTruncatingTail:
            container.truncationType = YYTextTruncationTypeEnd; break;
        case BDXLynxRichTextTruncatingMiddle:
            container.truncationType = YYTextTruncationTypeMiddle; break;
        case BDXLynxRichTextTruncatingClip:
            container.truncationType = YYTextTruncationTypeNone; break;
    }
    if (self.textStyle.numberOfLines != 0) {
        container.maximumNumberOfRows = self.textStyle.numberOfLines;
    }
    self.textLayout = [YYTextLayout layoutWithContainer:container text:self.textStyle.ultimateAttributedString];
}

@end
