// Copyright 2019 The Lynx Authors. All rights reserved.

#import "LynxTextView.h"
#import "LynxComponentRegistry.h"
#import "LynxLayer.h"
#import "LynxTextRenderer.h"
#import "LynxUIText.h"
#import "LynxWeakProxy.h"

#pragma mark - LynxTextLayerRender
@interface LynxTextLayerRender : NSObject <CALayerDelegate>
@property(nonatomic, weak) LynxTextRenderer *textRenderer;
@property(nonatomic, assign) UIEdgeInsets border;
@property(nonatomic, assign) UIEdgeInsets padding;

@end

@implementation LynxTextLayerRender

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx {
  LynxTextRenderer *strongRender = self.textRenderer;

  CGRect frame = CGRectMake(0, 0, layer.frame.size.width, layer.frame.size.height);

  UIGraphicsPushContext(ctx);
  [strongRender drawRect:frame padding:self.padding border:self.border];
  UIGraphicsPopContext();
}

@end

#pragma mark - LynxTextView

@interface LynxTextView () <UIGestureRecognizerDelegate>
/// selection drawing
@property(nonatomic, strong) LynxLayer *selectionLayer;
@property(nonatomic, strong) LynxLayer *startDot;
@property(nonatomic, strong) LynxLayer *endDot;
@property(nonatomic, strong) UIColor *selectColor;
@property(nonatomic, strong) UIColor *caretColor;
@property(nonatomic, strong) NSTimer *longPressTimer;
/// selection info
@property(nonatomic, assign) CGPoint touchBeganPoint;
@property(nonatomic, assign) CGPoint trackingPoint;
@property(nonatomic, assign) NSInteger selectionStart;
@property(nonatomic, assign) NSInteger selectionEnd;
/// selection state
@property(nonatomic, assign) BOOL trackingTouch;
@property(nonatomic, assign) BOOL trackingMove;
@property(nonatomic, assign) BOOL menuShowing;
@property(nonatomic, assign) BOOL showCaret;
@property(nonatomic, strong) UILongPressGestureRecognizer *longPressGesture;
@property(nonatomic, strong) UIPanGestureRecognizer *hoverGesture;
@property(nonatomic, strong) UITapGestureRecognizer *tapGesture;

@end

@implementation LynxTextView {
  LynxTextLayerRender *_layerRender;
}

+ (Class)layerClass {
  return [LynxLayer class];
}

- (instancetype)init {
  self = [super init];
  if (self) {
    self.contentLayer = [LynxLayer new];
    self.contentLayer.contentsScale = [[UIScreen mainScreen] scale];
    self.layer.contentsScale = [[UIScreen mainScreen] scale];
    // https://developer.apple.com/documentation/quartzcore/calayer/1410974-drawsasynchronously?language=objc
    // make drawInContext method queued draw command and execute in background thread
    self.contentLayer.drawsAsynchronously = YES;

    [self.layer addSublayer:self.contentLayer];

    _layerRender = [LynxTextLayerRender new];
    self.contentLayer.delegate = _layerRender;

    [self initSelectionLayers];
    self.enableTextSelection = NO;
    self.userInteractionEnabled = YES;

    self.longPressGesture =
        [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                      action:@selector(handleLongPress:)];
    self.longPressGesture.delegate = self;

    self.hoverGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                action:@selector(handleMove:)];
    self.hoverGesture.delegate = self;

    self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                              action:@selector(handleCancelTap:)];
    self.tapGesture.delegate = self;
  }
  return self;
}

- (void)initSelectionLayers {
  self.selectionLayer = [LynxLayer new];
  [self.layer insertSublayer:self.selectionLayer below:self.contentLayer];

  self.selectColor = [UIColor.systemBlueColor colorWithAlphaComponent:0.5f];

  self.caretColor = UIColor.systemBlueColor;

  self.selectionStart = self.selectionEnd = -1;

  self.startDot = [LynxLayer new];
  self.endDot = [LynxLayer new];

  self.startDot.frame = self.endDot.frame = CGRectMake(0, 0, 10, 10);
  self.startDot.cornerRadius = self.endDot.cornerRadius = 5.0;
  self.startDot.backgroundColor = self.endDot.backgroundColor = self.caretColor.CGColor;
}

