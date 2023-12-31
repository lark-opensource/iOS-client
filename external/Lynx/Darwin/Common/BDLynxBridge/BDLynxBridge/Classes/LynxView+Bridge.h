//
//  LynxView+Bridge.h
//
//  Created by li keliang on 2020/2/9.
//  Copyright © 2020 Lynx. All rights reserved.
//

#import "BDLynxBridgeDefines.h"
#import "LynxTemplateRender.h"
#import "LynxView.h"

NS_ASSUME_NONNULL_BEGIN
@class BDLynxBridge;

@interface LynxView (Bridge)

@property(nonatomic, copy, nullable) NSString *namescope;
@property(nonatomic, strong) BDLynxBridge *bridge;
@property(readwrite) BOOL isLynxViewBeingDestroyed;

@end

@interface LynxView (ID)

@property(nonatomic, copy) NSString *containerID;

@end

@interface LynxView (Initializer)

- (instancetype)initWithContainerSelfBuilderBlock:
    (void (^)(__attribute__((noescape))LynxViewBuilder *_Nonnull, LynxView *_Nonnull))block;

- (instancetype)initWithContainerBuilderBlock:
    (void (^)(__attribute__((noescape))LynxViewBuilder *_Nonnull, NSString *_Nonnull))block;

- (instancetype)initWithContainer:(NSString *)container
                 withBuilderBlock:(void (^)(__attribute__((noescape))LynxViewBuilder *_Nonnull,
                                            NSString *_Nonnull))block;

@end

NS_ASSUME_NONNULL_END
