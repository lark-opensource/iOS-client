// Copyright 2019 The Lynx Authors. All rights reserved.

#import "LynxUIText.h"
#import "LynxComponentRegistry.h"
#import "LynxPropsProcessor.h"
#import "LynxUI+Internal.h"
#import "LynxUIUnitUtils.h"
#import "LynxUnitUtils.h"
#import "LynxView+Internal.h"

@interface LynxUITextDrawParameter : NSObject

@property(nonatomic) LynxTextRenderer *renderer;
@property(nonatomic) UIEdgeInsets padding;
@property(nonatomic) UIEdgeInsets border;
@property(nonatomic) CGPoint overflowLayerOffset;

@end

@interface LynxCALayerDelegate : NSObject <CALayerDelegate>

@end

@implementation LynxCALayerDelegate

- (id<CAAction>)actionForLayer:(CALayer *)layer forKey:(NSString *)event {
  return (id)[NSNull null];
}

@end

@implementation LynxUITextDrawParameter

@end

@implementation LynxUIText {
  LynxTextRenderer *_renderer;
  LynxLinearGradient *_gradient;
  LynxTextOverflowLayer *_overflow_layer;
  LynxCALayerDelegate *_delegate;
  BOOL _isHasSubSpan;
}

#if LYNX_LAZY_LOAD
LYNX_LAZY_REGISTER_UI("text")
#else
LYNX_REGISTER_UI("text")
#endif

LYNX_PROPS_GROUP_DECLARE(LYNX_PROP_DECLARE("text-selection", setEnableTextSelection, BOOL))

- (instancetype)initWithView:(LynxTextView *)view {
  self = [super initWithView:view];
  if (self != nil) {
    // disable text async-display by default
    // user can enable this by adding async-display property on ttml element
    [self setAsyncDisplayFromTTML:NO];
  }
  return self;
}

- (void)setContext:(LynxUIContext *)context {
  [super setContext:context];
  if (self.context.enableTextOverflow) {
    self.overflow = OVERFLOW_XY_VAL;
    self.view.clipsToBounds = NO;
  }
}

- (LynxTextView *)createView {
  LynxTextView *view = [LynxTextView new];
  view.opaque = NO;
  view.contentMode = UIViewContentModeScaleAspectFit;
  view.ui = self;
  return view;
}

- (void)_lynxUIRequestDisplay {
  if (self.renderer == nil || self.frame.size.width <= 0 || self.frame.size.height <= 0) {
    return;
  }
  self.view.layer.contents = nil;
  [self.view.contentLayer setContents:nil];
  [_overflow_layer setContents:nil];
  [self requestDisplayAsynchronsly];
}

- (void)frameDidChange {
  [super frameDidChange];
  self.view.contentLayer.frame = CGRectMake(0, 0, self.frameSize.width, self.frameSize.height);
  if ([self enableLayerRender]) {
    self.view.border = self.border;
    self.view.padding = self.padding;
    if (self.overflow != OVERFLOW_HIDDEN_VAL) {
      [[self getOverflowLayer] setNeedsDisplay];
    } else {
      [self.view.contentLayer setNeedsDisplay];
    }
  } else {
    [self _lynxUIRequestDisplay];
  }
}

- (void)onReceiveUIOperation:(id)value {
  if (value && [value isKindOfClass:LynxTextRenderer.class]) {
    _isHasSubSpan = false;
    _renderer = value;

    for (LynxTextAttachmentInfo *attachment in _renderer.attachments) {
      [self.children enumerateObjectsUsingBlock:^(LynxUI *_Nonnull child, NSUInteger idx,
                                                  BOOL *_Nonnull stop) {
        if (child.sign == attachment.sign) {
          CGFloat scale = [UIScreen mainScreen].scale;
          if (attachment.nativeAttachment) {
            if (CGRectIsEmpty(attachment.frame) && ![child.view isHidden]) {
              [child.view setHidden:YES];
              [child.backgroundManager setHidden:YES];
            } else if (!CGRectIsEmpty(attachment.frame) && [child.view isHidden]) {
              [child.view setHidden:NO];
              [child.backgroundManager setHidden:NO];
            }
          } else {
            CGRect frame = attachment.frame;
            frame.origin.x = round(frame.origin.x * scale) / scale;
            frame.origin.y = round(frame.origin.y * scale) / scale;
            frame.size.width = round(frame.size.width * scale) / scale;
            frame.size.height = round(frame.size.height * scale) / scale;
            [child updateFrame:frame
                        withPadding:UIEdgeInsetsZero
                             border:UIEdgeInsetsZero
                withLayoutAnimation:NO];
          }

          *stop = true;
        }
      }];
    }

    if (self.useDefaultAccessibilityLabel) {
      self.view.accessibilityLabel = _renderer.attrStr.string;
    }
    // update selection color
    [self.view updateSelectionColor:_renderer.selectionColor];
    self.view.textRenderer = _renderer;
    if ([self enableLayerRender]) {
      if (self.overflow != OVERFLOW_HIDDEN_VAL) {
        [[self getOverflowLayer] setNeedsDisplay];
      } else {
        [self.view.contentLayer setNeedsDisplay];
      }
    } else {
      [self _lynxUIRequestDisplay];
    }
  }
}

