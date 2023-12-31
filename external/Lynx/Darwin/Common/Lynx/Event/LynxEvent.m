// Copyright 2019 The Lynx Authors. All rights reserved.
#import "LynxEvent.h"

int32_t const LynxTouchPseudoStateNone = 0;
int32_t const LynxTouchPseudoStateHover = 1;
int32_t const LynxTouchPseudoStateHoverTransition = 1 << 1;
int32_t const LynxTouchPseudoStateActive = 1 << 3;
int32_t const LynxTouchPseudoStateActiveTransition = 1 << 4;
int32_t const LynxTouchPseudoStateFocus = 1 << 6;
int32_t const LynxTouchPseudoStateFocusTransition = 1 << 7;
int32_t const LynxTouchPseudoStateAll = ~0;

@implementation LynxEvent

- (instancetype)initWithName:(NSString*)name {
  self = [super init];
  if (self) {
    _eventName = name;
  }
  return self;
}

- (instancetype)initWithName:(NSString*)name targetSign:(NSInteger)target {
  return [self initWithName:name targetSign:target currentTargetSign:target];
}

- (instancetype)initWithName:(NSString*)name
                  targetSign:(NSInteger)target
           currentTargetSign:(NSInteger)currentTarget {
  self = [self initWithName:name];
  if (self) {
    _currentTargetSign = currentTarget;
    _targetSign = target;
  }
  return self;
}

- (BOOL)canCoalesce {
  return NO;
}

- (NSMutableDictionary*)generateEventBody {
  NSMutableDictionary* body = [NSMutableDictionary new];
  body[@"type"] = _eventName;
  body[@"target"] = [NSNumber numberWithInteger:_targetSign];
  body[@"currentTarget"] = [NSNumber numberWithInteger:_currentTargetSign];
  return body;
}

@end

@implementation LynxCustomEvent

- (instancetype)initWithName:(NSString*)name
                  targetSign:(NSInteger)target
                      params:(NSDictionary*)params {
  return [self initWithName:name targetSign:target currentTargetSign:target params:params];
}

- (instancetype)initWithName:(NSString*)name
                  targetSign:(NSInteger)target
           currentTargetSign:(NSInteger)currentTarget
                      params:(NSDictionary*)params {
  self = [super initWithName:name targetSign:target currentTargetSign:currentTarget];
  if (self) {
    _params = params;
  }
  return self;
}

- (NSDictionary*)generateEventBody {
  NSMutableDictionary* body = [super generateEventBody];
  body[[self paramsName]] = _params;
  return body;
}

- (NSString*)paramsName {
  return @"params";
}

@end

@implementation LynxDetailEvent

- (instancetype)initWithName:(NSString*)name
                  targetSign:(NSInteger)target
                      detail:(NSDictionary*)detail {
  return [super initWithName:name targetSign:target currentTargetSign:target params:detail];
}

- (instancetype)initWithName:(NSString*)name
                  targetSign:(NSInteger)target
           currentTargetSign:(NSInteger)currentTarget
                      detail:(nullable NSDictionary*)detail {
  return [super initWithName:name targetSign:target currentTargetSign:currentTarget params:detail];
}

- (NSString*)paramsName {
  return @"detail";
}

@end
