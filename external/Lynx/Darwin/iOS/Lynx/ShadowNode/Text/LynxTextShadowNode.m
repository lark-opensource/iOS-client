// Copyright 2019 The Lynx Authors. All rights reserved.

#import "LynxTextShadowNode.h"
#import "LynxComponentRegistry.h"
#import "LynxNativeLayoutNode.h"
#import "LynxPropsProcessor.h"
#import "LynxRootUI.h"
#import "LynxTemplateRender.h"
#import "LynxTextRendererCache.h"
#import "LynxTextUtils.h"
#import "LynxTraceEvent.h"
#import "LynxTraceEventWrapper.h"

// This is an adaptaion for one of the bug of line spacing in TextKit that
// the last line will disappeare when both maxNumberOfLines and lineSpacing are set.
//
// FIXME(yxping): there still another bug that both height and lineSpacing are set,
// the last line in the visible area will disappeare.
@implementation LineSpacingAdaptation

- (BOOL)layoutManager:(NSLayoutManager *)layoutManager
    shouldBreakLineByWordBeforeCharacterAtIndex:(NSUInteger)charIndex {
  if (self.breakByChar) {
    return NO;
  } else {
    return YES;
  }
}

- (BOOL)layoutManager:(NSLayoutManager *)layoutManager
    shouldSetLineFragmentRect:(inout CGRect *)lineFragmentRect
         lineFragmentUsedRect:(inout CGRect *)lineFragmentUsedRect
               baselineOffset:(inout CGFloat *)baselineOffset
              inTextContainer:(NSTextContainer *)textContainer
                forGlyphRange:(NSRange)glyphRange {
  NSTextStorage *textStorage = layoutManager.textStorage;
  // When it returns YES, the layout manager uses the modified rects. Otherwise, it ignores the
  // rects returned from this method.
  BOOL isValid = YES;
  if (_enableLayoutRefactor) {
    __block CGFloat usedBaselinePosition = *baselineOffset;
    __block CGFloat usedLineRectHeight = lineFragmentRect->size.height;
    NSRange character_range = [layoutManager characterRangeForGlyphRange:glyphRange
                                                        actualGlyphRange:nil];

    // if set line-height, align the content in the center of line
    // if baseline is out of visual line rect, move the baseline
    if (_lineHeight != 0) {
      // center text in line
      usedBaselinePosition = _maxLineAscender + _halfLeading;
      if (_halfLeading < 0) {
        // baseline will be up if descender > 0
        if (_lineHeight - usedBaselinePosition < 0) {
          usedBaselinePosition = _lineHeight;
        }
        // baseline will be down if ascender < 0
        if (usedBaselinePosition < 0) {
          usedBaselinePosition = 0;
        }
      }

      // if inline-view or inline-image is lager than line-height, line-height will increase.
      [textStorage
          enumerateAttribute:NSAttachmentAttributeName
                     inRange:character_range
                     options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
                  usingBlock:^(NSTextAttachment *attachment, NSRange range, __unused BOOL *stop) {
                    if (attachment == nil) {
                      return;
                    }

                    CGRect bounds = attachment.bounds;
                    // bounds.origin.y is distance from attachment bottom to baseline
                    CGFloat attachmentTopToBaseline = bounds.size.height + bounds.origin.y;

                    NSRange attachmentRange;
                    id node = [textStorage attribute:LynxInlineViewAttributedStringKey
                                             atIndex:range.location
                                      effectiveRange:&attachmentRange];

                    if (node != nil) {
                      // modify line ascender
                      if (attachmentTopToBaseline > 0 &&
                          attachmentTopToBaseline > usedBaselinePosition) {
                        usedLineRectHeight += attachmentTopToBaseline - usedBaselinePosition;
                        usedBaselinePosition = attachmentTopToBaseline;
                      }
                      // modify line descender
                      if (bounds.origin.y < 0 &&
                          (-bounds.origin.y > usedLineRectHeight - usedBaselinePosition)) {
                        usedLineRectHeight +=
                            -usedLineRectHeight + usedBaselinePosition - bounds.origin.y;
                      }
                    }
                  }];
    }

    lineFragmentRect->size.height = usedLineRectHeight + _calculatedLineSpacing;
    lineFragmentUsedRect->size.height = usedLineRectHeight;
    *baselineOffset = usedBaselinePosition;
  } else {
    __block CGFloat maximumLineHeight = 0;
    [textStorage enumerateAttribute:NSFontAttributeName
                            inRange:NSMakeRange(0, textStorage.length)
                            options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
                         usingBlock:^(UIFont *font, NSRange range, __unused BOOL *stop) {
                           if (font) {
                             maximumLineHeight = MAX(maximumLineHeight, font.lineHeight);
                             // We are not traversing the paragraph attribute here because the
                             // maximumLineHeight are set to the same value if paragraph attribute
                             // exists.
                             NSParagraphStyle *paragraphStyle =
                                 [textStorage attribute:NSParagraphStyleAttributeName
                                                atIndex:range.location
                                         effectiveRange:nil];
                             if (paragraphStyle && paragraphStyle.maximumLineHeight > 0) {
                               maximumLineHeight =
                                   MIN(maximumLineHeight, paragraphStyle.maximumLineHeight);
                             }
                           }
                         }];
    CGRect usedRect = *lineFragmentUsedRect;
    usedRect.size.height = MAX(maximumLineHeight, usedRect.size.height);
    *lineFragmentUsedRect = usedRect;
    if (_adjustBaseLineOffsetForVerticalAlignCenter) {
      *baselineOffset = (*lineFragmentRect).size.height;
    }
    if (ABS(_calculatedLineSpacing) < FLT_EPSILON) {
      isValid = NO;
    } else {
      CGRect rect = *lineFragmentRect;
      // We add lineSpacing to lineFragmentRect instead of adding to lineFragmentUsedRect
      // to avoid last sentance have a extra lineSpacing pading.
      rect.size.height += _calculatedLineSpacing;
      *lineFragmentRect = rect;
    }
  }
  if (glyphRange.location == 0) {
    if (!_enableLayoutRefactor && _adjustBaseLineOffsetForVerticalAlignCenter) {
      _baseline = *baselineOffset - _baseLineOffsetForVerticalAlignCenter;
    } else {
      _baseline = *baselineOffset;
    }
  }
  return isValid;
}