- (void)requestDisplayAsynchronsly {
  __weak typeof(self) weakSelf = self;
  [self displayAsyncWithCompletionBlock:^(UIImage *_Nonnull image) {
    CALayer *layer = nil;
    if (weakSelf.overflow != OVERFLOW_HIDDEN_VAL) {
      layer = [weakSelf getOverflowLayer];
      layer.frame = CGRectMake(-[weakSelf overflowLayerOffset].x, -[weakSelf overflowLayerOffset].y,
                               image.size.width, image.size.height);
    } else {
      layer = weakSelf.view.contentLayer;
    }
    layer.contents = (id)image.CGImage;
    layer.contentsScale = [LynxUIUnitUtils screenScale];
  }];
}

- (CGSize)frameSize {
  if (self.overflow != OVERFLOW_HIDDEN_VAL) {
    CGSize size = [_renderer textsize];
    CGFloat width = size.width > self.frame.size.width ? size.width : self.frame.size.width;
    CGFloat height = size.height > self.frame.size.height ? size.height : self.frame.size.height;
    return CGSizeMake(width + 2 * [self overflowLayerOffset].x,
                      height + 2 * [self overflowLayerOffset].y);
  }
  return self.frame.size;
}

- (void)addOverflowLayer {
  _overflow_layer = [[LynxTextOverflowLayer alloc] initWithView:self.view];
  if (_delegate == nil) {
    _delegate = [[LynxCALayerDelegate alloc] init];
  }
  _overflow_layer.delegate = _delegate;
  [self.view.layer addSublayer:_overflow_layer];
}

- (CALayer *)getOverflowLayer {
  if (!_overflow_layer) {
    [self addOverflowLayer];
  }
  _overflow_layer.frame = CGRectMake(-self.overflowLayerOffset.x, -self.overflowLayerOffset.y,
                                     self.frameSize.width, self.frameSize.height);
  return _overflow_layer;
}

- (LynxTextRenderer *)renderer {
  return _renderer;
}

- (NSString *)accessibilityText {
  return _renderer.attrStr.string;
}

- (void)dealloc {
  // TODO refactor
  if (_overflow_layer) {
    if ([NSThread isMainThread]) {
      _overflow_layer.delegate = nil;
    } else {
      LynxTextOverflowLayer *overflow_layer = _overflow_layer;
      dispatch_async(dispatch_get_main_queue(), ^{
        overflow_layer.delegate = nil;
      });
    }
  }
}

- (id)drawParameter {
  LynxUITextDrawParameter *para = [[LynxUITextDrawParameter alloc] init];
  para.renderer = self.renderer;
  para.border = self.backgroundManager.borderWidth;
  para.padding = self.padding;
  para.overflowLayerOffset = [self overflowLayerOffset];
  return para;
}

- (CGPoint)overflowLayerOffset {
  if (self.overflow == 0x00 || _renderer == nil) {
    return CGPointZero;
  }
  return CGPointMake(0, _renderer.maxfontsize);
}

+ (void)drawRect:(CGRect)bounds withParameters:(id)drawParameters {
  LynxUITextDrawParameter *param = drawParameters;
  LynxTextRenderer *renderer = param.renderer;
  UIEdgeInsets padding = param.padding;
  UIEdgeInsets border = param.border;
  bounds.origin = CGPointMake(param.overflowLayerOffset.x, param.overflowLayerOffset.y);
  [renderer drawRect:bounds padding:padding border:border];
}

- (id<LynxEventTarget>)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
  if (!_isHasSubSpan) {
    [self.renderer genSubSpan];
    _isHasSubSpan = true;
  }
  for (LynxEventTargetSpan *span in _renderer.subSpan) {
    if ([span containsPoint:point]) {
      [span setParentEventTarget:self];
      return span;
    }
  }
  return [super hitTest:point withEvent:event];
}

- (BOOL)enableAccessibilityByDefault {
  return YES;
}

- (UIAccessibilityTraits)accessibilityTraitsByDefault {
  return UIAccessibilityTraitStaticText;
}

- (BOOL)enableAsyncDisplay {
  BOOL isIOSAppOnMac = NO;
  if (@available(iOS 14.0, *)) {
    // https://github.com/firebase/firebase-ios-sdk/issues/6969
    isIOSAppOnMac = ([[NSProcessInfo processInfo] respondsToSelector:@selector(isiOSAppOnMac)] &&
                     [NSProcessInfo processInfo].isiOSAppOnMac);
  }
  // https://t.wtturl.cn/R91Suay/
  // if running on Mac with M1 chip, disable async render
  return [super enableAsyncDisplay] && !isIOSAppOnMac;
}

- (BOOL)enableLayerRender {
  return [((LynxView *)self.context.rootView) enableTextLayerRender];
}

LYNX_PROP_DEFINE("text-selection", setEnableTextSelection, BOOL) {
  if (requestReset) {
    value = NO;
  }

  self.view.enableTextSelection = value;
}

@end
