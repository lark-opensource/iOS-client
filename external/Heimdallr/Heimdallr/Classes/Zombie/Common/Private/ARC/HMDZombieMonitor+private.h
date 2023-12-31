//
//  HMDZombieMonitor+private.h
//  ZombieDemo
//
//  Created by Liuchengqing on 2020/3/3.
//  Copyright © 2020 Liuchengqing. All rights reserved.
//

#ifndef HMDZombieMonitor_private_h
#define HMDZombieMonitor_private_h

#import "HMDZombieMonitor.h"

@interface HMDZombieMonitor (PrivateAPI)

- (void)cacheZombieObj:(void * _Nonnull)zombieObj cfAllocator:(CFAllocatorRef _Nullable)cfAllocator backtrace:(const char * _Nullable)backtrace size:(size_t)size;

- (const char* _Nullable)getZombieBacktrace:(void * _Nonnull)obj;

@end

#endif /* HMDZombieMonitor_private_h */

