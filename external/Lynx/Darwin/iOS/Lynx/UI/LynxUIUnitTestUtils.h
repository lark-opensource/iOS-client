//  Copyright 2023 The Lynx Authors. All rights reserved.
#import "LynxEventEmitter.h"

@class LynxUI;
@class LynxUIContext;

@interface LynxEventEmitterUnitTestHelper : LynxEventEmitter
@property(nonatomic, readonly) LynxCustomEvent *event;
@end

@interface LynxUIMockContext : NSObject
@property(nonatomic) LynxUI *mockUI;
@property(nonatomic) LynxUIContext *mockUIContext;
@property(nonatomic) LynxEventEmitter *mockEventEmitter;
@end

@interface LynxUIUnitTestUtils : NSObject
+ (LynxUIMockContext *)initUIMockContextWithUI:(LynxUI *)ui;
@end
