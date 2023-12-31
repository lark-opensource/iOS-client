// Copyright 2021 The Lynx Authors. All rights reserved.

#import "KryptonApp.h"
#import "LynxKryptonHelper.h"

@interface LynxKryptonApp : KryptonApp <LynxKryptonHelper>
@property(nonatomic, readonly, nullable) NSString* temporaryDirectory;
@property(nonatomic, readonly, nullable) id<LynxKryptonEffectHandlerProtocol> effectHandler;
@end
