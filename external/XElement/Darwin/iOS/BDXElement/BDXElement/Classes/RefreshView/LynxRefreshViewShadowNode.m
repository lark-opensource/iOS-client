//  Copyright 2022 The Lynx Authors. All rights reserved.

#import "LynxRefreshViewShadowNode.h"
#import <Lynx/LynxComponentRegistry.h>
#import "BDXLynxRefreshView.h"
#import "BDXLynxRefreshHeader.h"
#import "BDXLynxRefreshFooter.h"
#import <Lynx/LynxNativeLayoutNode.h>
#import <Lynx/LynxUICollection.h>

@interface LynxRefreshViewShadowNode ()

@property (nonatomic, assign) CGSize headerSize;
@property (nonatomic, assign) CGSize footerSize;
@property (nonatomic, assign) CGSize listSize;

@end

@implementation LynxRefreshViewShadowNode

#if LYNX_LAZY_LOAD
LYNX_LAZY_REGISTER_SHADOW_NODE("x-refresh-view")
#else
LYNX_REGISTER_SHADOW_NODE("x-refresh-view")
#endif

- (MeasureResult)customMeasureLayoutNode:(nonnull MeasureParam *)param
                          measureContext:(nullable MeasureContext *)context {
    NSArray *child = self.children;
    [child enumerateObjectsUsingBlock:
     ^(LynxShadowNode * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        BOOL supported = YES;
        Class clz = [LynxComponentRegistry uiClassWithName:obj.tagName accessible:&supported];
        if (supported && [obj isKindOfClass:[LynxNativeLayoutNode class]]) {
            LynxNativeLayoutNode *child = (LynxNativeLayoutNode *)obj;
            MeasureParam *cParam = [[MeasureParam alloc] initWithWidth:param.width
                                                             WidthMode:param.widthMode
                                                                Height:param.height
                                                            HeightMode:param.heightMode];
            if ([clz isEqual:([BDXLynxRefreshHeader class])]) {
                _headerSize =  [child measureWithMeasureParam:cParam MeasureContext:context].size;
            } else if ([clz isEqual:[LynxUICollection class]] || [clz isEqual:[LynxUIComponent class]]) {
                _listSize = [child measureWithMeasureParam:cParam MeasureContext:context].size;
            } else if ([clz isEqual:([BDXLynxRefreshFooter class])]) {
                _footerSize = [child measureWithMeasureParam:cParam MeasureContext:context].size;
            }
        }
    }];
    return (MeasureResult){CGSizeMake(param.width, param.height)};
}

- (void)customAlignLayoutNode:(nonnull AlignParam *)param
                 alignContext:(nonnull AlignContext *)context {
    [self.children enumerateObjectsUsingBlock:
     ^(LynxShadowNode * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[LynxNativeLayoutNode class]]) {
            LynxNativeLayoutNode *child = (LynxNativeLayoutNode *)obj;
            AlignParam *param = [[AlignParam alloc] init];
            [param SetAlignOffsetWithLeft:0 Top:0];
            [child alignWithAlignParam:param AlignContext:context];
        }
    }];
}


@end
