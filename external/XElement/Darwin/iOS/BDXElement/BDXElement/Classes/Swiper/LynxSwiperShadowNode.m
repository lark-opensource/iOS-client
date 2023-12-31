//  Copyright 2022 The Lynx Authors. All rights reserved.

#import "LynxSwiperShadowNode.h"
#import <Lynx/LynxComponentRegistry.h>
#import <Lynx/LynxNativeLayoutNode.h>
#import "BDXLynxSwiperView.h"
#import <Lynx/LynxUnitUtils.h>
#import <Lynx/LynxPropsProcessor.h>

@interface LynxSwiperShadowNode ()

@property (nonatomic, assign) CGFloat previousMargin;
@property (nonatomic, assign) CGFloat nextMargin;
@property (nonatomic, assign) CGFloat itemSpacing;
@property (nonatomic, assign) CGFloat itemHeight;
@property (nonatomic, assign) CGFloat itemWidth;
@property (nonatomic, assign) CGFloat xScale;
@property (nonatomic, assign) CGFloat yScale;
@property (nonatomic, assign) BOOL compatible;
@property (nonatomic, assign) BOOL vertical;
@property (nonatomic, assign) BDXLynxSwiperTransformLayoutType layoutType;

@end

@implementation LynxSwiperShadowNode

#if LYNX_LAZY_LOAD
LYNX_LAZY_REGISTER_SHADOW_NODE("swiper")
#else
LYNX_REGISTER_SHADOW_NODE("swiper")
#endif

- (instancetype)initWithSign:(NSInteger)sign tagName:(NSString *)tagName {
    if (self = [super initWithSign:sign tagName:tagName]) {
        _xScale = 1;
        _yScale = 1;
        _compatible = YES;
    }
    return self;
}

LYNX_PROP_SETTER("previous-margin", previousMargin, NSString *)
{
    _previousMargin = [LynxUnitUtils toPtFromUnitValue:value withDefaultPt:0];
    if (_previousMargin < 0 || _previousMargin > [UIScreen mainScreen].bounds.size.width) {
        _previousMargin = 0;
    }
    if (self.hasCustomLayout) {
        [self setNeedsLayout];
    }
}

LYNX_PROP_SETTER("next-margin", nextMargin, NSString *)
{
    _nextMargin = [LynxUnitUtils toPtFromUnitValue:value withDefaultPt:0];
    if (_nextMargin < 0 || _nextMargin > [UIScreen mainScreen].bounds.size.width) {
        _nextMargin = 0;
    }
    if (self.hasCustomLayout) {
        [self setNeedsLayout];
    }
}

LYNX_PROP_SETTER("page-margin", pageMargin, NSString *)
{
    _itemSpacing = [self toPtWithUnitValue:value fontSize:0];;
    if (_itemSpacing < 0 || _itemSpacing > [UIScreen mainScreen].bounds.size.width) {
        _itemSpacing = 0;
    }
    if (self.hasCustomLayout) {
        [self setNeedsLayout];
    }
}

LYNX_PROP_SETTER("item-width", itemWidth, NSString *)
{
    _itemWidth = [self toPtWithUnitValue:value fontSize:0];
    if (self.hasCustomLayout) {
        [self setNeedsLayout];
    }
}

LYNX_PROP_SETTER("item-height", itemHeight, NSString *)
{
    _itemHeight = [self toPtWithUnitValue:value fontSize:0];
    if (self.hasCustomLayout) {
        [self setNeedsLayout];
    }
}


LYNX_PROP_SETTER("max-x-scale", minXScale, NSNumber *)
{
    if ([value doubleValue] >= 0) {
        _xScale = [value doubleValue];
        if (self.hasCustomLayout) {
            [self setNeedsLayout];
        }
    }
}


LYNX_PROP_SETTER("max-y-scale", minYScale, NSNumber *)
{
    if ([value doubleValue] >= 0) {
        _yScale = [value doubleValue];
        if (self.hasCustomLayout) {
            [self setNeedsLayout];
        }
    }
}

