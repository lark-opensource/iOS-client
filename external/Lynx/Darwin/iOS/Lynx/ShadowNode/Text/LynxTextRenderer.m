// Copyright 2019 The Lynx Authors. All rights reserved.

#import "LynxTextRenderer.h"
#import "LynxBaseTextShadowNode.h"
#import "LynxBaselineShiftLayoutManager.h"
#import "LynxTextLayoutManager.h"
#import "LynxTextRendererCache.h"
#import "LynxTextShadowNode.h"
#import "LynxTextUtils.h"
#import "LynxTraceEvent.h"
#import "LynxTraceEventWrapper.h"
#import "base/compiler_specific.h"

@implementation LynxTextAttachmentInfo

- (instancetype)initWithSign:(NSInteger)sign andFrame:(CGRect)frame {
  self = [super init];

  if (self) {
    _sign = sign;
    _frame = frame;
    _nativeAttachment = NO;
  }

  return self;
}

@end

@implementation LynxTextRenderer {
  CGSize _calculatedSize;
  CGSize _textSize;
  CGFloat _offsetX;
  NSLayoutManager *_layoutManager;
  NSTextStorage *_textStorage;
  NSTextContainer *_textContainer;
}

- (instancetype)initWithAttributedString:(NSAttributedString *)attrStr
                              layoutSpec:(LynxLayoutSpec *)spec {
  LYNX_TRACE_SECTION(LYNX_TRACE_CATEGORY_WRAPPER, @"LynxTextRenderer.init");
  if (self = [super init]) {
    NSTextAlignment physicalAlignment = spec.textStyle.usedParagraphTextAlignment;

    _attrStr = attrStr;
    _layoutSpec = spec;
    if (spec.verticalAlign != LynxVerticalAlignDefault) {
      _layoutManager =
          [[LynxBaselineShiftLayoutManager alloc] initWithVerticalAlign:spec.verticalAlign];
    } else {
      _layoutManager = [[LynxTextLayoutManager alloc] init];
    }
    _layoutManager.usesFontLeading = NO;
    _layoutManager.delegate = spec.layoutManagerDelegate;
    _textStorage = [[NSTextStorage alloc] initWithAttributedString:attrStr];
    [_textStorage addLayoutManager:_layoutManager];
    _offsetX = 0.f;

    // 解决text组件height小于行高*高度之和时，重新修改总体行高spec.heightMode
    CGFloat modified_spec_height = spec.height;
    if (!isnan(spec.textStyle.lineHeight) && spec.heightMode != LynxMeasureModeIndefinite &&
        (spec.textOverflow == LynxTextOverflowClip || !spec.enableTextRefactor)) {
      // add 0.5 to spec.textStyle.lineHeight to ensure modified_spec_height is high enough for
      // system to draw all lines.
      // add more 0.5 to spec.textStyle.lineHeight for iOS9 to ensure modified_spec_height is high
      // enough for system to draw all lines.
      if (@available(iOS 10.0, *)) {
        modified_spec_height =
            ceil(spec.height / spec.textStyle.lineHeight) * ceil(spec.textStyle.lineHeight + 0.5);
      } else {
        modified_spec_height =
            ceil(spec.height / spec.textStyle.lineHeight) * ceil(spec.textStyle.lineHeight + 1);
      }
    }

    CGFloat w = spec.widthMode == LynxMeasureModeIndefinite ? CGFLOAT_MAX : spec.width;
    CGFloat h = spec.heightMode == LynxMeasureModeIndefinite ? CGFLOAT_MAX : modified_spec_height;

    // text overflow for Y axis
    if (spec.overflow == LynxOverflowY || spec.overflow == LynxOverflowXY) {
      h = CGFLOAT_MAX;
    }
    // give no width limit when whiteSpace is LynxWhiteSpaceNowrap
    if (spec.whiteSpace == LynxWhiteSpaceNowrap && spec.textOverflow != LynxTextOverflowEllipsis) {
      w = CGFLOAT_MAX;
    }
    CGSize inputSize = (CGSize){
        w,
        h,
    };

    LYNX_TRACE_SECTION(LYNX_TRACE_CATEGORY_WRAPPER, @"LynxTextRenderer.ensureLayout");
    _textContainer = [self createTextContainerWithSize:inputSize spec:spec];
    [_layoutManager addTextContainer:_textContainer];
    if (spec.enableTextNonContiguousLayout) {
      _layoutManager.allowsNonContiguousLayout = YES;
      if (spec.maxTextLength != LynxNumberNotSet) {
        [_layoutManager ensureLayoutForGlyphRange:NSMakeRange(0, spec.maxTextLength)];
      } else {
        if (spec.maxLineNum > 0) {
          h = spec.maxLineNum * (MAX(spec.textStyle.lineHeight, [self maxfontsize] * 1.5));
        }
        if (spec.widthMode != LynxMeasureModeDefinite) {
          w = MAXFLOAT;
        }
        if (spec.heightMode != LynxMeasureModeDefinite) {
          h = MAXFLOAT;
        }
        [_layoutManager ensureLayoutForBoundingRect:CGRectMake(0, 0, w, h)
                                    inTextContainer:_textContainer];
      }
    } else {
      [_layoutManager ensureLayoutForTextContainer:_textContainer];
    }
    LYNX_TRACE_END_SECTION(LYNX_TRACE_CATEGORY_WRAPPER)
    _calculatedSize = [_layoutManager usedRectForTextContainer:_textContainer].size;

    // if text size is smaller than width, need layout once again for text-align
    if (spec.whiteSpace == LynxWhiteSpaceNowrap && spec.widthMode == LynxMeasureModeDefinite &&
        physicalAlignment != NSTextAlignmentLeft && _calculatedSize.width < spec.width) {
      _textContainer.size = CGSizeMake(spec.width, _calculatedSize.height);
      [_layoutManager ensureLayoutForTextContainer:_textContainer];
      _calculatedSize = [_layoutManager usedRectForTextContainer:_textContainer].size;
    }

    // TODO(yxping): 处理非 Natural 的文字位置时，需要为 TextContainer 重新设定空间，保证 text align
    // 在给定的空间能起作用。 而这段逻辑可以放置在 layout 阶段的 layoutDidFinish
    // 阶段重新进行一次测量即可，不需要在 measure 过程中进行重测，目前暂时放置在这里的主要原因是
    // 自定义排版的 measure 和 layout 阶段逻辑需要优化，后续需要移动到 layout 阶段。
    if (physicalAlignment != NSTextAlignmentLeft &&
        ((spec.widthMode == LynxMeasureModeAtMost && _calculatedSize.width < spec.width) ||
         (spec.width == LynxMeasureModeIndefinite))) {
      _textContainer.size = CGSizeMake(_calculatedSize.width, _calculatedSize.height);
      [_layoutManager ensureLayoutForTextContainer:_textContainer];
      _calculatedSize = [_layoutManager usedRectForTextContainer:_textContainer].size;
    } else if (spec.widthMode == LynxMeasureModeAtMost ||
               spec.widthMode == LynxMeasureModeIndefinite) {
      CGPoint p = [_layoutManager usedRectForTextContainer:_textContainer].origin;
      if (p.x != 0.0) {
        _calculatedSize.width += p.x;
      }
    }
    if (spec.enableTailColorConvert) {
      [self overrideTruncatedAttrIfNeed];
    }
    _textSize = CGSizeMake(_calculatedSize.width, _calculatedSize.height);
    // recalucate height according to mode in case of overflow
    if (spec.overflow != LynxNoOverflow) {
      if (_calculatedSize.height != modified_spec_height) {
        if (spec.heightMode == LynxMeasureModeDefinite ||
            (spec.heightMode == LynxMeasureModeAtMost &&
             _calculatedSize.height > modified_spec_height)) {
          _calculatedSize.height = modified_spec_height;
        }
      }
    }

    if (spec.widthMode == LynxMeasureModeAtMost && layoutManagerIsTruncated(_layoutManager) &&
        physicalAlignment == NSTextAlignmentCenter) {
      // issue: #2129
      // if textline is truncated by layout manager, the width of final boundary is a litter smaller
      // than parent's width. This will cause text in render result not center in textview boundary.
      // to make the render right, need to do translate on x-axis
      if (_calculatedSize.width < spec.width) {
        // only center alignment need to do offset
        _offsetX = (spec.width - _calculatedSize.width) / 2.0f;
      }
      _calculatedSize.width = MAX(_calculatedSize.width, spec.width);
    }

    [self handleEllipsisDirection:spec];

    [_attrStr enumerateAttribute:NSFontAttributeName
                         inRange:NSMakeRange(0, _attrStr.length)
                         options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
                      usingBlock:^(UIFont *font, NSRange range, BOOL *_Nonnull stop) {
                        // A hack way to detect if this font is fake apply italic with skew
                        // transform
                        if ([font.fontDescriptor.fontAttributes
                                objectForKey:@"NSCTFontMatrixAttribute"] == nil) {
                          return;
                        }

                        // fake italic use -0.25 skew
                        _calculatedSize.width += font.xHeight * 0.25;
                      }];
  }

  self.baseline = ((LineSpacingAdaptation *)_layoutManager.delegate).baseline;
  LYNX_TRACE_END_SECTION(LYNX_TRACE_CATEGORY_WRAPPER)
  return self;
}

