//
//  BDLynxBridgeListenerManager.m
//  BDLynxBridge
//
//  Created by bytedance on 2020/6/19.
//

#import "BDLynxBridgeListenerManager.h"
#import "BDLynxBridge.h"
#import "BDLynxBridgeListenerManager+Internal.h"

static NSHashTable *_bdbridgeListeners;

@implementation BDLynxBridgeListenerManager

+ (NSHashTable *)bridgeListeners {
  if (!_bdbridgeListeners) {
    _bdbridgeListeners = [NSHashTable weakObjectsHashTable];
  }
  return _bdbridgeListeners;
}

+ (void)addBridgeListener:(id<BDLynxBridgeListenerDelegate>)listener {
  @synchronized(self) {
    [BDLynxBridgeListenerManager.bridgeListeners addObject:listener];
  }
}

+ (void)callBridgeListenersWithSel:(SEL)sel bridge:(BDLynxBridge *)bridge message:(id)message {
  for (NSObject<BDLynxBridgeListenerDelegate> *item in BDLynxBridgeListenerManager
           .bridgeListeners) {
    if ([item respondsToSelector:sel]) {
      IMP imp = [item methodForSelector:sel];
      void (*func)(id, SEL, BDLynxBridge * bridge, id message) = (void *)imp;
      func(item, sel, bridge, message);
    }
  }
}

#define CALL_BRIDGE_WITH_SEL(sel) \
  [self callBridgeListenersWithSel:sel bridge:lynxBridge message:message];

+ (void)notifyWillCallEvent:(nullable BDLynxBridge *)lynxBridge
                    message:(nonnull BDLynxBridgeSendMessage *)message {
  CALL_BRIDGE_WITH_SEL(@selector(lynxBridge:willCallEvent:))
}
+ (void)notifyDidCallEvent:(nullable BDLynxBridge *)lynxBridge
                   message:(nonnull BDLynxBridgeSendMessage *)message {
  CALL_BRIDGE_WITH_SEL(@selector(lynxBridge:didCallEvent:))
}

+ (void)notifyWillHandleMethod:(nullable BDLynxBridge *)lynxBridge
                       message:(nonnull BDLynxBridgeReceivedMessage *)message {
  CALL_BRIDGE_WITH_SEL(@selector(lynxBridge:willHandleMethod:))
}

+ (void)notifyDidHandleMethod:(nullable BDLynxBridge *)lynxBridge
                      message:(nonnull BDLynxBridgeReceivedMessage *)message {
  CALL_BRIDGE_WITH_SEL(@selector(lynxBridge:didHandleMethod:))
}

+ (void)notifyWillCallback:(nullable BDLynxBridge *)lynxBridge
                   message:(nonnull BDLynxBridgeSendMessage *)message {
  CALL_BRIDGE_WITH_SEL(@selector(lynxBridge:willCallback:))
}

+ (void)notifyDidCallback:(nullable BDLynxBridge *)lynxBridge
                  message:(nonnull BDLynxBridgeSendMessage *)message {
  CALL_BRIDGE_WITH_SEL(@selector(lynxBridge:didCallback:))
}

@end
