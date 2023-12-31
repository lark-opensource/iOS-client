// Copyright 2019 The Lynx Authors. All rights reserved.

#import "LynxUIView.h"

NS_ASSUME_NONNULL_BEGIN

@class LynxUIComponent;

@protocol LynxUIComponentLayoutObserver <NSObject>

- (void)onComponentLayoutUpdated:(LynxUIComponent*)component;
- (void)onAsyncComponentLayoutUpdated:(LynxUIComponent*)component operationID:(int64_t)operationID;

@end

@interface LynxUIComponent : LynxUIView

@property(weak) id<LynxUIComponentLayoutObserver> layoutObserver;
@property(nonatomic, strong) NSString* itemKey;

- (void)asyncListItemRenderFinished:(int64_t)operationID;

@end

NS_ASSUME_NONNULL_END