- (void)genSubSpan {
  __block NSMutableArray<LynxEventTargetSpan *> *subSpan = [NSMutableArray new];

  [self.attrStr
      enumerateAttribute:LynxInlineTextShadowNodeSignKey
                 inRange:NSMakeRange(0, self.attrStr.length)
                 options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
              usingBlock:^(LynxShadowNode *node, NSRange range, BOOL *_Nonnull stop) {
                if (!node) {
                  return;
                }
                // split range by newline, don't need the rect of newline
                NSString *str = [self.attrStr.string substringWithRange:range];
                NSMutableArray *ranges = [NSMutableArray array];
                NSRange newlineRange =
                    [str rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet]];
                if (newlineRange.location == NSNotFound) {
                  [ranges addObject:[NSValue valueWithRange:range]];
                } else {
                  NSRange lastNewlineRange = NSMakeRange(0, 0);
                  while (newlineRange.location != NSNotFound) {
                    NSRange remainRange =
                        NSMakeRange(newlineRange.location + newlineRange.length,
                                    range.length - newlineRange.location - newlineRange.length);
                    [ranges addObject:[NSValue
                                          valueWithRange:NSMakeRange(range.location +
                                                                         lastNewlineRange.location +
                                                                         lastNewlineRange.length,
                                                                     newlineRange.location -
                                                                         lastNewlineRange.location -
                                                                         lastNewlineRange.length)]];
                    lastNewlineRange = newlineRange;
                    newlineRange = [str rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet]
                                                        options:NSRegularExpressionSearch
                                                          range:remainRange];
                  }
                  [ranges
                      addObject:[NSValue
                                    valueWithRange:NSMakeRange(
                                                       range.location + lastNewlineRange.location +
                                                           lastNewlineRange.length,
                                                       range.length - lastNewlineRange.location -
                                                           lastNewlineRange.length)]];
                }

                for (NSUInteger i = 0; i < [ranges count]; i++) {
                  NSRange characterRange = [ranges[i] rangeValue];
                  if (characterRange.length == 0) {
                    continue;
                  }
                  // If noncontiguous layout is not enabled, this method forces the generation of
                  // glyphs for all characters up to and including the end of the specified range.
                  NSRange glyphRange = [_layoutManager glyphRangeForCharacterRange:characterRange
                                                              actualCharacterRange:NULL];
                  // since text can be breaked by NSLayoutManager for newline
                  // here we need to fetch precise sub range rect
                  [_layoutManager
                      enumerateEnclosingRectsForGlyphRange:glyphRange
                                  withinSelectedGlyphRange:NSMakeRange(NSNotFound, 0)
                                           inTextContainer:_textContainer
                                                usingBlock:^(CGRect rect, BOOL *_Nonnull stop) {
                                                  [subSpan addObject:[[LynxEventTargetSpan alloc]
                                                                         initWithShadowNode:node
                                                                                      frame:rect]];
                                                }];
                }
              }];

  if ([subSpan count] > 0) {
    _subSpan = subSpan;
  }
}

