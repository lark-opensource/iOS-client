//
//  NSObject+BDXBridgeContainer.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/6/14.
//

#import "NSObject+BDXBridgeContainer.h"
#import "BDXBridge+Internal.h"
#import "BDXBridgeContainerProtocol.h"
#import "BDXBridgeContainerPool.h"
#import <objc/runtime.h>
#import <BDAssert/BDAssert.h>

@implementation NSObject (BDXBridgeContainer)

- (BDXBridge *)bdx_bridge
{
    BDXBridge *bridge = objc_getAssociatedObject(self, _cmd);
    BDAssert(bridge, @"The bridge has not been set up yet.");
    return bridge;
}

- (void)bdx_setUpBridgeWithContainerID:(NSString *)containerID
{
    BDXBridge *bridge = objc_getAssociatedObject(self, @selector(bdx_bridge));
    BDAssert(!bridge, @"The bridge has been set up already.");
    if (!bridge) {
        if ([self conformsToProtocol:@protocol(BDXBridgeContainerProtocol)]) {
            BDXBridge *bridge = [[BDXBridge alloc] initWithContainer:(id<BDXBridgeContainerProtocol>)self];
            objc_setAssociatedObject(self, @selector(bdx_bridge), bridge, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        } else {
            BDAssert(NO, @"The class '%@' should conform to protocol '%@'.", NSStringFromClass(self.class), NSStringFromProtocol(@protocol(BDXBridgeContainerProtocol)));
            return;
        }
    }
    
    if (!containerID) {
        containerID = [[NSUUID UUID] UUIDString];
    }
    objc_setAssociatedObject(self, @selector(bdx_containerID), containerID, OBJC_ASSOCIATION_COPY_NONATOMIC);
    BDXBridgeContainerPool.sharedPool[containerID] = (id<BDXBridgeContainerProtocol>)self;
}

- (void)bdx_tearDownBridge
{
    BDXBridge *bridge = objc_getAssociatedObject(self, @selector(bdx_bridge));
    if (bridge) {
        objc_setAssociatedObject(self, @selector(bdx_bridge), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

- (NSString *)bdx_containerID
{
    NSString *containerID = objc_getAssociatedObject(self, _cmd);
    BDAssert(containerID, @"The containerID has not been set via `-bdx_setUpBridgeWithContainerID:` yet.");
    return containerID;
}

@end
