// Copyright 2019 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>
#import "LynxComponentRegistry.h"
#import "LynxModule.h"
#import "LynxTemplateProvider.h"

NS_ASSUME_NONNULL_BEGIN

/*!
 Config some common tools that may be used in the lifecycle of LynxView.
 LynxConfig can be reused for multiple LynxViews.
 */
@interface LynxConfig : NSObject

@property(nonatomic, readonly) id<LynxTemplateProvider> templateProvider;
@property(nonatomic, readonly) LynxComponentScopeRegistry *componentRegistry;
@property(nonatomic, copy, nullable) NSMutableDictionary *contextDict;

/*! Set a global (default) config which will provide a convenient way
 for creating LynxView without LynxConfig. */
+ (LynxConfig *)globalConfig
    __attribute__((deprecated("Use [LynxEnv sharedInstance].config instead.")));
+ (void)prepareGlobalConfig:(LynxConfig *)config
    __attribute__((deprecated("Use [[LynxEnv sharedInstance] prepareConfig:config] instead.")));

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithProvider:(id<LynxTemplateProvider>)provider;
- (void)registerModule:(Class<LynxModule>)module;
- (void)registerModule:(Class<LynxModule>)module param:(nullable id)param;
- (void)registerUI:(Class)ui withName:(NSString *)name;
- (void)registerShadowNode:(Class)node withName:(NSString *)name;
- (void)registerMethodAuth:(LynxMethodBlock)authBlock;
- (void)registerContext:(NSDictionary *)ctxDict sessionInfo:(LynxMethodSessionBlock)sessionInfo;
/**
 * Set renderkit context to module. used by macOS
 */
- (void)setRenderkitImpl:(void *)renderkit_impl;

@end

NS_ASSUME_NONNULL_END
