// Copyright 2021 The Lynx Authors. All rights reserved.
//
//  BDXLynxInputShadowNode.m
//  XElement
//
//  Created by zhangkaijie on 2021/12/13.
//

#import <Foundation/Foundation.h>
#import <Lynx/LynxCustomMeasureShadowNode.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDXLynxInputShadowNode : LynxCustomMeasureShadowNode<LynxCustomMeasureDelegate>

@property (nonatomic, assign, readwrite) BOOL needRelayout;
@property (nonatomic, assign, readwrite) CGFloat mHeightAtMost;
@property (nonatomic, assign, readwrite) CGFloat mWidthAtMost;
@property (atomic, strong, readwrite) UIFont *fontFromUI;
@property (atomic, strong, readwrite) NSNumber *textHeightFromUI;


@end

NS_ASSUME_NONNULL_END