- (void)updateSelectionColor:(UIColor *)color {
  if (color == nil) {
    self.selectColor = [UIColor.systemBlueColor colorWithAlphaComponent:0.5];
    self.caretColor = UIColor.systemBlueColor;
  } else {
    self.selectColor = [color colorWithAlphaComponent:0.5];
    self.caretColor = [color copy];
  }
}

- (NSString *)description {
  NSString *superDescription = super.description;
  NSRange semicolonRange = [superDescription rangeOfString:@";"];
  NSString *replacement =
      [NSString stringWithFormat:@"; text: %@", _ui.renderer.layoutManager.textStorage.string];
  return [superDescription stringByReplacingCharactersInRange:semicolonRange
                                                   withString:replacement];
}

- (NSString *)text {
  return _ui.renderer.attrStr.string;
}

- (void)setBorder:(UIEdgeInsets)border {
  _border = border;
  _layerRender.border = border;
}

- (void)setPadding:(UIEdgeInsets)padding {
  _padding = padding;
  _layerRender.padding = padding;
}

- (void)setTextRenderer:(LynxTextRenderer *)textRenderer {
  _textRenderer = textRenderer;
  _layerRender.textRenderer = textRenderer;
}

- (void)layoutSublayersOfLayer:(CALayer *)layer {
  if (layer != self.layer) {
    return;
  }
  [self updateSelectionHighlights];
}

- (void)setEnableTextSelection:(BOOL)enableTextSelection {
  _enableTextSelection = enableTextSelection;

  if (_enableTextSelection) {
    [self installGestures];
  } else {
    [self unInstallGestures];
  }
}

#pragma mark - SelectionControl
- (CGPoint)convertPointToLayout:(CGPoint)point {
  point.x -= (self.padding.left + self.border.left);
  point.y -= (self.padding.top + self.border.left);

  return point;
}

- (NSUInteger)getGlyphOffsetByPoint:(CGPoint)point {
  return [self.textRenderer.layoutManager
      glyphIndexForPoint:point
         inTextContainer:[self.textRenderer.layoutManager.textContainers firstObject]];
}

- (void)updateSelectionHighlights {
  self.selectionLayer.sublayers = nil;

  if (self.selectionStart == -1 || self.selectionEnd == -1) {
    return;
  }

  NSInteger start = MIN(self.selectionStart, self.selectionEnd);
  NSInteger length = ABS(self.selectionEnd - self.selectionStart);

  [self.textRenderer.layoutManager
      enumerateEnclosingRectsForGlyphRange:NSMakeRange(start, length)
                  withinSelectedGlyphRange:NSMakeRange(start, length)
                           inTextContainer:[self.textRenderer.layoutManager
                                                   .textContainers firstObject]
                                usingBlock:^(CGRect rect, BOOL *_Nonnull stop) {
                                  CALayer *highlight = [LynxLayer new];
                                  if (rect.size.width > 0) {
                                    highlight.backgroundColor = self.selectColor.CGColor;
                                  } else {
                                    rect.size.width = 1;
                                    highlight.backgroundColor = self.caretColor.CGColor;
                                  }

                                  highlight.frame = rect;

                                  [self.selectionLayer addSublayer:highlight];
                                }];

  if (!self.showCaret) {
    return;
  }

  CGRect startFrame = [self.textRenderer.layoutManager
      boundingRectForGlyphRange:NSMakeRange(start, 0)
                inTextContainer:self.textRenderer.layoutManager.textContainers.firstObject];

  CGRect endFrame = [self.textRenderer.layoutManager
      boundingRectForGlyphRange:NSMakeRange(start + length, 0)
                inTextContainer:self.textRenderer.layoutManager.textContainers.firstObject];

  // start cursor
  self.startDot.frame =
      CGRectMake(MAX(startFrame.origin.x, 0) - 5 + 1, MAX(startFrame.origin.y, 0) - 10, 10, 10);
  CALayer *startCursor = [LynxLayer new];
  startCursor.frame = CGRectMake(MAX(startFrame.origin.x, 0), MAX(startFrame.origin.y, 0), 2,
                                 startFrame.size.height);
  startCursor.backgroundColor = self.caretColor.CGColor;

  self.startDot.backgroundColor = self.caretColor.CGColor;

  [self.selectionLayer addSublayer:self.startDot];
  [self.selectionLayer addSublayer:startCursor];

  // end cursor
  CGPoint endOrigin = endFrame.origin;
  endOrigin.y += endFrame.size.height;

  self.endDot.frame = CGRectMake(MIN(endOrigin.x, self.frame.size.width) - 5,
                                 MIN(endOrigin.y, self.frame.size.height), 10, 10);

  CALayer *endCursor = [LynxLayer new];
  endCursor.frame =
      CGRectMake(MIN(endFrame.origin.x, self.frame.size.width) - 1,
                 MIN(endFrame.origin.y, self.frame.size.height), 2, endFrame.size.height);
  endCursor.backgroundColor = self.caretColor.CGColor;

  self.endDot.backgroundColor = self.caretColor.CGColor;

  [self.selectionLayer addSublayer:self.endDot];
  [self.selectionLayer addSublayer:endCursor];
}

