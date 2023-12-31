//
//  TTBridgeUnify_internal.h
//  AFgzipRequestSerializer-iOS12.0
//
//  Created by lizhuopeng on 2019/9/26.
//

#import <Foundation/Foundation.h>
#import "TTBridgeForwarding.h"
#import "TTBridgeRegister.h"

NS_ASSUME_NONNULL_BEGIN


@interface TTBridgeForwarding (TTBridgeInternal)

- (void)_installAssociatedPluginsOnEngine:(id<TTBridgeEngine>)engine;

@end

@interface TTBridgeRegister (TTBridgeInternal)

+ (void)_doRegisterIfNeeded;

@end



NS_ASSUME_NONNULL_END
