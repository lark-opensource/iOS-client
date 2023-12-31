//
//  HMDZombieHandle.h
//  ZombieDemo
//
//  Created by Liuchengqing on 2020/3/2.
//  Copyright © 2020 Liuchengqing. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HMDZombieHandle : NSObject

+ (void)setupVariable;

+ (BOOL)deallocHandle:(__unsafe_unretained id _Nonnull )obj class:(__unsafe_unretained Class _Nonnull )cls;

+ (BOOL)cfNonObjCReleaseHandle:(__unsafe_unretained id _Nonnull)obj;

+ (void)free:(void * _Nonnull)obj cfAllocator:(CFAllocatorRef _Nullable)allocator;

@end