- (CGFloat)layoutManager:(NSLayoutManager *)layoutManager
    lineSpacingAfterGlyphAtIndex:(NSUInteger)glyphIndex
    withProposedLineFragmentRect:(CGRect)rect {
  // Do not include lineSpacing in lineFragmentUsedRect to avoid last line disappearing
  return 0;
}

@end

// LynxTextIndent
@interface LynxTextIndent : NSObject

@property(nonatomic, assign) NSInteger type;
@property(nonatomic, assign) CGFloat value;

- (instancetype _Nullable)initWithValue:(NSArray *)value;

- (CGFloat)applyValue:(CGFloat)widthValue;

@end

@implementation LynxTextIndent

- (instancetype)initWithValue:(NSArray *)value {
  self = [super init];
  if (self) {
    self.value = [value[0] floatValue];
    self.type = [value[1] integerValue];
  }
  return self;
}

- (CGFloat)applyValue:(CGFloat)widthValue {
  return self.type == LynxPlatformLengthUnitNumber ? self.value : self.value * widthValue;
}

@end

// LynxTextShadowNode
@interface LynxTextShadowNode ()

@property(nonatomic) LynxTextRenderer *textRenderer;
@property(nonatomic) LineSpacingAdaptation *lineSpacingAdaptation;

@property(readwrite, nonatomic, assign) LynxTextOverflowType textOverflow;
@property(readwrite, nonatomic, assign) LynxOverflow overflow;
@property(readwrite, nonatomic, assign) LynxWhiteSpaceType whiteSpace;
@property(readwrite, nonatomic, assign) NSInteger maxLineNum;
@property(readwrite, nonatomic, assign) NSInteger maxTextLength;
@property(readwrite, nonatomic, assign) LynxVerticalAlign textVerticalAlign;
@property(readwrite, nonatomic) NSMutableAttributedString *attrString;
@property(readwrite, nonatomic, assign) BOOL enableTailColorConvert;
// text
@property(readwrite, nonatomic, assign) CGFloat maxAscender;
@property(readwrite, nonatomic, assign) CGFloat maxDescender;
// line, include inline-image and inline-view
@property(readwrite, nonatomic, assign) CGFloat maxLineAscender;
@property(readwrite, nonatomic, assign) CGFloat maxLineDescender;
@property(nonatomic, nonatomic, assign) CGFloat maxXHeight;
@property(nonatomic, nonatomic, assign) BOOL isCalcVerticalAlignValue;
@property(readwrite, nonatomic, strong, nullable) LynxTextIndent *textIndent;

@end

@implementation LynxTextShadowNode

#if LYNX_LAZY_LOAD
LYNX_LAZY_REGISTER_SHADOW_NODE("text")
#else
LYNX_REGISTER_SHADOW_NODE("text")
#endif

- (instancetype)initWithSign:(NSInteger)sign tagName:(NSString *)tagName {
  self = [super initWithSign:sign tagName:tagName];
  if (self) {
    _lineSpacingAdaptation = [LineSpacingAdaptation new];
    _maxTextLength = LynxNumberNotSet;
    _textVerticalAlign = LynxVerticalAlignDefault;
    _textIndent = nil;
  }
  return self;
}

- (void)adoptNativeLayoutNode:(int64_t)ptr {
  [self setCustomMeasureDelegate:self];
  [super adoptNativeLayoutNode:ptr];
}

- (BOOL)enableTextNonContiguousLayout {
  if (self.uiOwner.rootUI) {
    return [self.uiOwner.rootUI.lynxView enableTextNonContiguousLayout];
  } else {
    return [self.uiOwner.templateRender enableTextNonContiguousLayout];
  }
}

- (MeasureResult)measureWithMeasureParam:(MeasureParam *)param
                          MeasureContext:(MeasureContext *)ctx {
  LynxLayoutSpec *spec = [[LynxLayoutSpec alloc] initWithWidth:param.width
                                                        height:param.height
                                                     widthMode:param.widthMode
                                                    heightMode:param.heightMode
                                                  textOverflow:self.textOverflow
                                                      overflow:self.overflow
                                                    whiteSpace:self.whiteSpace
                                                    maxLineNum:self.maxLineNum
                                                 maxTextLength:self.maxTextLength
                                                     textStyle:self.textStyle
                                                   breakByChar:_lineSpacingAdaptation.breakByChar
                                        enableTailColorConvert:self.enableTailColorConvert];
  spec.enableTextRefactor = self.enableTextRefactor;
  spec.enableTextNonContiguousLayout = [self enableTextNonContiguousLayout];
  spec.enableNewClipMode = self.enableNewClipMode;
  spec.layoutManagerDelegate = _lineSpacingAdaptation;
  spec.verticalAlign = self.textVerticalAlign;

  __block float maxLineAscender = 0, maxLineDescender = 0;
  // layout native node.
  if (ctx != nil) {
    [self.attrString
        enumerateAttribute:LynxInlineViewAttributedStringKey
                   inRange:NSMakeRange(0, self.attrString.length)
                   options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
                usingBlock:^(LynxShadowNode *node, NSRange range, BOOL *_Nonnull stop) {
                  if (node == nil || ![node isKindOfClass:[LynxNativeLayoutNode class]]) {
                    return;
                  }

                  LynxNativeLayoutNode *child = (LynxNativeLayoutNode *)node;
                  MeasureParam *nParam = [[MeasureParam alloc] initWithWidth:param.width
                                                                   WidthMode:param.widthMode
                                                                      Height:param.height
                                                                  HeightMode:param.heightMode];
                  MeasureResult result = [child measureWithMeasureParam:nParam MeasureContext:ctx];

                  NSTextAttachment *attachment =
                      [self.attrString attribute:NSAttachmentAttributeName
                                         atIndex:range.location
                                  effectiveRange:nil];
                  CGFloat baselineOffset = 0.f;

                  if (self.enableTextRefactor) {
                    if (node.shadowNodeStyle.valign == LynxVerticalAlignBaseline) {
                      baselineOffset = result.baseline - result.size.height;
                    } else {
                      baselineOffset =
                          [self calcBaselineShiftOffset:node.shadowNodeStyle.valign
                                     verticalAlignValue:node.shadowNodeStyle.valignLength
                                           withAscender:result.size.height
                                          withDescender:0.f];
                    }
                    maxLineAscender = MAX(maxLineAscender, baselineOffset + result.size.height);
                    maxLineDescender = MIN(maxLineDescender, baselineOffset);
                  } else {
                    baselineOffset = attachment.bounds.origin.y;
                  }
                  [attachment setBounds:CGRectMake(attachment.bounds.origin.x, baselineOffset,
                                                   result.size.width, result.size.height)];
                }];
  }
  _maxLineAscender = MAX(_maxLineAscender, maxLineAscender);
  _maxLineDescender = MIN(_maxLineDescender, maxLineDescender);
  self.lineSpacingAdaptation.maxLineAscender = _maxLineAscender;
  self.lineSpacingAdaptation.maxLineDescender = _maxLineDescender;
  if (!isnan(self.textStyle.lineHeight)) {
    self.lineSpacingAdaptation.lineHeight = self.textStyle.lineHeight;
    self.lineSpacingAdaptation.halfLeading =
        (self.textStyle.lineHeight - _maxLineAscender + _maxLineDescender) * 0.5f;
  }

  self.textRenderer = [[LynxTextRendererCache cache] rendererWithString:[self.attrString copy]
                                                             layoutSpec:spec];
  self.textRenderer.selectionColor = self.textStyle.selectionColor;
  CGSize size = self.textRenderer.size;
  CGFloat letterSpacing = self.textStyle.letterSpacing;
  if (!isnan(letterSpacing) && letterSpacing < 0) {
    size.width -= letterSpacing;
  }
  [self dispatchLayoutEventWithLayout:self.textRenderer.layoutManager];

  MeasureResult result;
  result.size = size;
  result.baseline = self.textRenderer.baseline;

  return result;
}

