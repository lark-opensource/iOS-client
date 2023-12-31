// Copyright 2020 The Lynx Authors. All rights reserved.

#import "BDXLynxTextAreaShadowNode.h"
#import "BDXLynxTextArea.h"
#import <Lynx/LynxComponentRegistry.h>
#import <Lynx/LynxUIOwner.h>
#import <Lynx/LynxPropsProcessor.h>
#import <Lynx/LynxNativeLayoutNode.h>

#pragma mark - BDXLynxTextAreaShadowNode
@implementation BDXLynxTextAreaShadowNode {
    CGFloat _minHeight;
    CGFloat _maxHeight;
}

#if LYNX_LAZY_LOAD
+(void)lynxLazyLoad {
    LYNX_BASE_INIT_METHOD
    [LynxComponentRegistry registerShadowNode:self withName:@"textarea"];
    [LynxComponentRegistry registerShadowNode:self withName:@"x-textarea"];
}
#else
+(void)load {
    [LynxComponentRegistry registerShadowNode:self withName:@"textarea"];
    [LynxComponentRegistry registerShadowNode:self withName:@"x-textarea"];
}
#endif


- (instancetype)initWithSign:(NSInteger)sign tagName:(NSString *)tagName {
    self = [super initWithSign:sign tagName:tagName];
    if (self) {
      _isAutoSize = YES;
      _minHeight = CGFLOAT_MIN;
      _maxHeight = CGFLOAT_MAX;
      _needRelayout = NO;
      _mHeightAtMost = CGFLOAT_MAX;
      _mWidthAtMost = CGFLOAT_MAX;
    }
    return self;
}

- (CGFloat)floatWithNSStr:(NSString*)str {
    if (str.length > 3 && [str hasSuffix:@"rpx"]) {
      CGFloat f = [[str substringToIndex:str.length - 3] floatValue];
      return f * [UIScreen mainScreen].bounds.size.width / 750;
    } else if (str.length > 2 && [str hasSuffix:@"px"]) {
      return [[str substringToIndex:str.length - 2] floatValue];
    } else {
      return 0;
    }
}

LYNX_PROP_SETTER("min-height", setMinHeight, NSString*) {
    if (requestReset) {
        _minHeight = CGFLOAT_MIN;
        return;
    }
    _minHeight = [self floatWithNSStr:value];
    [self setNeedsLayout];
}

LYNX_PROP_SETTER("max-height", setMaxHeight, NSString*) {
    if (requestReset) {
        _maxHeight = CGFLOAT_MAX;
        return;
    }
    _maxHeight = [self floatWithNSStr:value];
    [self setNeedsLayout];
}

- (void)adoptNativeLayoutNode:(int64_t)ptr {
    [self setCustomMeasureDelegate:self];
    [super adoptNativeLayoutNode:ptr];
}

- (BOOL)updateSizeIfNeeded {
    if (!_isAutoSize) {
        return NO;
    }
    if ([NSThread isMainThread]) {
      _fontFromUI = nil;
      _textHeightFromUI = nil;
      _heightFromUI = nil;
      LynxUI* ui = [self.uiOwner findUIBySign:self.sign];
      BDXLynxTextArea* area = (BDXLynxTextArea*)ui;
      _fontFromUI = area.view.font;
      _textHeightFromUI = @(area.textHeight);
      _heightFromUI = @(area.frame.size.height);
    }
    if (_fontFromUI == nil) {
        return NO;
    }
    
    if (_textHeightFromUI) {
      CGFloat intrinsicTextHeight = [_textHeightFromUI doubleValue];//area.textHeight;
        if (_minHeight > 0) {
            intrinsicTextHeight = MAX(_minHeight, intrinsicTextHeight);
        }
        if (_maxHeight > 0) {
            intrinsicTextHeight = MIN(_maxHeight, intrinsicTextHeight);
        }
        if (_mHeightAtMost != CGFLOAT_MAX) {
            intrinsicTextHeight = MIN(_mHeightAtMost, intrinsicTextHeight);
        }
        if (intrinsicTextHeight != [_heightFromUI doubleValue]) {
            [self setNeedsLayout];
            return YES;
        } else {
            return NO;
        }
    }
    
    return NO;
}

