//
//  BDXLynxRichTextStyle.h
//  BDXElement
//
//  Created by li keliang on 2020/6/8.
//

#import <Foundation/Foundation.h>
#import <Mantle/MTLModel.h>
#import "BDXRichTextFormater.h"
#import <Lynx/LynxCSSType.h>

#import <YYText/YYTextLayout.h>
#import <YYText/YYLabel.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const BDXLynxRichTextTraitsAttributeKey;
extern NSAttributedStringKey const BDXLynxInlineElementSignKey;

typedef NS_ENUM(NSInteger, BDXLynxRichTextTruncatingMode) {
    BDXLynxRichTextTruncatingHead = NSLineBreakByTruncatingHead,
    BDXLynxRichTextTruncatingTail = NSLineBreakByTruncatingTail,
    BDXLynxRichTextTruncatingMiddle = NSLineBreakByTruncatingMiddle,
    BDXLynxRichTextTruncatingClip = NSLineBreakByClipping
};

@class BDXLynxTextLayoutModel;

@interface BDXLynxRichTextStyle : MTLModel

@property (nonatomic, strong) NSMutableDictionary<NSAttributedStringKey, id> *defaultAttriutes;

@property (nonatomic) NSUInteger numberOfLines;

@property (nonatomic) BDXLynxRichTextTruncatingMode truncatingMode;

@property (nonatomic, strong, nullable) id<BDXRichTextFormater> richTextFormater;

@property (nonatomic, strong, readonly) NSMutableArray<NSAttributedString *> *attributeTexts;

@property (nonatomic, strong, readonly) NSMutableAttributedString *ultimateAttributedString;

@property (nonatomic, strong, nullable) NSAttributedString *truncationAttributeString;

@property(nonatomic, assign) CGFloat fontSize;

@property(nonatomic, assign) CGFloat fontWeight;

@property(nonatomic, assign) LynxFontStyleType fontStyle;

@property(nonatomic, nullable) NSString* fontFamily;

@property(nonatomic, assign) BOOL enableTextLanguageAlignment;

@property(nonatomic, assign) CGFloat textStrokeWidth;
@property(nonatomic, strong) UIColor* textStrokeColor;

@property (nonatomic, strong) BDXLynxTextLayoutModel *textModel;

- (void)appendAttributeText:(NSAttributedString *)attributeText;

- (void)updateTextStyle:(BDXLynxRichTextStyle *)textStyle;

@end

@interface BDXLynxRichTextStyle (DefaultAttriutes)

@property (nonatomic) UIFont    *font;

@property (nonatomic) UIColor   *textColor;

@property (nonatomic, nullable) UIColor *backgroundColor;

@property (nonatomic) CGFloat letterSpacing;

@property (nonatomic) LynxTextDecorationType textDecoration;

@property (nonatomic, nullable) NSShadow* textShadow;

@property (nonatomic) NSParagraphStyle *paragraphStyle;

@property (nonatomic) BOOL noTrim;

@end

@interface BDXLynxTextLayoutModel : NSObject

@property (nonatomic, strong) YYTextLayout *textLayout;
@property (nonatomic, strong) NSAttributedString *truncationToken;

+ (instancetype)createTextModelWithStyle:(BDXLynxRichTextStyle *)textStyle;

- (void)createTruncationToken:(NSAttributedString *)truncationAttributeString;

- (void)createLayoutWithContainerSize:(CGSize)size;

- (YYLabel *)truncationLabel;

@end

NS_ASSUME_NONNULL_END