- (BOOL)needsEventSet {
  return YES;
}

/*
 {
   lineCount: number;    //line count of display text
   lines: LineInfo[];    //contain line layout info
 }
 class LineInfo {
   start: number;        //the line start offset for text
   end: number;          //the line end offset for text
   ellipsisCount: number;//ellipsis count of the line. If larger than 0, truncate text in this line.
 }
 */
- (void)dispatchLayoutEventWithLayout:(NSLayoutManager *)layoutManager {
  if ([self.eventSet objectForKey:@"layout"] == nil) {
    return;
  }

  NSMutableDictionary *layoutInfo = [NSMutableDictionary new];
  NSMutableArray *lineInfo = [NSMutableArray new];

  __block NSInteger lineCount = 0;
  [layoutManager enumerateLineFragmentsForGlyphRange:NSMakeRange(0, self.attrString.length)
                                          usingBlock:^(CGRect rect, CGRect usedRect,
                                                       NSTextContainer *_Nonnull textContainer,
                                                       NSRange glyphRange, BOOL *_Nonnull stop) {
                                            lineCount++;
                                          }];

  __block NSInteger index = 0;
  [layoutManager
      enumerateLineFragmentsForGlyphRange:NSMakeRange(0, self.attrString.length)
                               usingBlock:^(CGRect rect, CGRect usedRect,
                                            NSTextContainer *_Nonnull textContainer,
                                            NSRange glyphRange, BOOL *_Nonnull stop) {
                                 NSMutableDictionary *info = [NSMutableDictionary new];
                                 [info setObject:@(glyphRange.location) forKey:@"start"];
                                 NSInteger ellipsisCount = 0;
                                 if (index == lineCount - 1) {
                                   NSRange truncatedRange = [layoutManager
                                       truncatedGlyphRangeInLineFragmentForGlyphAtIndex:
                                           glyphRange.location];
                                   ellipsisCount = truncatedRange.length;
                                 }

                                 [info setObject:@(glyphRange.location + glyphRange.length)
                                          forKey:@"end"];
                                 [info setObject:@(ellipsisCount) forKey:@"ellipsisCount"];

                                 [lineInfo addObject:info];

                                 index++;
                               }];

  [layoutInfo setObject:@(lineCount) forKey:@"lineCount"];
  [layoutInfo setObject:lineInfo forKey:@"lines"];

  LynxDetailEvent *event = [[LynxDetailEvent alloc] initWithName:@"layout"
                                                      targetSign:[self sign]
                                                          detail:layoutInfo];

  [self.uiOwner.uiContext.eventEmitter dispatchCustomEvent:event];
}

