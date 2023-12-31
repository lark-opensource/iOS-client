// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef DARWIN_COMMON_LYNX_NAVIGATOR_CACHE_LYNXLRUCACHE_H_
#define DARWIN_COMMON_LYNX_NAVIGATOR_CACHE_LYNXLRUCACHE_H_

#import <Foundation/Foundation.h>

@class LynxRoute;
@class LynxView;

typedef LynxView * (^LynxViewReCreateBlock)(LynxRoute *);
typedef void (^LynxViewEvictedBlock)(LynxView *);

@interface LynxLruCache : NSObject

@property(nonatomic, readonly, assign) NSUInteger capacity;

- (instancetype)initWithCapacity:(NSUInteger)capacity
                        recreate:(LynxViewReCreateBlock)createBlock
                     viewEvicted:(LynxViewEvictedBlock)evictedBlock;
- (void)setObject:(id)object forKey:(id)key;
- (id)objectForKey:(id)key;
- (id)removeObjectForKey:(id)key;

@end

#endif  // DARWIN_COMMON_LYNX_NAVIGATOR_CACHE_LYNXLRUCACHE_H_
