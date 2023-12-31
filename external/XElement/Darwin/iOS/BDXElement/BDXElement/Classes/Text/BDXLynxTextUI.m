//
//  BDXLynxTextUI.m
//  BDXElement
//
//

#import "BDXLynxTextUI.h"
#import "BDXLynxRichTextStyle.h"
#import "BDXLynxInlineEventTarget.h"

#import <Lynx/LynxComponentRegistry.h>
#import <Lynx/LynxPropsProcessor.h>
#import <Lynx/LynxUI+Internal.h>

@interface YYLabel(T)

- (YYTextLayout *)_innerLayout;

@end

@interface BDXLynxTextUI()<UIGestureRecognizerDelegate>

@end

@interface BDXLynxLabel : YYLabel
@property (nonatomic, strong) NSString *lynxAccessibilityLabel;
@end

@implementation BDXLynxLabel

- (void)setAccessibilityLabel:(NSString *)accessibilityLabel {
  [super setAccessibilityLabel:accessibilityLabel];
  self.lynxAccessibilityLabel = accessibilityLabel;
}

- (NSString *)accessibilityLabel {
  if (self.lynxAccessibilityLabel) {
    return self.lynxAccessibilityLabel;
  }
  return [super accessibilityLabel];
}

@end

@implementation BDXLynxTextUI {
    YYLabel * _truncationLabel;
    NSMutableDictionary<NSNumber*, BDXLynxEventTargetSpan*> *_subSpan;
    NSMutableDictionary<NSNumber*, BDXLynxEventTargetSpan*> *_truncationSubSpan;
    BOOL _dirty;
}

#if LYNX_LAZY_LOAD
LYNX_LAZY_REGISTER_UI("x-text")
#else
LYNX_REGISTER_UI("x-text")
#endif

- (UIView *)createView
{
    BDXLynxLabel *label = [BDXLynxLabel new];
    label.font = [UIFont systemFontOfSize:14.f];
    label.textColor = [UIColor blackColor];
    label.displaysAsynchronously = YES;
    label.lineBreakMode = NSLineBreakByTruncatingTail;
    label.backgroundColor = [UIColor clearColor];
    label.fadeOnAsynchronouslyDisplay = NO;
    label.textVerticalAlignment = YYTextVerticalAlignmentTop;
    
    return label;
}

- (void)onReceiveUIOperation:(id)value
{
    if (value && [value isKindOfClass:[BDXLynxRichTextStyle class]]) {
        [self configDisplaysAsynchronouslyIfNeed];
        BDXLynxRichTextStyle *textStyle = value;
        // clear previouse truncationToken
        self.view.truncationToken = nil;
        if (textStyle.textModel) {
            self.view.textLayout = textStyle.textModel.textLayout;
            _truncationLabel = textStyle.textModel.truncationLabel;
        } else {
            self.view.font = textStyle.font;
            self.view.textColor = textStyle.textColor;
            self.view.numberOfLines = textStyle.numberOfLines;
            self.view.attributedText = textStyle.ultimateAttributedString;
            if (textStyle.truncatingMode != 0) {
                self.view.lineBreakMode = (NSLineBreakMode)textStyle.truncatingMode;
            }
    
            
            if (textStyle.truncationAttributeString) {
                _truncationLabel = [YYLabel new];
                _truncationLabel.attributedText = textStyle.truncationAttributeString;
                [_truncationLabel sizeToFit];
                self.view.truncationToken = [NSAttributedString yy_attachmentStringWithContent:_truncationLabel contentMode:UIViewContentModeCenter attachmentSize:_truncationLabel.bounds.size alignToFont:textStyle.font alignment:YYTextVerticalAlignmentCenter];
            } else {
                _truncationLabel = nil;
            }
        }
        [self didRender];
        _dirty = YES;
    }
}   

#pragma mark - Actions

- (void)didRender
{
    LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:@"onlayout" targetSign:[self sign] detail:@{@"width" : @(self.view.frame.size.width), @"height" : @(self.view.frame.size.height)}];
    [self.context.eventEmitter sendCustomEvent:event];
}

