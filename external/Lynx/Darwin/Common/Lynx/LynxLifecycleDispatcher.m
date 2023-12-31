// Copyright 2020 The Lynx Authors. All rights reserved.

#import "LynxLifecycleDispatcher.h"
#import "LynxViewClient.h"

@implementation LynxLifecycleDispatcher {
  NSHashTable<id<LynxViewLifecycle>>* _innerLifecycleClients;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _innerLifecycleClients = [NSHashTable hashTableWithOptions:NSPointerFunctionsWeakMemory];
  }

  return self;
}

- (void)dummyMethod {
};

- (void)addLifecycleClient:(id<LynxViewLifecycle>)lifecycleClient {
  @synchronized(self) {
    if (lifecycleClient && ![_innerLifecycleClients containsObject:lifecycleClient]) {
      [_innerLifecycleClients addObject:lifecycleClient];
    }
  }
}

- (void)removeLifecycleClient:(id<LynxViewLifecycle>)lifecycleClient {
  @synchronized(self) {
    if (lifecycleClient && [_innerLifecycleClients containsObject:lifecycleClient]) {
      [_innerLifecycleClients removeObject:lifecycleClient];
    }
  }
}

- (NSArray<id<LynxViewLifecycle>>*)lifecycleClients {
  NSMutableArray<id<LynxViewLifecycle>>* clients = [[NSMutableArray alloc] init];
  @synchronized(self) {
    @autoreleasepool {
      for (id<LynxViewLifecycle> client in _innerLifecycleClients) {
        [clients addObject:client];
      }
    }
  }

  return clients;
}

- (void)forwardInvocation:(NSInvocation*)invocation {
  SEL sel = invocation.selector;

  NSArray* allLifecycleClients = self.lifecycleClients;
  [allLifecycleClients enumerateObjectsUsingBlock:^(id _Nonnull client, NSUInteger idx,
                                                    BOOL* _Nonnull stop) {
    if ([client respondsToSelector:sel] || [client isKindOfClass:LynxLifecycleDispatcher.class]) {
      [invocation invokeWithTarget:client];
    }
  }];
}

// issue: #1510
// see https://developer.apple.com/documentation/objectivec/nsobject/1571955-forwardinvocation
// CAUTION:
// To respond to methods that your object does not itself recognize, you must override
// methodSignatureForSelector: If methodSignatureForSelector: is not overrided, an exception with
// message: unrecognized selector sent to instance will be thrown
- (NSMethodSignature*)methodSignatureForSelector:(SEL)sel {
  for (id sub in self.lifecycleClients) {
    if ([sub respondsToSelector:sel]) {
      NSMethodSignature* signature = [sub methodSignatureForSelector:sel];
      if (signature) {
        return signature;
      }
    }
  }
  return [LynxLifecycleDispatcher instanceMethodSignatureForSelector:@selector(dummyMethod)];
}

#if OS_OSX
- (void)lynxViewDidConstructJSRuntime:(LynxView*)view {
  for (id sub in self.lifecycleClients) {
    [sub lynxViewDidConstructJSRuntime:view];
  }
}
#endif

@end
