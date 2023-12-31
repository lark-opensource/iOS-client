// Copyright 2019 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>
#import "LynxLayoutNode.h"
#import "LynxShadowNodeStyle.h"
#import "LynxUIOwner.h"

@class LynxShadowNode;

NS_ASSUME_NONNULL_BEGIN

// TODO(heshan):now ShadowNode invoke LynxUIOwner directly on ios
// platfrom, in fact need through LayoutResultProcessor...
@protocol LynxShadowNodeDelegate <NSObject>

- (void)updateExtraData:(NSInteger)sign value:(id)value;
- (void)updateLayout:(NSInteger)sign
          layoutLeft:(CGFloat)left
                 top:(CGFloat)top
               width:(CGFloat)width
              height:(CGFloat)height;
- (void)finishLayoutOperation;

@end

@interface LynxShadowNode : LynxLayoutNode <LynxShadowNode*>
@property(nonatomic, readonly) NSInteger sign;
@property(nonatomic, readonly) NSString* tagName;
@property(nonatomic, weak, readonly) LynxUIOwner* uiOwner;
@property(nonatomic, readonly) LynxShadowNodeStyle* shadowNodeStyle;
@property(nonatomic, readonly) BOOL isDestroy;
@property(nonatomic, readonly) BOOL needsEventSet;
@property(nonatomic, readonly) BOOL ignoreFocus;
@property(nonatomic, readonly) BOOL enableTouchPseudoPropagation;
@property(nonatomic, readonly) enum LynxEventPropStatus eventThrough;
@property(nonatomic, readwrite, nullable) NSDictionary<NSString*, LynxEventSpec*>* eventSet;

- (instancetype)initWithSign:(NSInteger)sign tagName:(NSString*)tagName;

- (void)setUIOperation:(LynxUIOwner*)owner;
- (void)setDelegate:(id<LynxShadowNodeDelegate>)delegate;
- (void)postExtraDataToUI:(id)value;
- (void)postFrameToUI:(CGRect)frame;
- (void)destroy;
/// Subclass need to override this function if need to pass custom bundle from ShadowNode to LynxUI
- (id)getExtraBundle;
- (void)setVerticalAlignOnShadowNode:(BOOL)requestReset value:(NSArray*)value;

/**
 * Virtual node will not be layout and doesn't have a ui
 */
- (BOOL)isVirtual;

- (BOOL)supportInlineView;

@end

NS_ASSUME_NONNULL_END
