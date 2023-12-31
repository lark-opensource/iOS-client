//
//  NSObject+IESAuthManager.h
//  TTBridgeUnify-Pods-Aweme
//
//  Created by admin on 2021/8/17.
//

#import <Foundation/Foundation.h>
#import <BDJSBridgeAuthManager/IESBridgeAuthManager.h>
#import "TTBridgeEngine.h"

NS_ASSUME_NONNULL_BEGIN

IESBridgeAuthManager *ies_getAuthManagerFromEngine(id<TTBridgeEngine> engine);

@interface NSObject (IESAuthManager)

- (IESBridgeAuthManager *)ies_authManager;
- (void)setIes_authManager:(IESBridgeAuthManager *)authManager;

@end

NS_ASSUME_NONNULL_END