- (MeasureResult)customMeasureLayoutNode:(nonnull MeasureParam *)param
                          measureContext:(nullable MeasureContext *)context {
    if ([NSThread isMainThread]) {
      _fontFromUI = nil;
      _textHeightFromUI = nil;
      _heightFromUI = nil;
      LynxUI* ui = [self.uiOwner findUIBySign:self.sign];
      BDXLynxTextArea *input = nil;
      if (ui != nil && [ui isKindOfClass:[BDXLynxTextArea class]]) {
        input = (BDXLynxTextArea*)ui;
        _fontFromUI = input.view.font;
        _textHeightFromUI = @(input.textHeight);
        _heightFromUI = @(input.frame.size.height);
      }
    }
    
    MeasureResult res;
    res.size = CGSizeMake(param.width, param.height);
    if (_fontFromUI != nil) {
        UIFont *font = _fontFromUI;
        res.baseline = font.ascender + font.leading;
    } else {
        res.baseline = 0.0f;
    }
    
    if ((param.heightMode == LynxMeasureModeDefinite && param.widthMode == LynxMeasureModeDefinite) ||
        _fontFromUI == nil) {
        if (_fontFromUI == nil) {
            _needRelayout = YES;
        }
        return res;
    }

    if (_textHeightFromUI != nil) {
        _mHeightAtMost = CGFLOAT_MAX;
        _mWidthAtMost = CGFLOAT_MAX;
        if (param.heightMode == LynxMeasureModeIndefinite) {
            res.size.height = [_textHeightFromUI doubleValue];
            res.size.height = MAX(_minHeight, res.size.height);
            res.size.height = MIN(_maxHeight, res.size.height);
        } else if (param.heightMode == LynxMeasureModeAtMost) {
            _mHeightAtMost = res.size.height;
            res.size.height = [_textHeightFromUI doubleValue];
            res.size.height = MAX(_minHeight, res.size.height);
            res.size.height = MIN(_maxHeight, res.size.height);
            res.size.height = MIN(_mHeightAtMost, res.size.height);
        }
        if (param.widthMode == LynxMeasureModeIndefinite) {
            // TODO widthMode can not be Indefinite now
        } else if (param.widthMode == LynxMeasureModeAtMost) {
            
        }
    }

    // measure inputAccessoryView child.
    [self.children enumerateObjectsUsingBlock:
    ^(LynxShadowNode * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
    if ([obj isKindOfClass:[LynxNativeLayoutNode class]]) {
      // inputAccessoryView's width is always equal to the screen, its child should be measured correctly
      MeasureParam *childParam = [[MeasureParam alloc] initWithWidth:UIScreen.mainScreen.bounds.size.width
                                                           WidthMode:LynxMeasureModeDefinite
                                                              Height:UIScreen.mainScreen.bounds.size.height
                                                          HeightMode:LynxMeasureModeAtMost];
      LynxNativeLayoutNode *child = (LynxNativeLayoutNode *)obj;
      [child measureWithMeasureParam:childParam MeasureContext:context];
    }
    }];
    
    return res;
}


- (void)customAlignLayoutNode:(nonnull AlignParam *)param
                 alignContext:(nonnull AlignContext *)context {
  [self.children enumerateObjectsUsingBlock:
   ^(LynxShadowNode * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
    if ([obj isKindOfClass:[LynxNativeLayoutNode class]]) {
      LynxNativeLayoutNode *child = (LynxNativeLayoutNode *)obj;
      AlignParam *param = [[AlignParam alloc] init];
      // apply margin to child
      [param SetAlignOffsetWithLeft:child.style.computedMarginLeft Top:child.style.computedMarginTop];
      [child alignWithAlignParam:param AlignContext:context];
    }
  }];
}

- (void)alignWithAlignParam:(nonnull AlignParam *)param
               AlignContext:(nonnull AlignContext *)context {
  [self customAlignLayoutNode:param alignContext:context];
}

- (MeasureResult)measureWithMeasureParam:(nonnull MeasureParam *)param
                          MeasureContext:(nullable MeasureContext *)context {
  MeasureResult result = [self customMeasureLayoutNode:param measureContext:context];
  return result;
}

@end
