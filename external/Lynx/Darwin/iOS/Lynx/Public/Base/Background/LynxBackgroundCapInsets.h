// Copyright 2021 The Lynx Authors. All rights reserved.

@class LynxUI;

@interface LynxBackgroundCapInsets : NSObject
@property(nonatomic, assign) UIEdgeInsets capInsets;
@property(nonatomic, weak) LynxUI* ui;
- (instancetype)initWithParams:(NSString*)capInsetsString;
- (void)reset;
@end
