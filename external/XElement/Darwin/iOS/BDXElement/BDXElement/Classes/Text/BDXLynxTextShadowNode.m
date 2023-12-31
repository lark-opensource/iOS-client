//
//  BDXLynxTextShadowNode.m
//  BDXElement
//

#import "BDXLynxTextShadowNode.h"
#import "BDXLynxRichTextStyle.h"
#import "BDXLynxInlineTruncationShadowNode.h"

#import <YYText/YYText.h>
#import <Lynx/LynxRawTextShadowNode.h>
#import <Lynx/LynxComponentRegistry.h>
#import <Lynx/LynxPropsProcessor.h>

#import "BDXBracketRichTextFormater.h"

@interface BDXLynxTextShadowNode()

@end

@implementation BDXLynxTextShadowNode

#if LYNX_LAZY_LOAD
LYNX_LAZY_REGISTER_SHADOW_NODE("x-text")
#else
LYNX_REGISTER_SHADOW_NODE("x-text")
#endif

- (CGSize)measureNode:(LynxLayoutNode *)node
            withWidth:(CGFloat)width
            widthMode:(LynxMeasureMode)widthMode
               height:(CGFloat)height
           heightMode:(LynxMeasureMode)heightMode
{
    
    // HACK ALERT! TikTok swizzled yytext, and the swizzle code has bug when the size of container is max float on both side.
    // Use a super large number instead of max float here to work around this issue.
    CGFloat measureWidth = widthMode == LynxMeasureModeIndefinite ? 1000000.f : width;
    CGFloat measureHeight = heightMode == LynxMeasureModeIndefinite ? 1000000.f : height;

    YYTextLayout* layout;
    if (self.uiOwner.uiContext.enableXTextLayoutReused) {
        self.textStyle.textModel = [BDXLynxTextLayoutModel createTextModelWithStyle:self.textStyle];
        [self.textStyle.textModel createLayoutWithContainerSize:CGSizeMake(measureWidth, measureHeight)];
        layout = self.textStyle.textModel.textLayout;
    } else {
        YYTextContainer* container = [YYTextContainer containerWithSize:CGSizeMake(measureWidth, measureHeight)];
        if (self.textStyle.numberOfLines != 0) {
            container.maximumNumberOfRows = self.textStyle.numberOfLines;
        }
    
        layout = [YYTextLayout layoutWithContainer:container text:self.textStyle.ultimateAttributedString];
    }
    CGSize size = layout.textBoundingSize;
    if (widthMode == LynxMeasureModeAtMost && self.textStyle.paragraphStyle.alignment != NSTextAlignmentLeft && self.textStyle.paragraphStyle.alignment != NSTextAlignmentNatural) {
      size.width = layout.textBoundingRect.size.width;
    }
    CGFloat realWidth = ceilf(size.width);
    if (widthMode == LynxMeasureModeDefinite) {
        realWidth = ceilf(width);
    }
  
    [self dispatchLayoutEventWithLayout:layout];
    
    return CGSizeMake(realWidth, ceilf(size.height));
}

- (void)adoptNativeLayoutNode:(int64_t)ptr
{
    [super adoptNativeLayoutNode:ptr];
    [self setMeasureDelegate:self];
}

- (void)layoutDidStart
{
    [super layoutDidStart];
    [self reloadInlineTexts];
    
    [self.children enumerateObjectsUsingBlock:^(LynxShadowNode * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:BDXLynxInlineTruncationShadowNode.class]) {
            BDXLynxInlineTruncationShadowNode *truncation = (BDXLynxInlineTruncationShadowNode *)obj;
            [truncation reloadInlineTexts];
            self.textStyle.truncationAttributeString = truncation.truncationAttributeString;
        }
    }];
}

LYNX_PROP_SETTER("richtype", richTextType, NSString *)
{
    if ([value isEqualToString:@"bracket"]) {
        self.textStyle.richTextFormater = [BDXBracketRichTextFormater sharedFormater];
    }
}

LYNX_PROP_SETTER("text-indent", textIndent, NSArray *)
{
  CGFloat indent = 0.f;
  if (!requestReset) {
    CGFloat v = [value[0] floatValue];
    indent = [value[1] integerValue] == 0 ? v : v * [self.style computedWidth];
  }
  [self resetParagraphStyle:^(NSMutableParagraphStyle *paragraphStyle) {
      paragraphStyle.firstLineHeadIndent = indent;
  }];
  [self setNeedsLayout];
}

- (BOOL)hasCustomLayout
{
  return YES;
}

- (void)layoutDidUpdate
{
    [super layoutDidUpdate];
}

- (id) getExtraBundle {
  return self.textStyle;
}

- (BOOL)needsEventSet {
  return YES;
}

- (void) dispatchLayoutEventWithLayout:(YYTextLayout*)layout {
  if ([self.eventSet objectForKey:@"layout"] == nil) {
    return;
  }
  
  NSMutableDictionary* layoutInfo = [NSMutableDictionary new];

  [layoutInfo setObject:@(layout.lines.count) forKey:@"lineCount"];
  
  NSMutableArray* lineInfo = [NSMutableArray new];
  
  for(NSUInteger i = 0; i < layout.lines.count; i++) {
    YYTextLine* line = [layout.lines objectAtIndex:i];
    NSMutableDictionary* info = [NSMutableDictionary new];
    
    [info setObject:@(line.range.location) forKey:@"start"];
    
    NSInteger ellipsisCount = 0;
    if (i == layout.lines.count - 1) {
      ellipsisCount = layout.text.length - line.range.location - line.range.length;
    }
    
    [info setObject:@(ellipsisCount) forKey:@"ellipsisCount"];
    
    if (ellipsisCount == 0) {
      [info setObject:@(line.range.location + line.range.length) forKey:@"end"];
    } else {
      [info setObject:@(layout.text.length) forKey:@"end"];
    }
    
    [lineInfo addObject:info];
    
  }
  
  [layoutInfo setObject:lineInfo forKey:@"lines"];
  
  LynxDetailEvent* event = [[LynxDetailEvent alloc] initWithName:@"layout" targetSign:[self sign] detail:layoutInfo];
  
  [self.uiOwner.uiContext.eventEmitter dispatchCustomEvent:event];
}

@end