- (void)alignOneLine:(NSRange)characterRange
            lineRect:(CGRect)rect
       layoutManager:(NSLayoutManager *)layoutManager
       textContainer:(NSTextContainer *)textContainer
        AlignContext:(AlignContext *)ctx {
  if (characterRange.location + characterRange.length > self.attrString.length) {
    // Here the layout manager append ellipsis to text storage string.
    // Ignore those appended string when aligning inline view.
    if (self.attrString.length >= characterRange.location) {
      return;
    }
    characterRange.length = self.attrString.length - characterRange.location;
  }

  [self.attrString
      enumerateAttribute:LynxInlineViewAttributedStringKey
                 inRange:characterRange
                 options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
              usingBlock:^(LynxShadowNode *value, NSRange range, BOOL *_Nonnull stop) {
                if (value == nil || ![value isKindOfClass:[LynxNativeLayoutNode class]]) {
                  return;
                }

                NSTextAttachment *attachment = [self.attrString attribute:NSAttachmentAttributeName
                                                                  atIndex:range.location
                                                           effectiveRange:nil];
                if (attachment) {
                  CGFloat yOffsetToTop = 0;
                  NSRange glyphRange = [layoutManager glyphRangeForCharacterRange:range
                                                             actualCharacterRange:nil];
                  CGRect glyphRect = [layoutManager boundingRectForGlyphRange:glyphRange
                                                              inTextContainer:textContainer];

                  LynxNativeLayoutNode *child = (LynxNativeLayoutNode *)value;
                  CGFloat yPosition = [layoutManager locationForGlyphAtIndex:glyphRange.location].y;
                  yOffsetToTop = [self alignInlineNodeInVertical:child.shadowNodeStyle.valign
                                                  withLineHeight:rect.size.height
                                            withAttachmentHeight:attachment.bounds.size.height
                                         withAttachmentYPosition:yPosition];

                  AlignParam *nparam = [[AlignParam alloc] init];
                  if (self.enableTextRefactor) {
                    [nparam SetAlignOffsetWithLeft:glyphRect.origin.x + attachment.bounds.origin.x
                                               Top:rect.origin.y + yOffsetToTop];
                  } else {
                    [nparam SetAlignOffsetWithLeft:glyphRect.origin.x + attachment.bounds.origin.x
                                               Top:rect.origin.y + attachment.bounds.origin.y];
                  }

                  [child alignWithAlignParam:nparam AlignContext:ctx];
                }
              }];
  if (_isCalcVerticalAlignValue) {
    [self.attrString
        enumerateAttribute:LynxInlineTextShadowNodeSignKey
                   inRange:characterRange
                   options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
                usingBlock:^(LynxShadowNode *value, NSRange range, BOOL *_Nonnull stop) {
                  if (value == nil) {
                    return;
                  }
                  CGFloat baselinePosition = 0.f;
                  // ascender,descender
                  NSArray *fontMetric = [self.attrString attribute:LynxUsedFontMetricKey
                                                           atIndex:range.location
                                                    effectiveRange:nil];
                  bool isResetLocation = true;
                  switch (value.shadowNodeStyle.valign) {
                    case LynxVerticalAlignCenter:
                      baselinePosition =
                          (rect.size.height - ([[fontMetric objectAtIndex:0] floatValue] -
                                               [[fontMetric objectAtIndex:1] floatValue])) *
                              0.5f +
                          [[fontMetric objectAtIndex:0] floatValue];
                      break;
                    case LynxVerticalAlignBottom:
                      baselinePosition =
                          rect.size.height + [[fontMetric objectAtIndex:1] floatValue];
                      break;
                    case LynxVerticalAlignTop:
                      baselinePosition = [[fontMetric objectAtIndex:0] floatValue];
                      break;
                    default:
                      isResetLocation = false;
                      break;
                  }
                  if (isResetLocation) {
                    NSRange glyphRange = [layoutManager glyphRangeForCharacterRange:range
                                                               actualCharacterRange:nil];
                    CGPoint point = {[layoutManager locationForGlyphAtIndex:glyphRange.location].x,
                                     baselinePosition};
                    [layoutManager setLocation:point forStartOfGlyphRange:glyphRange];
                  }
                }];
  }
}

- (void)alignWithAlignParam:(AlignParam *)param AlignContext:(AlignContext *)ctx {
  LYNX_TRACE_SECTION(LYNX_TRACE_CATEGORY_WRAPPER, @"LynxTextShadowNode.align");

  NSTextStorage *textStorage = self.textRenderer.textStorage;
  NSLayoutManager *layoutManager = textStorage.layoutManagers.firstObject;

  [layoutManager enumerateLineFragmentsForGlyphRange:(NSRange){0, self.attrString.length}
                                          usingBlock:^(CGRect rect, CGRect usedRect,
                                                       NSTextContainer *_Nonnull textContainer,
                                                       NSRange glyphRange, BOOL *_Nonnull stop) {
                                            NSRange character_range = [layoutManager
                                                characterRangeForGlyphRange:glyphRange
                                                           actualGlyphRange:nil];
                                            [self alignOneLine:character_range
                                                      lineRect:rect
                                                 layoutManager:layoutManager
                                                 textContainer:textContainer
                                                  AlignContext:ctx];
                                          }];
  LYNX_TRACE_END_SECTION(LYNX_TRACE_CATEGORY_WRAPPER)
}

- (CGSize)measureNode:(LynxLayoutNode *)node
            withWidth:(CGFloat)width
            widthMode:(LynxMeasureMode)widthMode
               height:(CGFloat)height
           heightMode:(LynxMeasureMode)heightMode {
  MeasureParam *param = [[MeasureParam alloc] initWithWidth:width
                                                  WidthMode:widthMode
                                                     Height:height
                                                 HeightMode:heightMode];
  return [self measureWithMeasureParam:param MeasureContext:NULL].size;
}

- (void)determineLineSpacing:(NSMutableAttributedString *)attributedString {
  __block CGFloat calculatedLineSpacing = 0;
  [attributedString enumerateAttribute:NSParagraphStyleAttributeName
                               inRange:NSMakeRange(0, attributedString.length)
                               options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
                            usingBlock:^(NSParagraphStyle *paragraphStyle, __unused NSRange range,
                                         __unused BOOL *stop) {
                              if (paragraphStyle) {
                                calculatedLineSpacing =
                                    MAX(paragraphStyle.lineSpacing, calculatedLineSpacing);
                              }
                            }];
  _lineSpacingAdaptation.calculatedLineSpacing = calculatedLineSpacing;
}