- (void)clearSelectionHighlight {
  self.selectionStart = -1;
  self.selectionEnd = -1;

  [self.layer setNeedsLayout];
}

#pragma mark - Menu control

- (void)unsetMenuHideListener {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)registMenuHideListener {
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(didHideEditMenu:)
                                               name:UIMenuControllerDidHideMenuNotification
                                             object:nil];
}

- (void)didHideEditMenu:(NSNotification *)notification {
  [self clearSelectionHighlight];

  if (![self isFirstResponder]) {
    // reset touch tracing state
    self.trackingTouch = NO;
    self.trackingMove = NO;
  }
}

- (void)hideMenu {
  if (!self.menuShowing) {
    return;
  }

  [self unsetMenuHideListener];

  UIMenuController *menu = [UIMenuController sharedMenuController];
  [menu setMenuVisible:NO animated:YES];
  self.menuShowing = NO;
}

- (void)showMenu {
  CGRect rect;
  if ([self.selectionLayer.sublayers count] == 0) {
    // if no selection layer, it means this is the first time need to show floating toolbar
    // in this case, use the touch begin point as anchor point
    rect = CGRectMake(self.touchBeganPoint.x, self.touchBeganPoint.y, 1, 1);
  } else {
    rect = [self.selectionLayer.sublayers firstObject].frame;

    for (NSUInteger i = 1; i < [self.selectionLayer.sublayers count]; i++) {
      rect = CGRectUnion(rect, [self.selectionLayer.sublayers objectAtIndex:i].frame);
    }

    CGRect inter = CGRectIntersection(rect, self.frame);
    if (!CGRectIsNull(inter) && inter.size.height > 1) {
      rect = inter;
    } else {
      rect.size.height = 1;
      if (CGRectGetMinX(rect) < CGRectGetMinY(self.frame)) {
        rect.origin.y = CGRectGetMinY(self.frame);
      } else {
        rect.origin.y = CGRectGetMaxY(self.frame);
      }
    }
  }

  if (!self.isFirstResponder) {
    [self becomeFirstResponder];
  }

  if (!self.isFirstResponder) {
    return;
  }

  UIMenuController *menu = [UIMenuController sharedMenuController];

  rect.origin.x -= self.frame.origin.x;
  rect.origin.y -= self.frame.origin.y;

  [menu setTargetRect:rect inView:self];
  [menu update];
  [menu setMenuVisible:YES animated:YES];

  self.menuShowing = YES;
  [self registMenuHideListener];
}

#pragma mark - UIResponder
- (BOOL)canBecomeFirstResponder {
  if (!self.enableTextSelection) {
    return NO;
  }

  if (!self.trackingTouch) {
    return NO;
  }

  return YES;
}

