//  Copyright 2023 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>
@class LynxView;

NS_ASSUME_NONNULL_BEGIN

enum EVENT_TYPE {
  TOUCH_EVENT,
};

#pragma mark - LynxEventDetail
@interface LynxEventDetail : NSObject

- (instancetype)initWithEvent:(enum EVENT_TYPE)type name:(NSString*)name lynxView:(LynxView*)view;
@property enum EVENT_TYPE eventType;
@property(nonatomic, copy, readonly) NSString* eventName;
@property(nonatomic, weak, nullable) LynxView* lynxView;

#pragma mark - TouchEvent
@property CGPoint targetPoint;

@end

NS_ASSUME_NONNULL_END