- (void)modifyLineHeightForStorage:(NSMutableAttributedString *)storage {
  if (storage.length == 0) {
    return;
  }
  __block CGFloat minimumLineHeight = 0;
  __block CGFloat maximumLineHeight = 0;

  // Check max line-height
  [storage enumerateAttribute:NSParagraphStyleAttributeName
                      inRange:NSMakeRange(0, storage.length)
                      options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
                   usingBlock:^(NSParagraphStyle *paragraphStyle, __unused NSRange range,
                                __unused BOOL *stop) {
                     if (paragraphStyle) {
                       minimumLineHeight = MAX(paragraphStyle.minimumLineHeight, minimumLineHeight);
                       maximumLineHeight = MAX(paragraphStyle.maximumLineHeight, maximumLineHeight);
                     }
                   }];

  //  I don't think the process below is necessary
  if (minimumLineHeight == 0 && maximumLineHeight == 0) {
    __block CGFloat lineHeight = 0;

    [storage enumerateAttribute:NSFontAttributeName
                        inRange:NSMakeRange(0, storage.length)
                        options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
                     usingBlock:^(UIFont *font, NSRange range, __unused BOOL *stop) {
                       if (font) {
                         lineHeight = MAX(lineHeight, font.lineHeight);
                       }
                     }];
    minimumLineHeight = lineHeight;
    maximumLineHeight = lineHeight;
  }

  if (minimumLineHeight == 0 && maximumLineHeight == 0) {
    return;
  }

  if ([storage attribute:NSParagraphStyleAttributeName atIndex:0 effectiveRange:nil] == nil) {
    NSMutableParagraphStyle *newStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    newStyle.minimumLineHeight = minimumLineHeight;
    newStyle.maximumLineHeight = maximumLineHeight;
    [storage addAttribute:NSParagraphStyleAttributeName value:newStyle range:NSMakeRange(0, 1)];
  }

  [storage enumerateAttribute:NSParagraphStyleAttributeName
                      inRange:NSMakeRange(0, storage.length)
                      options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
                   usingBlock:^(NSParagraphStyle *paragraphStyle, __unused NSRange range,
                                __unused BOOL *stop) {
                     if (paragraphStyle) {
                       NSMutableParagraphStyle *style = [paragraphStyle mutableCopy];
                       style.minimumLineHeight = minimumLineHeight;
                       style.maximumLineHeight = maximumLineHeight;
                       [storage addAttribute:NSParagraphStyleAttributeName value:style range:range];
                     }
                   }];
}

/**
 * Vertical align center in line
 */
- (void)addVerticalAlignCenterInline:(NSMutableAttributedString *)attributedString {
  __block CGFloat maxiumCapheight = 0;

  [attributedString enumerateAttribute:NSFontAttributeName
                               inRange:NSMakeRange(0, attributedString.length)
                               options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
                            usingBlock:^(UIFont *font, NSRange range, __unused BOOL *stop) {
                              if (font) {
                                maxiumCapheight = MAX(maxiumCapheight, font.capHeight);
                              }
                            }];

  __block CGFloat maximumLineHeight = 0;

  // Check max line-height
  [attributedString enumerateAttribute:NSParagraphStyleAttributeName
                               inRange:NSMakeRange(0, attributedString.length)
                               options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
                            usingBlock:^(NSParagraphStyle *paragraphStyle, __unused NSRange range,
                                         __unused BOOL *stop) {
                              if (paragraphStyle) {
                                maximumLineHeight =
                                    MAX(paragraphStyle.maximumLineHeight, maximumLineHeight);
                              }
                            }];

  if (maximumLineHeight == 0) {
    return;
  }

  if (self.textVerticalAlign != LynxVerticalAlignDefault) {
    // baseLine offset will calculate during LayoutManager draw
    return;
  }
  _lineSpacingAdaptation.adjustBaseLineOffsetForVerticalAlignCenter = YES;

  CGFloat baseLineOffset = 0;
  baseLineOffset = maximumLineHeight * 1 / 2 - maxiumCapheight * 1 / 2;
  [attributedString addAttribute:NSBaselineOffsetAttributeName
                           value:@(baseLineOffset)
                           range:NSMakeRange(0, attributedString.length)];
  _lineSpacingAdaptation.baseLineOffsetForVerticalAlignCenter = baseLineOffset;
}

- (void)layoutDidStart {
  if (self.textIndent != nil) {
    self.textStyle.textIndent = [self.textIndent applyValue:[self.style computedWidth]];
  } else {
    self.textStyle.textIndent = 0;
  }
  [super layoutDidStart];
  [self.children enumerateObjectsUsingBlock:^(LynxShadowNode *_Nonnull obj, NSUInteger idx,
                                              BOOL *_Nonnull stop) {
    // if child is not virtual, maybe this is a text insert by slot
    if (![obj isVirtual]) {
      [obj layoutDidStart];
    }
  }];
  self.lineSpacingAdaptation.enableLayoutRefactor = self.enableTextRefactor;
  NSMutableAttributedString *attrString;
  if (self.enableTextRefactor) {
    attrString = [[NSTextStorage alloc]
        initWithAttributedString:[self generateAttributedString:nil
                                              withTextMaxLength:self.maxTextLength
                                                  withDirection:self.textStyle.direction]];
  } else {
    attrString = [[self generateAttributedString:nil
                               withTextMaxLength:self.maxTextLength
                                   withDirection:self.textStyle.direction] mutableCopy];
  }

  NSTextAlignment inferredAlignment =
      [LynxTextUtils applyNaturalAlignmentAccordingToTextLanguage:attrString
                                                         refactor:self.uiOwner.uiContext
                                                                      .enableTextLanguageAlignment];
  if (inferredAlignment != NSTextAlignmentNatural) {
    self.textStyle.usedParagraphTextAlignment = inferredAlignment;
  }
  [self determineLineSpacing:attrString];
  if (!self.enableTextRefactor) {
    [self modifyLineHeightForStorage:attrString];
    [self addVerticalAlignCenterInline:attrString];
  }

  if (self.enableTextRefactor) {
    [self setVerticalAlign:attrString];
  }
  self.attrString = attrString;
  _lineSpacingAdaptation.attributedString = attrString;
  self.textRenderer = nil;
}

- (NSAttributedString *)generateAttributedString:
                            (NSDictionary<NSAttributedStringKey, id> *)baseTextAttribute
                               withTextMaxLength:(NSInteger)textMaxLength
                                   withDirection:(NSWritingDirection)direction {
  NSAttributedString *attrStr = [super generateAttributedString:baseTextAttribute
                                              withTextMaxLength:textMaxLength
                                                  withDirection:direction];

  if (!self.enableTextRefactor) {
    return attrStr;
  }

  // if TextRefactor is enabled, inline-text's line-height is ignored. And may contains the
  // following bad case cause line-height not working:
  //      <text style="line-height: xxx"> <text>aaa</text> bbb </text>
  // So set ParagraphStyle at root text node to make sure it is working
  NSMutableAttributedString *mutableStr = [attrStr mutableCopy];
  NSParagraphStyle *paragraphStyle = [self.textStyle genParagraphStyle];
  [mutableStr addAttribute:NSParagraphStyleAttributeName
                     value:paragraphStyle
                     range:NSMakeRange(0, mutableStr.length)];

  return mutableStr;
}