LYNX_PROP_SETTER("mode", swiperMode, NSString *)
{
    BDXLynxSwiperTransformLayoutType lastLayoutType = self.layoutType;
    if ([value isEqualToString:@"normal"]) {
        self.layoutType = BDXLynxSwiperTransformLayoutNormal;
    } else if ([value isEqualToString:@"carousel"]) {
        self.layoutType = BDXLynxSwiperTransformLayoutLinear;
    } else if ([value isEqualToString:@"coverflow"]) {
        self.layoutType = BDXLynxSwiperTransformLayoutCoverflow;
    } else if ([value isEqualToString:@"flat-coverflow"]) {
        self.layoutType = BDXLynxSwiperTransformLayoutFlatCoverflow;
    } else if ([value isEqualToString:@"multi-pages"]) {
        self.layoutType = BDXLynxSwiperTransformLayoutMultiplePages;
    } else if ([value isEqualToString:@"carry"]) {
        self.layoutType = BDXLynxSwiperTransformLayoutCarry;
    }
    if (lastLayoutType != self.layoutType) {
        if (self.hasCustomLayout) {
            [self setNeedsLayout];
        }
    }
}

LYNX_PROP_SETTER("ios-compatible", markCompatible, BOOL)
{
    self.compatible = value;
    if (self.hasCustomLayout) {
        [self setNeedsLayout];
    }
}

LYNX_PROP_SETTER("vertical", vertical, BOOL)
{
    self.vertical = value;
    if (self.hasCustomLayout) {
        [self setNeedsLayout];
    }
}

#pragma mark - layout

- (MeasureResult)measureWithMeasureParam:(MeasureParam *)param
                          MeasureContext:(MeasureContext *)context {
    __block MeasureParam *cParam;
    [self.children enumerateObjectsUsingBlock:
     ^(LynxShadowNode * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[LynxNativeLayoutNode class]]) {
            LynxNativeLayoutNode *child = (LynxNativeLayoutNode *)obj;
            if (cParam) {
                [child measureWithMeasureParam:cParam MeasureContext:context];
                return;
            }
            
            if (self.layoutType == BDXLynxSwiperTransformLayoutCoverflow ||
                self.layoutType == BDXLynxSwiperTransformLayoutFlatCoverflow) {
                CGFloat pageMargin = 0.f;
                CGFloat totalMargin = 0.f;
                if (self.compatible) {
                    pageMargin = self.itemSpacing * 2;
                }
                totalMargin = self.previousMargin + self.nextMargin + pageMargin;
                cParam = [[MeasureParam alloc] initWithWidth:param.width - (self.vertical ? 0 : totalMargin)
                                                   WidthMode:param.widthMode
                                                      Height:param.height - (self.vertical ? totalMargin : 0)
                                                  HeightMode:param.heightMode];
            } else if (self.layoutType == BDXLynxSwiperTransformLayoutLinear) {
                CGFloat width = 0.f;
                CGFloat height = 0.f;
                if (self.vertical) {
                    height = self.itemHeight ? : param.height * 0.8;
                    width = param.width;
                } else {
                    width = self.itemWidth ? : param.width * 0.8;
                    height = param.height;
                }
                cParam = [[MeasureParam alloc] initWithWidth:width
                                                   WidthMode:param.widthMode
                                                      Height:height
                                                  HeightMode:param.heightMode];
            } else if (self.layoutType == BDXLynxSwiperTransformLayoutCarry) {
                CGFloat pageMargin = 0.f;
                CGFloat totalMargin = 0.f;
                if (self.compatible) {
                    pageMargin = self.itemSpacing * 2;
                }
                totalMargin = self.previousMargin + self.nextMargin + pageMargin;
                cParam = [[MeasureParam alloc] initWithWidth:(param.width - (self.vertical ? 0 : totalMargin)) * self.xScale
                                                   WidthMode:param.widthMode
                                                      Height:(param.height - (self.vertical ? totalMargin : 0)) * self.yScale
                                                  HeightMode:param.heightMode];
            } else {
                cParam = [[MeasureParam alloc] initWithWidth:param.width
                                                   WidthMode:param.widthMode
                                                      Height:param.height
                                                  HeightMode:param.heightMode];
            }
            [child measureWithMeasureParam:cParam MeasureContext:context];
        }
    }];
    return (MeasureResult){CGSizeMake(param.width, param.height)};
}

- (void)alignWithAlignParam:(AlignParam *)param AlignContext:(AlignContext *)ctx {
    [self.children enumerateObjectsUsingBlock:
     ^(LynxShadowNode * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[LynxNativeLayoutNode class]]) {
            LynxNativeLayoutNode *child = (LynxNativeLayoutNode *)obj;
            AlignParam *param = [[AlignParam alloc] init];
            [param SetAlignOffsetWithLeft:0 Top:0];
            [child alignWithAlignParam:param AlignContext:ctx];
        }
    }];
}

@end