- (void)handleEllipsisDirection:(LynxLayoutSpec *)spec {
  if (spec.textStyle.direction != NSWritingDirectionNatural) {
    __block NSUInteger truncatedLocation = NSNotFound;
    [_layoutManager
        enumerateLineFragmentsForGlyphRange:NSMakeRange(0, _layoutManager.textStorage.length)
                                 usingBlock:^(CGRect rect, CGRect usedRect,
                                              NSTextContainer *_Nonnull textContainer,
                                              NSRange glyphRange, BOOL *_Nonnull stop) {
                                   NSRange truncatedRange = [self->_layoutManager
                                       truncatedGlyphRangeInLineFragmentForGlyphAtIndex:
                                           glyphRange.location];
                                   if (truncatedRange.location != NSNotFound) {
                                     truncatedLocation = truncatedRange.location;
                                     *stop = YES;
                                   }
                                 }];

    NSRange lineRange;
    if (truncatedLocation == NSNotFound) {
      return;
    }
    lineRange =
        [_layoutManager truncatedGlyphRangeInLineFragmentForGlyphAtIndex:(truncatedLocation)];
    if (lineRange.location != NSNotFound) {
      [_textStorage
          replaceCharactersInRange:[_layoutManager characterRangeForGlyphRange:lineRange
                                                              actualGlyphRange:NULL]
                        withString:[LynxTextUtils
                                       getEllpsisStringAccordingToWritingDirection:spec.textStyle
                                                                                       .direction]];
      [_layoutManager ensureLayoutForTextContainer:_textContainer];
    }
  }
}

