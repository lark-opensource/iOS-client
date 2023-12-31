//
//  NSObject+IESAuthManager.m
//  TTBridgeUnify-Pods-Aweme
//
//  Created by admin on 2021/8/17.
//

#import "NSObject+IESAuthManager.h"
#import <objc/runtime.h>

IESBridgeAuthManager *ies_getAuthManagerFromEngine(id<TTBridgeEngine> engine) {
    IESBridgeAuthManager *authManager = nil;
    if (engine && engine.sourceObject) {
        authManager = engine.sourceObject.ies_authManager;
    }
    if (!authManager) {
        authManager = IESBridgeAuthManager.sharedManager;
    }
    return authManager;
}

@implementation NSObject (IESAuthManager)

- (IESBridgeAuthManager *)ies_authManager {
    return objc_getAssociatedObject(self, @selector(ies_authManager));
}

- (void)setIes_authManager:(IESBridgeAuthManager *)authManager {
    objc_setAssociatedObject(self, @selector(ies_authManager), authManager, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
