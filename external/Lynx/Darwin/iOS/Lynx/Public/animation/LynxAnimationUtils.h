// Copyright 2019 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>
#import "LynxAnimationDelegate.h"
#import "LynxAnimationInfo.h"
#import "LynxUI.h"

NS_ASSUME_NONNULL_BEGIN

@interface LynxAnimationUtils : NSObject

extern NSString* const DUP_ANI_PREFIX;
extern NSString* const DUP_CONTENT_ANI_PREFIX;
extern NSString* const kAnimationEventStart;
extern NSString* const kAnimationEventEnd;
extern NSString* const kAnimationEventCancel;

+ (CABasicAnimation*)createBasicAnimation:(NSString*)path
                                     from:(id)fromValue
                                       to:(id)toValue
                                     info:(LynxAnimationInfo*)info;
+ (void)applyAnimationProperties:(CAAnimation*)animation
                        withInfo:(LynxAnimationInfo*)info
                        forLayer:(CALayer*)layer;
+ (void)removeAnimation:(LynxUI*)ui withName:(NSString*)animationKey;
+ (void)attachTo:(LynxUI*)ui animation:(CAAnimation*)animation forKey:(NSString*)animationName;
+ (void)attachOpacityTo:(LynxUI*)ui
              animation:(CAAnimation*)animation
                 forKey:(NSString*)animationName;
+ (void)addContentAnimationDelegateTo:(CABasicAnimation*)contentAnimation
                       forTargetLayer:(CALayer*)targetLayer
                          withContent:(UIImage*)content
                             withProp:(LynxAnimationProp)prop;
+ (void)addPathAnimationDelegateTo:(CABasicAnimation*)pathAnimation
                    forTargetLayer:(CAShapeLayer*)targetLayer
                          withPath:(CGPathRef)path
                          withProp:(LynxAnimationProp)prop;

@end

#pragma mark - SyncedTimeHelper
// A singleton object using for all keyframe animator to sync start time
@interface SyncedTimeHelper : NSObject
- (CFTimeInterval)getSyncedTime;
+ (instancetype)shareInstance;
@end

NS_ASSUME_NONNULL_END