#pragma mark - Menu Action

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
  return action == @selector(selectAll:) || action == @selector(copy:);
}

- (void)copy:(id)sender {
  self.trackingTouch = NO;
  self.trackingMove = NO;

  NSInteger start = MIN(self.selectionStart, self.selectionEnd);
  NSInteger length = ABS(self.selectionEnd - self.selectionStart);

  if (start == -1 || length == 0) {
    return;
  }

  NSString *string =
      [self.textRenderer.attrStr attributedSubstringFromRange:NSMakeRange(start, length)].string;
  // write to pasteboard
  [UIPasteboard generalPasteboard].string = string;

  // clear selection
  [self clearSelectionHighlight];
}

- (void)selectAll:(id)sender {
  self.selectionStart = 0;
  self.selectionEnd = self.textRenderer.attrStr.length;

  [self.layer setNeedsLayout];
  [self unsetMenuHideListener];

  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)),
                 dispatch_get_main_queue(), ^{
                   [self showMenu];
                 });
}

#pragma mark - UIGestureRecognizer
- (void)handleLongPress:(UIGestureRecognizer *)sender {
  if (!self.trackingTouch && !self.trackingMove) {
    self.trackingTouch = YES;
    self.trackingMove = NO;

    self.touchBeganPoint = self.trackingPoint = [sender locationInView:self];

    CGPoint trackingPoint = [self convertPointToLayout:self.trackingPoint];

    self.selectionStart = self.selectionEnd = [self getGlyphOffsetByPoint:trackingPoint];

    if (self.selectionStart - 1 >= 0) {
      self.selectionStart -= 1;
    }

    if (self.selectionEnd + 1 < (NSInteger)self.textRenderer.attrStr.length) {
      self.selectionEnd += 1;
    }

    [self.layer setNeedsLayout];
    [self showMenu];
  }
}

- (void)handleMove:(UIPanGestureRecognizer *)sender {
  if (!self.trackingTouch) {
    return;
  }

  CGPoint point = [sender locationInView:self];

  point = [self convertPointToLayout:point];
  self.trackingMove = true;

  NSInteger glyphOffset = [self getGlyphOffsetByPoint:point];

  if (glyphOffset <= (self.selectionStart + self.selectionEnd) / 2) {
    self.selectionStart = glyphOffset;
  } else {
    self.selectionEnd = glyphOffset;
  }

  if (sender.state == UIGestureRecognizerStateEnded) {
    if (!self.trackingTouch) {
      [self clearSelectionHighlight];
      [self hideMenu];
      return;
    }

    // show menu
    [self showMenu];
    // show caret
    self.showCaret = YES;
  }

  [self.layer setNeedsLayout];
}

- (void)handleCancelTap:(UITapGestureRecognizer *)sender {
  CGPoint point = [sender locationInView:self];

  point = [self convertPointToLayout:point];

  NSInteger glyphOffset = [self getGlyphOffsetByPoint:point];

  if (glyphOffset >= self.selectionStart && glyphOffset <= self.selectionEnd) {
    if (self.menuShowing) {
      [self hideMenu];
    } else {
      [self showMenu];
    }
    return;
  }

  // clear selection and hide menu if needed
  self.trackingTouch = NO;
  self.trackingMove = NO;

  [self clearSelectionHighlight];
  [self hideMenu];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
    shouldRecognizeSimultaneouslyWithGestureRecognizer:
        (UIGestureRecognizer *)otherGestureRecognizer {
  return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
    shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
  return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
    shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
  if (gestureRecognizer == self.longPressGesture && otherGestureRecognizer != self.hoverGesture) {
    return YES;
  }
  return NO;
}

- (void)installGestures {
  [self addGestureRecognizer:self.longPressGesture];
  [self addGestureRecognizer:self.hoverGesture];
  [self addGestureRecognizer:self.tapGesture];
}

- (void)unInstallGestures {
  [self removeGestureRecognizer:self.longPressGesture];
  [self removeGestureRecognizer:self.hoverGesture];
  [self removeGestureRecognizer:self.tapGesture];
}

@end