- (void)setVerticalAlign:(NSMutableAttributedString *)attributedString {
  __block CGFloat maxAscender = 0, maxDescender = 0, maxXHeight = 0;
  [attributedString enumerateAttribute:NSFontAttributeName
                               inRange:NSMakeRange(0, attributedString.length)
                               options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
                            usingBlock:^(UIFont *font, NSRange range, BOOL *_Nonnull stop) {
                              if (font) {
                                maxAscender = MAX(maxAscender, font.ascender);
                                maxDescender = MIN(maxDescender, font.descender);
                                maxXHeight = MAX(maxXHeight, font.xHeight);
                              }
                            }];
  _maxLineAscender = _maxAscender = maxAscender;
  _maxLineDescender = _maxDescender = maxDescender;
  _maxXHeight = maxXHeight;

  __block BOOL isCalcVerticalAlignValue = false;
  [attributedString enumerateAttribute:LynxVerticalAlignKey
                               inRange:NSMakeRange(0, attributedString.length)
                               options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
                            usingBlock:^(NSNumber *value, NSRange range, BOOL *_Nonnull stop) {
                              isCalcVerticalAlignValue =
                                  isCalcVerticalAlignValue ||
                                  ([value integerValue] != LynxVerticalAlignDefault);
                            }];
  _isCalcVerticalAlignValue = isCalcVerticalAlignValue;
  if (!_isCalcVerticalAlignValue && isnan(self.textStyle.lineHeight)) {
    return;
  }

  __block float maxLineAscender = _maxLineAscender, maxLineDescender = _maxLineDescender;
  [attributedString
      enumerateAttribute:LynxInlineTextShadowNodeSignKey
                 inRange:NSMakeRange(0, attributedString.length)
                 options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
              usingBlock:^(LynxShadowNode *node, NSRange range, BOOL *_Nonnull stop) {
                if (!node) {
                  return;
                }
                if ([node isKindOfClass:[LynxBaseTextShadowNode class]]) {
                  LynxBaseTextShadowNode *textNode = (LynxBaseTextShadowNode *)node;
                  if (textNode.shadowNodeStyle.valign != LynxVerticalAlignDefault) {
                    __block CGFloat fontAscent = 0.f, fontDescent = 0.f;

                    [attributedString
                        enumerateAttribute:NSFontAttributeName
                                   inRange:range
                                   options:
                                       NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
                                usingBlock:^(UIFont *font, NSRange fontRange, __unused BOOL *stop) {
                                  if (font) {
                                    fontAscent = MAX(fontAscent, font.ascender);
                                    fontDescent = MIN(fontDescent, font.descender);
                                  }
                                }];
                    [attributedString
                        addAttribute:LynxUsedFontMetricKey
                               value:[NSArray
                                         arrayWithObjects:[NSNumber numberWithFloat:fontAscent],
                                                          [NSNumber numberWithFloat:fontDescent],
                                                          nil]
                               range:range];
                    CGFloat baselineOffset =
                        [self calcBaselineShiftOffset:textNode.shadowNodeStyle.valign
                                   verticalAlignValue:textNode.shadowNodeStyle.valignLength
                                         withAscender:fontAscent
                                        withDescender:fontDescent];
                    [attributedString addAttribute:NSBaselineOffsetAttributeName
                                             value:@(baselineOffset)
                                             range:range];
                    maxLineAscender = MAX(maxLineAscender, fontAscent + baselineOffset);
                    maxLineDescender = MIN(maxLineDescender, fontDescent + baselineOffset);
                  }
                }
              }];
  [attributedString
      enumerateAttribute:LynxInlineViewAttributedStringKey
                 inRange:NSMakeRange(0, attributedString.length)
                 options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
              usingBlock:^(LynxShadowNode *node, NSRange range, BOOL *_Nonnull stop) {
                if (!node || [node isKindOfClass:[LynxNativeLayoutNode class]]) {
                  return;
                }

                LynxBaseTextShadowNode *imageNode = (LynxBaseTextShadowNode *)node;
                NSTextAttachment *attachment = [attributedString attribute:NSAttachmentAttributeName
                                                                   atIndex:range.location
                                                            effectiveRange:nil];
                if (imageNode.shadowNodeStyle.valign != LynxVerticalAlignDefault) {
                  CGFloat baselineOffset =
                      [self calcBaselineShiftOffset:imageNode.shadowNodeStyle.valign
                                 verticalAlignValue:imageNode.shadowNodeStyle.valignLength
                                       withAscender:attachment.bounds.size.height
                                      withDescender:0.f];

                  CGRect rect = attachment.bounds;
                  rect.origin.y += baselineOffset;
                  [attachment setBounds:rect];
                }
                maxLineAscender = MAX(maxLineAscender,
                                      attachment.bounds.size.height + attachment.bounds.origin.y);
                maxLineDescender = MIN(maxLineDescender, attachment.bounds.origin.y);
              }];
  _maxLineAscender = MAX(_maxLineAscender, maxLineAscender);
  _maxLineDescender = MIN(_maxLineDescender, maxLineDescender);
}

