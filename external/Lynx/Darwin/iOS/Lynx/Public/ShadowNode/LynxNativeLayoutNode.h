// Copyright 2021 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>
#import "LynxCustomMeasureDelegate.h"
#import "LynxShadowNode.h"

NS_ASSUME_NONNULL_BEGIN
@interface LynxNativeLayoutNode : LynxShadowNode
- (MeasureResult)measureWithMeasureParam:(MeasureParam *)param
                          MeasureContext:(MeasureContext *)context;
- (void)alignWithAlignParam:(AlignParam *)param AlignContext:(AlignContext *)context;
@end
NS_ASSUME_NONNULL_END