- (NSMutableDictionary<NSNumber*, BDXLynxEventTargetSpan*>*)subSpanOf:(YYLabel*)label withOrigin:(CGPoint)origin {
    __block NSMutableDictionary<NSNumber*, BDXLynxEventTargetSpan*>* subSpan = [NSMutableDictionary new];
    NSAttributedString* str = label.attributedText;
    YYTextLayout* layout = label._innerLayout;
    // visible text length exclude truncation
    NSInteger visibleStrLength = str.length;
    if(layout.truncatedLine && layout.lines.count > 0){
        NSInteger strLengthExcludeLastLine = layout.lines[layout.lines.count-1].range.location;
        if(layout.truncatedLine.attachmentRanges.count > 0){
            // attachment contains image and truncation, find the truncation
            NSInteger truncationAttachmentIndex = 0;
            for (int i = 0; i < layout.truncatedLine.attachments.count; i++) {
                if([layout.truncatedLine.attachments[i].content isKindOfClass:[BDXLynxLabel class]]){
                    truncationAttachmentIndex = i;
                    break;
                }
            }
            visibleStrLength = strLengthExcludeLastLine + layout.truncatedLine.attachmentRanges[truncationAttachmentIndex].rangeValue.location;
        }
    }
    
    [str enumerateAttributesInRange:NSMakeRange(0, str.length)
                            options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
                         usingBlock:^(NSDictionary<NSAttributedStringKey, id> * _Nonnull attrs,
                                      NSRange range,
                                      BOOL * _Nonnull stop) {
        
        YYTextRange* visibleTextRange = [YYTextRange rangeWithRange:range];
        if(range.location + range.length > visibleStrLength){
            visibleTextRange = [YYTextRange rangeWithRange:NSMakeRange(range.location, visibleStrLength - range.location)];
        }
        NSArray *rects = [layout selectionRectsForRange:visibleTextRange];
        [attrs enumerateKeysAndObjectsUsingBlock:^(NSAttributedStringKey  _Nonnull key,
                                                   id  _Nonnull obj,
                                                   BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[BDXLynxTextInfo class]]) {
                BDXLynxTextInfo *info = (BDXLynxTextInfo *)obj;
                if (info && [subSpan objectForKey:[NSNumber numberWithInteger:info.sign]] == nil) {
                    [rects enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        if ([obj isKindOfClass:[YYTextSelectionRect class]]) {
                            YYTextSelectionRect* yyRect = (YYTextSelectionRect*)obj;
                            yyRect.rect = CGRectOffset(yyRect.rect, origin.x, origin.y);
                        }
                    }];
                    [subSpan setObject:[[BDXLynxEventTargetSpan alloc] initWithInfo:info withRects:rects]
                               forKey:[NSNumber numberWithInteger:info.sign]];
                }
            }
        }];
    }];

    return subSpan;
}

- (void)ensureSubSpan {
    if (!_dirty) {
        return;
    }
    _subSpan = [self subSpanOf:self.view withOrigin:CGPointZero];
    if (_truncationLabel != nil) {
        _truncationSubSpan = [self subSpanOf:_truncationLabel withOrigin:_truncationLabel.frame.origin];
    }
    _dirty = NO;
}

- (id<LynxEventTarget>)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    [self ensureSubSpan];
    for (id key in _truncationSubSpan) {
        if ([_truncationSubSpan[key] containsPoint:point]) {
            [_truncationSubSpan[key] setParentEventTarget:self];
            return _truncationSubSpan[key];
        }
    }
    for (id key in _subSpan) {
        if ([_subSpan[key] containsPoint:point]) {
            [_subSpan[key] setParentEventTarget:self];
            return _subSpan[key];
        }
    }
    return [super hitTest:point withEvent:event];
}

-(void) setAsyncDisplayFromTTML:(BOOL)async {
  [super setAsyncDisplayFromTTML:async];
  self.view.displaysAsynchronously = async;
}

- (void)configDisplaysAsynchronouslyIfNeed {
  if ([self.view respondsToSelector:@selector(setDisplaysAsynchronously:)]) {
    self.view.displaysAsynchronously = _asyncDisplayFromTTML;
  }
}

-(void) frameDidChange {
  [super frameDidChange];
  
  UIEdgeInsets insets = UIEdgeInsetsMake(self.border.top + self.padding.top, self.border.left + self.padding.left, self.border.bottom + self.padding.bottom, self.border.right + self.padding.right);
  // handle border and padding in UI
  self.view.textContainerInset = insets;
}

- (NSString *)accessibilityText {
  return self.view.text;
}

@end
