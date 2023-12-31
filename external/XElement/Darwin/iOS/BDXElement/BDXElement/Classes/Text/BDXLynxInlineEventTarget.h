// Copyright 2019 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>
#import <Lynx/LynxEventTarget.h>
#import <Lynx/LynxShadowNode.h>


NS_ASSUME_NONNULL_BEGIN

@interface BDXLynxTextInfo : NSObject

@property(nonatomic, assign) NSInteger sign;
@property(nonatomic, assign) NSInteger parentSign;
@property(nonatomic, readonly) BOOL ignoreFocus;
@property(nonatomic, readonly) BOOL enableTouchPseudoPropagation;
@property(nonatomic, readonly) enum LynxEventPropStatus eventThrough;
@property(nonatomic, readonly, nullable) NSDictionary<NSString*, LynxEventSpec*>* eventSet;

- (instancetype)initWithShadowNode:(LynxShadowNode*)node;

@end

@interface BDXLynxEventTargetSpan : NSObject <LynxEventTarget>

- (instancetype)initWithInfo:(BDXLynxTextInfo*)info withRects:(NSArray*)rects;

- (void)setParentEventTarget:(id<LynxEventTarget>)parent;

@end

NS_ASSUME_NONNULL_END
