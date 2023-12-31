// Copyright 2019 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>
#import "LynxLayoutTick.h"
#import "LynxShadowNode.h"
#import "LynxUIOwner.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, LynxShadowNodeType) {
  LynxShadowNodeTypeCommon = 1,
  LynxShadowNodeTypeVirtual = 1 << 1,
  LynxShadowNodeTypeCustom = 1 << 2,
  //  LynxShadowNodeTypeFlatten = 1 << 3,
  LynxShadowNodeTypeList = 1 << 4,
  LynxShadowNodeTypeInlineView = 1 << 5,
  LynxShadowNodeTypePlatformNodeAttached = 1 << 6,
};

@class LynxComponentRegistry;

@interface LynxShadowNodeOwner : NSObject

@property(atomic, readonly, nullable) LynxLayoutTick* layoutTick;
@property(nonatomic, weak, readonly) LynxUIContext* uiContext;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithUIOwner:(LynxUIOwner*)uiOwner
              componentRegistry:(LynxComponentScopeRegistry*)registry
                     layoutTick:(LynxLayoutTick*)layoutTick
                  isAsyncRender:(BOOL)isAsyncRender
                        context:(LynxUIContext*)context;

- (void)setDelegate:(id<LynxShadowNodeDelegate>)delegate;

- (void)shadowNodeStatistic:(NSString*)tagName;

- (NSInteger)createNodeWithSign:(NSInteger)sign
                        tagName:(nonnull NSString*)tagName
                          props:(nullable NSDictionary*)props
                       eventSet:(nullable NSSet<NSString*>*)eventSet
                  lepusEventSet:(nullable NSSet<NSString*>*)lepusEventSet
                  layoutNodePtr:(long)ptr
        isParentInlineContainer:(bool)isParentInlineContainer;

- (void)updateNodeWithSign:(NSInteger)sign
                     props:(nullable NSDictionary*)props
                  eventSet:(nullable NSSet<NSString*>*)eventSet
             lepusEventSet:(nullable NSSet<NSString*>*)lepusEventSet;

- (void)insertNode:(NSInteger)childSign toParent:(NSInteger)parentSign atIndex:(NSInteger)index;

- (void)removeNode:(NSInteger)childSign fromParent:(NSInteger)parentSign atIndex:(NSInteger)index;

- (void)moveNode:(NSInteger)childSign
        inParent:(NSInteger)parentSign
       fromIndex:(NSInteger)from
         toIndex:(NSInteger)to;

- (void)destroyNode:(NSInteger)sign;

- (void)didLayoutStartOnNode:(NSInteger)sign;

- (void)didUpdateLayoutLeft:(CGFloat)left
                        top:(CGFloat)top
                      width:(CGFloat)width
                     height:(CGFloat)height
                     onNode:(NSInteger)sign;

- (void)didLayoutFinished;

- (void)destroy;
- (void)destroySelf;

- (LynxShadowNode*)nodeWithSign:(NSInteger)sign;

- (void)updateRootSize:(float)width height:(float)height;
- (float)rootWidth;
- (float)rootHeight;
@end

NS_ASSUME_NONNULL_END