- (CGFloat)calcBaselineShiftOffset:(LynxVerticalAlign)verticalAlign
                verticalAlignValue:(CGFloat)verticalAlignValue
                      withAscender:(CGFloat)ascender
                     withDescender:(CGFloat)descender {
  switch (verticalAlign) {
    case LynxVerticalAlignLength:
      return verticalAlignValue;
    case LynxVerticalAlignPercent:
      // if set vertical-align:50%, baselineShift = 50 * lineHeight /100.f, the lineHeight is 0 if
      // lineHeight not set.
      return _lineSpacingAdaptation.lineHeight * verticalAlignValue / 100.f;
    case LynxVerticalAlignMiddle:
      // the middle of element will be align to the middle of max x-height
      return (-descender - ascender + _maxXHeight) * 0.5f;
    case LynxVerticalAlignTextTop:
    case LynxVerticalAlignTop:
      // the ascender of element will be align to text max ascender
      return _maxAscender - ascender;
    case LynxVerticalAlignTextBottom:
    case LynxVerticalAlignBottom:
      // the descender of element will be align to text max descender
      return _maxDescender - descender;
    case LynxVerticalAlignSub:
      //-height * 0.1
      return -(ascender - descender) * 0.1f;
    case LynxVerticalAlignSuper:
      // height * 0.1
      return (ascender - descender) * 0.1f;
    case LynxVerticalAlignCenter:
      // the middle of element will be align to the middle of line
      return (_maxAscender + _maxDescender - ascender - descender) * 0.5f;
    default:
      // baseline,center,top,bottom
      return 0.f;
  }
}

- (CGFloat)alignInlineNodeInVertical:(LynxVerticalAlign)verticalAlign
                      withLineHeight:(CGFloat)lineFragmentHeight
                withAttachmentHeight:(CGFloat)attachmentHeight
             withAttachmentYPosition:(CGFloat)attachmentYPosition {
  CGFloat yOffsetToTop = 0;
  switch (verticalAlign) {
    case LynxVerticalAlignBottom:
      yOffsetToTop = lineFragmentHeight - attachmentHeight;
      break;
    case LynxVerticalAlignTop:
      yOffsetToTop = 0;
      break;
    case LynxVerticalAlignCenter:
      yOffsetToTop = (lineFragmentHeight - attachmentHeight) * 0.5f;
      break;
    default:
      yOffsetToTop = attachmentYPosition - attachmentHeight;
      break;
  }
  return yOffsetToTop;
}

- (void)layoutDidUpdate {
  [super layoutDidUpdate];
  if (self.textRenderer == nil) {
    [self measureNode:self
            withWidth:self.frame.size.width
            widthMode:LynxMeasureModeDefinite
               height:self.frame.size.height
           heightMode:LynxMeasureModeDefinite];
  }
  // As TextShadowNode has custom layout, we have to handle children layout
  // after layout updated.
  [self updateNonVirtualOffspringLayout];
}

- (id)getExtraBundle {
  return self.textRenderer;
}

/**
 * Update layout info for those non-virtual shadow node which will not layout
 * by native layout system.
 */
- (void)updateNonVirtualOffspringLayout {
  if (!self.hasNonVirtualOffspring) {
    return;
  }
  NSTextStorage *textStorage = self.textRenderer.textStorage;
  NSLayoutManager *layoutManager = textStorage.layoutManagers.firstObject;
  NSTextContainer *textContainer = layoutManager.textContainers.firstObject;
  NSRange glyphRange = [layoutManager glyphRangeForTextContainer:textContainer];
  NSRange characterRange = [layoutManager characterRangeForGlyphRange:glyphRange
                                                     actualGlyphRange:nil];

  NSMutableArray *attachemnts = [NSMutableArray new];

  // Update child node layout info
  [textStorage
      enumerateAttribute:LynxInlineViewAttributedStringKey
                 inRange:characterRange
                 options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
              usingBlock:^(LynxShadowNode *node, NSRange range, BOOL *stop) {
                if (!node || [node isKindOfClass:[LynxNativeLayoutNode class]]) {
                  // native inline view
                  NSRange inlineViewGlyphRange = [layoutManager glyphRangeForCharacterRange:range
                                                                       actualCharacterRange:nil];
                  NSRange truncatedGlyphRange = [layoutManager
                      truncatedGlyphRangeInLineFragmentForGlyphAtIndex:inlineViewGlyphRange
                                                                           .location];
                  LynxTextAttachmentInfo *inlineViewAttachment = nil;
                  if (truncatedGlyphRange.location != NSNotFound &&
                      truncatedGlyphRange.location <= inlineViewGlyphRange.location) {
                    inlineViewAttachment = [[LynxTextAttachmentInfo alloc] initWithSign:node.sign
                                                                               andFrame:CGRectZero];
                  } else {
                    NSTextAttachment *attachment = [textStorage attribute:NSAttachmentAttributeName
                                                                  atIndex:range.location
                                                           effectiveRange:nil];

                    inlineViewAttachment =
                        [[LynxTextAttachmentInfo alloc] initWithSign:node.sign
                                                            andFrame:attachment.bounds];
                  }

                  inlineViewAttachment.nativeAttachment = YES;

                  [attachemnts addObject:inlineViewAttachment];

                  return;
                }

                // Get current line rect
                NSRange lineRange = NSMakeRange(0, 0);
                NSRange inlineImageGlyphRange = [layoutManager glyphRangeForCharacterRange:range
                                                                      actualCharacterRange:nil];
                CGRect lineFragment =
                    [layoutManager lineFragmentRectForGlyphAtIndex:inlineImageGlyphRange.location
                                                    effectiveRange:&lineRange];
                CGRect glyphRect = [layoutManager boundingRectForGlyphRange:inlineImageGlyphRange
                                                            inTextContainer:textContainer];

                // Get attachment size
                NSTextAttachment *attachment = [textStorage attribute:NSAttachmentAttributeName
                                                              atIndex:range.location
                                                       effectiveRange:nil];
                CGSize attachmentSize = attachment.bounds.size;
                CGFloat yOffsetToTop = 0;
                CGFloat yPosition =
                    [layoutManager locationForGlyphAtIndex:inlineImageGlyphRange.location].y;
                const LynxVerticalAlign vAlign =
                    ([node shadowNodeStyle] != nil ? [node shadowNodeStyle].valign
                                                   : LynxVerticalAlignDefault);

                if (self.enableTextRefactor) {
                  yOffsetToTop = [self alignInlineNodeInVertical:vAlign
                                                  withLineHeight:lineFragment.size.height
                                            withAttachmentHeight:attachment.bounds.size.height
                                         withAttachmentYPosition:yPosition];
                } else {
                  switch (vAlign) {
                    case LynxVerticalAlignBottom:
                      yOffsetToTop = lineFragment.size.height - attachmentSize.height;
                      break;
                    case LynxVerticalAlignTop:
                      yOffsetToTop = 0;
                      break;
                    case LynxVerticalAlignMiddle:
                    case LynxVerticalAlignDefault:
                      yOffsetToTop = (lineFragment.size.height - attachmentSize.height) * 0.5f;
                      break;
                    default:
                      yOffsetToTop = yPosition - attachmentSize.height;
                      break;
                  }
                }

                // Determin final rect, make attachment center in line
                CGRect frame = {
                    {glyphRect.origin.x + node.style.computedMarginLeft,
                     lineFragment.origin.y + node.style.computedMarginTop + yOffsetToTop},
                    {attachmentSize.width - node.style.computedMarginLeft -
                         node.style.computedMarginRight,
                     attachmentSize.height - node.style.computedMarginTop -
                         node.style.computedMarginBottom}};

                NSRange truncatedGlyphRange = [layoutManager
                    truncatedGlyphRangeInLineFragmentForGlyphAtIndex:inlineImageGlyphRange
                                                                         .location];
                if (truncatedGlyphRange.location != NSNotFound &&
                    truncatedGlyphRange.location <= inlineImageGlyphRange.location) {
                  // truncated happen before this inline-image;
                  // no need to show all remined inline-image
                  [node updateLayoutWithFrame:CGRectZero];
                  [attachemnts addObject:[[LynxTextAttachmentInfo alloc] initWithSign:node.sign
                                                                             andFrame:CGRectZero]];
                } else {
                  [node updateLayoutWithFrame:frame];
                  [attachemnts addObject:[[LynxTextAttachmentInfo alloc] initWithSign:node.sign
                                                                             andFrame:frame]];
                }
              }];
  self.textRenderer.attachments = attachemnts;
}

