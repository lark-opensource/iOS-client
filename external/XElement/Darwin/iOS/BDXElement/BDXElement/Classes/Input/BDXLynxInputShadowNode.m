// Copyright 2021 The Lynx Authors. All rights reserved.
//
//  BDXLynxInputShadowNode.m
//  XElement
//
//  Created by zhangkaijie on 2021/12/13.
//

#import "BDXLynxInputShadowNode.h"
#import "BDXLynxInput.h"
#import <Lynx/LynxComponentRegistry.h>
#import <Lynx/LynxUIOwner.h>
#import <Lynx/LynxPropsProcessor.h>
#import <Lynx/LynxNativeLayoutNode.h>

#pragma mark - BDXLynxTextAreaShadowNode
@implementation BDXLynxInputShadowNode {
}

#if LYNX_LAZY_LOAD
+(void)lynxLazyLoad {
    LYNX_BASE_INIT_METHOD
    [LynxComponentRegistry registerShadowNode:self withName:@"input"];
    [LynxComponentRegistry registerShadowNode:self withName:@"x-input"];
}
#else
+(void)load {
    [LynxComponentRegistry registerShadowNode:self withName:@"input"];
    [LynxComponentRegistry registerShadowNode:self withName:@"x-input"];
}
#endif

- (instancetype)initWithSign:(NSInteger)sign tagName:(NSString *)tagName {
    self = [super initWithSign:sign tagName:tagName];
    if (self) {
        _needRelayout = NO;
        _mHeightAtMost = CGFLOAT_MAX;
        _mWidthAtMost = CGFLOAT_MAX;
    }
    return self;
}

- (void)adoptNativeLayoutNode:(int64_t)ptr {
  [self setCustomMeasureDelegate:self];
  [super adoptNativeLayoutNode:ptr];
}

- (MeasureResult)customMeasureLayoutNode:(nonnull MeasureParam *)param
                          measureContext:(nullable MeasureContext *)context {
    if ([NSThread isMainThread]) {
      _fontFromUI = nil;
      _textHeightFromUI = nil;
      LynxUI* ui = [self.uiOwner findUIBySign:self.sign];
      BDXLynxInput *input = nil;
      if (ui != nil && [ui isKindOfClass:[BDXLynxInput class]]) {
        input = (BDXLynxInput*)ui;
      }
      _fontFromUI = [input.view font];
      _textHeightFromUI = @(input.textHeight);
    }
    
    MeasureResult res;
    res.size = CGSizeMake(param.width, param.height);
    if (param.widthMode == LynxMeasureModeAtMost) {
        res.size.width = 0;
    }
    if (_fontFromUI != nil) {
        res.baseline = _fontFromUI.ascender + _fontFromUI.leading;
    } else {
        res.baseline = 0.0f;
    }
    
    if ((param.heightMode == LynxMeasureModeDefinite && param.widthMode == LynxMeasureModeDefinite) ||
        _fontFromUI == nil) {
        if (_fontFromUI == nil) {
            _needRelayout = YES;
        } else {
            _needRelayout = NO;
        }
        return res;
    }

    if (_textHeightFromUI != nil) {
        _mHeightAtMost = CGFLOAT_MAX;
        _mWidthAtMost = CGFLOAT_MAX;
        if (param.heightMode == LynxMeasureModeIndefinite) {
            res.size.height =  [_textHeightFromUI doubleValue];
        } else if (param.heightMode == LynxMeasureModeAtMost) {
            _mHeightAtMost = res.size.height;
          res.size.height =  [_textHeightFromUI doubleValue];
            res.size.height = MIN(_mHeightAtMost, res.size.height);
        }
        if (param.widthMode == LynxMeasureModeIndefinite) {
            // TODO widthMode can not be Indefinite now
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
