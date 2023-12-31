// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef DARWIN_COMMON_LYNX_LYNXGROUP_H_
#define DARWIN_COMMON_LYNX_LYNXGROUP_H_

#import <Foundation/Foundation.h>

@class LynxView;

/**
 * A class used to distinguish between different LynxViews.
 */
@interface LynxGroup : NSObject

/*!
 The name of LynxGroup
 */
@property(nonatomic, readonly, nonnull) NSString* groupName;

/*!
 The ID of LynxGroup
 */
@property(nonatomic, readonly, nonnull) NSString* identification;

@property(nonatomic, readonly, nullable) NSArray* preloadJSPaths;

@property(nonatomic, readonly) bool useProviderJsEnv;
@property(nonatomic, readonly) bool enableCanvas;

/**
 * The return value of the function is the tag of the LynxView which doesn't belong to any group.
 */
+ (nonnull NSString*)singleGroupTag;

/**
 * Init LynxGroup with name.
 */
- (nonnull instancetype)initWithName:(nonnull NSString*)name;

/**
 * Init LynxGroup with name and extra js scripts path.
 */
- (nonnull instancetype)initWithName:(nonnull NSString*)name
                   withPreloadScript:(nullable NSArray*)extraJSPaths;

/**
 * Init LynxGroup with name and extra js scripts path and jsenv flag
 */
- (nonnull instancetype)initWithName:(nonnull NSString*)name
                   withPreloadScript:(nullable NSArray*)extraJSPaths
                    useProviderJsEnv:(bool)useProviderJsEnv
                        enableCanvas:(bool)enableCanvas;

/**
 * Init LynxGroup with name and extra js scripts path and jsenv flag
 */
- (nonnull instancetype)initWithName:(nonnull NSString*)name
                   withPreloadScript:(nullable NSArray*)extraJSPaths
                    useProviderJsEnv:(bool)useProviderJsEnv
                        enableCanvas:(bool)enableCanvas
            enableCanvasOptimization:(bool)enableCanvasOptimization;
/**
 * Add LynxView to this group.
 */
- (void)addLynxView:(nonnull LynxView*)view;

+ (bool)enableOptimizedCanvas:(nullable LynxGroup*)group;

+ (bool)enableAnyCanvas:(nullable LynxGroup*)group
    __attribute__((deprecated("Use enableOptimizedCanvas instead.")));

+ (bool)enableOriginalCanvas:(nullable LynxGroup*)group
    __attribute__((deprecated("Always return false.")));
;

@end

#endif  // DARWIN_COMMON_LYNX_LYNXGROUP_H_