- (void)overrideTruncatedAttrIfNeed {
  [_layoutManager
      enumerateLineFragmentsForGlyphRange:NSMakeRange(0, _layoutManager.textStorage.length)
                               usingBlock:^(CGRect rect, CGRect usedRect,
                                            NSTextContainer *_Nonnull textContainer,
                                            NSRange glyphRange, BOOL *_Nonnull stop) {
                                 NSRange truncatedRange = [self->_layoutManager
                                     truncatedGlyphRangeInLineFragmentForGlyphAtIndex:
                                         glyphRange.location];
                                 if (truncatedRange.length == 0) {
                                   // no truncated on this line
                                   return;
                                 }
                                 truncatedRange = [self->_layoutManager
                                     characterRangeForGlyphRange:truncatedRange
                                                actualGlyphRange:NULL];

                                 NSDictionary<NSAttributedStringKey, id> *attr =
                                     [self->_layoutManager.textStorage
                                         attributesAtIndex:truncatedRange.location
                                            effectiveRange:nil];
                                 NSDictionary *baseAttr =
                                     [self->_layoutManager.textStorage attributesAtIndex:0
                                                                          effectiveRange:nil];
                                 NSMutableDictionary *overrideAttr =
                                     [NSMutableDictionary dictionaryWithDictionary:attr];
                                 overrideAttr[NSForegroundColorAttributeName] =
                                     baseAttr[NSForegroundColorAttributeName];

                                 [self->_layoutManager.textStorage
                                     setAttributes:overrideAttr
                                             range:NSMakeRange(
                                                       truncatedRange.location,
                                                       self->_layoutManager.textStorage.length -
                                                           truncatedRange.location)];

                                 *stop = YES;
                               }];
}

- (CGSize)size {
  return _calculatedSize;
}

- (CGSize)textsize {
  return _textSize;
}

- (CGFloat)maxfontsize {
  // TODO: (linxs)check performance and run times
  __block CGFloat fontsize = 0;
  [_layoutManager.textStorage
      enumerateAttribute:NSFontAttributeName
                 inRange:NSMakeRange(0, _layoutManager.textStorage.length)
                 options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
              usingBlock:^(UIFont *font, NSRange range, __unused BOOL *stop) {
                fontsize = font.pointSize > fontsize ? font.pointSize : fontsize;
              }];
  return fontsize;
}

- (NSLayoutManager *)layoutManager {
  return _layoutManager;
}

- (NSTextStorage *)textStorage {
  return _textStorage;
}

- (void)drawTextRect:(CGRect)bounds padding:(UIEdgeInsets)padding border:(UIEdgeInsets)border {
  NSTextContainer *textContainer = _layoutManager.textContainers.firstObject;
  NSRange glyphRange = [_layoutManager glyphRangeForTextContainer:textContainer];
  CGPoint origin = bounds.origin;
  origin.x += (padding.left + border.left);
  origin.y += (padding.top + border.top);
  // issue: #2129
  // do a little translate on x-axis to make text content render at center
  origin.x += _offsetX;
  [_layoutManager drawBackgroundForGlyphRange:glyphRange atPoint:origin];
  [_layoutManager drawGlyphsForGlyphRange:glyphRange atPoint:origin];
}

- (void)drawRect:(CGRect)bounds padding:(UIEdgeInsets)padding border:(UIEdgeInsets)border {
  if ([_layoutManager respondsToSelector:NSSelectorFromString(@"setOverflowOffset:")]) {
    [(id)_layoutManager setOverflowOffset:bounds.origin];
  }

  [self drawTextRect:bounds padding:padding border:border];
}

- (NSTextContainer *)createTextContainerWithSize:(CGSize)inputSize spec:(LynxLayoutSpec *)spec {
  NSTextContainer *textContainer = [[NSTextContainer alloc] initWithSize:inputSize];
  // lineFragmentPadding default is 5.0
  textContainer.lineFragmentPadding = 0;
  // ellipsis mode
  if (spec.textOverflow == LynxTextOverflowEllipsis) {
    textContainer.lineBreakMode = NSLineBreakByTruncatingTail;
  } else {
    if (spec.enableNewClipMode) {
      textContainer.lineBreakMode = NSLineBreakByWordWrapping;
    } else {
      textContainer.lineBreakMode = NSLineBreakByClipping;
    }
  }
  // max-line 0 means no limits
  if (spec.whiteSpace == LynxWhiteSpaceNowrap) {
    textContainer.maximumNumberOfLines = 1;
  } else if (spec.maxLineNum != LynxNumberNotSet) {
    textContainer.maximumNumberOfLines = spec.maxLineNum;
  } else {
    textContainer.maximumNumberOfLines = 0;
  }
  return textContainer;
}

@end
