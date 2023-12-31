// Copyright 2019 The Lynx Authors. All rights reserved.
//
//  LynxAnimationInfo.h
//  Lynx
//
//  Created by lybvinci on 2020/8/27.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "LynxCSSType.h"
#import "LynxConverter.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSUInteger, LynxAnimationProp) {
  // The value of those properties must be consistent with C++ AnimationPropertyType.
  NONE = 0,
  OPACITY = 1 << 0,
  SCALE_X = 1 << 1,
  SCALE_Y = 1 << 2,
  SCALE_XY = 1 << 3,
  TRANSITION_WIDTH = 1 << 4,
  TRANSITION_HEIGHT = 1 << 5,
  TRANSITION_BACKGROUND_COLOR = 1 << 6,
  TRANSITION_VISIBILITY = 1 << 7,
  TRANSITION_LEFT = 1 << 8,
  TRANSITION_TOP = 1 << 9,
  TRANSITION_RIGHT = 1 << 10,
  TRANSITION_BOTTOM = 1 << 11,
  TRANSITION_TRANSFORM = 1 << 12,
  TRANSITION_COLOR = 1 << 13,
  TRANSITION_ALL = OPACITY | TRANSITION_WIDTH | TRANSITION_HEIGHT | TRANSITION_BACKGROUND_COLOR |
                   TRANSITION_VISIBILITY | TRANSITION_LEFT | TRANSITION_RIGHT | TRANSITION_TOP |
                   TRANSITION_BOTTOM | TRANSITION_TRANSFORM | TRANSITION_COLOR,

  TRANSITION_LAYOUT = TRANSITION_WIDTH | TRANSITION_HEIGHT | TRANSITION_LEFT | TRANSITION_TOP |
                      TRANSITION_RIGHT | TRANSITION_BOTTOM,
  TRANSITION_LAYOUT_POSITION_X = TRANSITION_LEFT | TRANSITION_RIGHT,
  TRANSITION_LAYOUT_POSITION_Y = TRANSITION_TOP | TRANSITION_BOTTOM,
};

@interface LynxAnimationInfo : NSObject <NSCopying>

typedef void (^CompletionBlock)(BOOL finished);
@property(nonatomic, copy, nullable) CompletionBlock completeBlock;
@property(nonatomic, assign) NSTimeInterval duration;
@property(nonatomic, assign) NSTimeInterval delay;
@property(nonatomic) LynxAnimationProp prop;
@property(nonatomic, strong) CAMediaTimingFunction *timingFunction;
@property(nonatomic, strong) NSString *name;
@property(nonatomic, assign) CGFloat iterationCount;
@property(nonatomic, assign) LynxAnimationDirectionType direction;
@property(nonatomic, strong) CAMediaTimingFillMode fillMode;
@property(nonatomic, assign) LynxAnimationPlayStateType playState;
@property(nonatomic, assign) int orderIndex;
- (instancetype)initWithName:(NSString *)name;
- (BOOL)isEqualToKeyframeInfo:(LynxAnimationInfo *)info;
- (BOOL)isOnlyPlayStateChanged:(LynxAnimationInfo *)info;

+ (BOOL)isDirectionReverse:(LynxAnimationInfo *)info;
+ (BOOL)isDirectionAlternate:(LynxAnimationInfo *)info;
+ (BOOL)isFillModeRemoved:(LynxAnimationInfo *)info;
+ (LynxAnimationInfo *)copyAnimationInfo:(LynxAnimationInfo *)info withProp:(LynxAnimationProp)prop;
+ (void)removeDuplicateAnimation:
            (NSMutableDictionary<NSNumber *, LynxAnimationInfo *> *)animationInfos
                         withKey:(LynxAnimationProp)lhsKey
                       sameToKey:(LynxAnimationProp)rhsKey;
+ (void)makePositionAndSizeTimingInfoConsistent:
            (NSMutableDictionary<NSNumber *, LynxAnimationInfo *> *)animationInfos
                                withPositionKey:(LynxAnimationProp)positionKey
                                    withSizeKey:(LynxAnimationProp)sizeKey;
@end

@interface LynxConverter (LynxAnimationInfo)
+ (LynxAnimationInfo *)toKeyframeAnimationInfo:(id)value;
+ (LynxAnimationInfo *)toTransitionAnimationInfo:(id)value;
@end

@interface LynxConverter (LynxAnimationPropType)
+ (LynxAnimationProp)toLynxAnimationProp:(id)value;
+ (NSString *)toLynxPropName:(LynxAnimationProp)prop;
@end

NS_ASSUME_NONNULL_END
