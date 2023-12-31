// Copyright 2020 The Lynx Authors. All rights reserved.

#import <UIKit/UIKit.h>
#import "LynxUI.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^LynxHeliumErrorCallback)(NSString* _Nullable errorMessage);

@protocol LynxHeliumErrorHandlerProtocol <NSObject>
- (void)onError:(NSString* _Nullable)errorString;
@end

@interface LynxHeliumConfig : NSObject
+ (void)setForceEnableCanvas;
+ (void)setOnErrorCallback:(LynxHeliumErrorCallback _Nullable)callback;
+ (void)setSmashUrlFallback:(NSString* _Nullable)url autoCheckSettings:(bool)autoCheckSettings;
+ (void)setForceEnableAutoDestroyHelium;
+ (void)addWeakErrorHandler:(id<LynxHeliumErrorHandlerProtocol> _Nonnull)handler;
+ (void)removeWeakErrorHandler:(id<LynxHeliumErrorHandlerProtocol> _Nonnull)handler;
@end

@interface LynxHeliumCanvasView : UIView
@end

@interface LynxHeliumCanvas : LynxUI <LynxHeliumCanvasView*>
@end

NS_ASSUME_NONNULL_END
