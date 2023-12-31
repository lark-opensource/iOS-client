// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef DARWIN_COMMON_LYNX_EVENT_LYNXEVENT_H_
#define DARWIN_COMMON_LYNX_EVENT_LYNXEVENT_H_

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - LynxTouchPseudoState
FOUNDATION_EXPORT int32_t const LynxTouchPseudoStateNone;
FOUNDATION_EXPORT int32_t const LynxTouchPseudoStateHover;
FOUNDATION_EXPORT int32_t const LynxTouchPseudoStateHoverTransition;
FOUNDATION_EXPORT int32_t const LynxTouchPseudoStateActive;
FOUNDATION_EXPORT int32_t const LynxTouchPseudoStateActiveTransition;
FOUNDATION_EXPORT int32_t const LynxTouchPseudoStateFocus;
FOUNDATION_EXPORT int32_t const LynxTouchPseudoStateFocusTransition;
FOUNDATION_EXPORT int32_t const LynxTouchPseudoStateAll;

#pragma mark - LynxEvent
/**
 * The basic event with event name only. Waring: do not use LynxEvent directly.
 */
@interface LynxEvent : NSObject

@property(nonatomic, readonly) NSInteger targetSign;
@property(nonatomic, readonly) NSInteger currentTargetSign;
@property(nonatomic, copy, readonly) NSString* eventName;

- (instancetype)initWithName:(NSString*)name;

- (instancetype)initWithName:(NSString*)name targetSign:(NSInteger)target;

- (instancetype)initWithName:(NSString*)name
                  targetSign:(NSInteger)target
           currentTargetSign:(NSInteger)currentTarget;

// TODO(yxping): coalesce event
- (BOOL)canCoalesce;
- (NSMutableDictionary*)generateEventBody;

@end

/**
 * Custom event will contain detail object on the event body which can be used
 * as extra data on front-end.
 */
@interface LynxCustomEvent : LynxEvent

@property(nonatomic, readonly, nullable) NSDictionary* params;

- (instancetype)initWithName:(NSString*)name
                  targetSign:(NSInteger)target
                      params:(nullable NSDictionary*)params;

- (instancetype)initWithName:(NSString*)name
                  targetSign:(NSInteger)target
           currentTargetSign:(NSInteger)currentTarget
                      params:(nullable NSDictionary*)params;

/**
 There return value decide how to access the params on
 front-end. Such as "params" was the return value, you can access the result on front-end by
 event.params.xx.
 */
- (NSString*)paramsName;

@end

@interface LynxDetailEvent : LynxCustomEvent

@property(nonatomic, readonly, nullable) NSDictionary* detail;

- (instancetype)initWithName:(NSString*)name
                  targetSign:(NSInteger)target
                      detail:(nullable NSDictionary*)detail;

- (instancetype)initWithName:(NSString*)name
                  targetSign:(NSInteger)target
           currentTargetSign:(NSInteger)currentTarget
                      detail:(nullable NSDictionary*)detail;

@end

NS_ASSUME_NONNULL_END

#endif  // DARWIN_COMMON_LYNX_EVENT_LYNXEVENT_H_
