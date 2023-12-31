// Copyright 2019 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "LynxHeroModifiers.h"
#import "LynxUI.h"

NS_ASSUME_NONNULL_BEGIN
@class LynxAnimationInfo;
@interface LynxHeroViewConfig : NSObject
// sharedElement 和 content 动画仅有一个起作用，sharedElement 优先，如果找不到则使用 content 动画
// 描述 sharedElement 动画
@property(nonatomic, copy) NSString* sharedElementName;
@property(nonatomic, assign) BOOL crossPage;
@property(nonatomic) LynxHeroModifiers* sharedElementModifiers;
// Lynx 描述 content 动画的快捷方式
@property(nonatomic, copy) LynxAnimationInfo* enterTransitionName;
@property(nonatomic, copy) LynxAnimationInfo* exitTransitionName;
@property(nonatomic, copy) LynxAnimationInfo* pauseTransiitonName;
@property(nonatomic, copy) LynxAnimationInfo* resumeTransitionName;
// 原生 UIView 描述动画使用
@property(nonatomic) LynxHeroModifiers* enterTransitionModifiers;
@property(nonatomic) LynxHeroModifiers* exitTransitionModifiers;
// 是否要截图，仅对 shared-element 动画的元素有效
@property(nonatomic, assign) BOOL snapshot;
// 是否要提层级
@property(nonatomic, assign) BOOL merge;
@property(nonatomic, weak) LynxUI* lynxUI;
@property(nonatomic, readonly, weak) UIView* view;

- (instancetype)initWithView:(UIView*)view;

@end

@interface UIView (LynxHeroTransition)
@property(nonatomic, readonly) LynxHeroViewConfig* lynxHeroConfig;
@end

NS_ASSUME_NONNULL_END