LYNX_PROP_SETTER("background-color", setBackgroundColor, UIColor *) {
  // Do nothing as background-color will be handle by ui
}

LYNX_PROP_SETTER("text-maxline", setMaxeLine, NSInteger) {
  if (requestReset) {
    value = LynxNumberNotSet;
  }
  if (self.maxLineNum != value) {
    if (value > 0) {
      self.maxLineNum = value;
    } else {
      self.maxLineNum = LynxNumberNotSet;
    }
    [self setNeedsLayout];
  }
}

LYNX_PROP_SETTER("text-maxlength", setTextMaxLength, NSInteger) {
  if (requestReset) {
    value = LynxNumberNotSet;
  }
  if (self.maxTextLength != value) {
    if (value > 0) {
      self.maxTextLength = value;
    } else {
      self.maxTextLength = LynxNumberNotSet;
    }
    [self setNeedsLayout];
  }
}

LYNX_PROP_SETTER("white-space", setWhiteSpace, LynxWhiteSpaceType) {
  if (requestReset) {
    value = LynxWhiteSpaceNormal;
  }
  if (self.whiteSpace != value) {
    self.whiteSpace = value;
    [self setNeedsLayout];
  }
}

LYNX_PROP_SETTER("text-overflow", setTextOverflow, LynxTextOverflowType) {
  if (requestReset) {
    value = LynxTextOverflowClip;
  }
  if (self.textOverflow != value) {
    self.textOverflow = value;
    [self setNeedsLayout];
  }
}

LYNX_PROP_SETTER("overflow-x", setOverflowX, LynxOverflowType) {
  if (requestReset) {
    value = LynxOverflowHidden;
  }
  if (value == LynxOverflowVisible) {
    self.overflow = LynxOverflowX;
  }
}

LYNX_PROP_SETTER("overflow-y", setOverflowY, LynxOverflowType) {
  if (requestReset) {
    value = LynxOverflowHidden;
  }
  if (value == LynxOverflowVisible) {
    self.overflow = LynxOverflowY;
  }
}
LYNX_PROP_SETTER("overflow", setOverflow, LynxOverflowType) {
  if (requestReset) {
    value = LynxOverflowHidden;
  }
  if (value == LynxOverflowVisible) {
    self.overflow = LynxOverflowXY;
  }
}

LYNX_PROP_SETTER("text-vertical-align", setTextVerticalAlign, NSString *) {
  if (requestReset) {
    value = @"center";
  }

  if ([value isEqualToString:@"bottom"]) {
    self.textVerticalAlign = LynxVerticalAlignBottom;
  } else if ([value isEqualToString:@"top"]) {
    self.textVerticalAlign = LynxVerticalAlignTop;
  } else {
    self.textVerticalAlign = LynxVerticalAlignMiddle;
  }
  [self setNeedsLayout];
}

LYNX_PROP_SETTER("word-break", setWordBreakStrategy, LynxWordBreakType) {
  if (requestReset) {
    value = LynxWordBreakNormal;
  }
  // simplest implement for css word-break
  // current only handle `break-all`, or other mode is fallback to WordBreakStrategyNone
  if (value == LynxWordBreakBreakAll) {
    self.lineSpacingAdaptation.breakByChar = YES;
  } else {
    self.lineSpacingAdaptation.breakByChar = NO;
  }
  [self setNeedsLayout];
}

LYNX_PROP_SETTER("tail-color-convert", setEnableTailColorConvert, BOOL) {
  if (requestReset) {
    value = NO;
  }

  self.enableTailColorConvert = value;
  [self setNeedsLayout];
}

LYNX_PROP_SETTER("text-indent", setTextIndent, NSArray *) {
  if (requestReset || value == nil || value.count != 2) {
    self.textIndent = nil;
  } else {
    self.textIndent = [[LynxTextIndent alloc] initWithValue:value];
  }
  [self markStyleDirty];
  [self setNeedsLayout];
}

@end

@implementation LynxConverter (LynxWhiteSpaceType)

+ (LynxWhiteSpaceType)toLynxWhiteSpace:(id)value {
  if (!value || [value isEqual:[NSNull null]]) {
    return LynxWhiteSpaceNormal;
  }
  return (LynxWhiteSpaceType)[value intValue];
}

@end
