//
//  IESBridgeEngine_Deprecated+Private.h
//  IESWebKit
//
//  Created by li keliang on 2019/4/11.
//

#import "IESBridgeEngine_Deprecated.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESBridgeEngine_Deprecated (Private)

- (void)executeMethodsWithMessage:(IESBridgeMessage *)message;
- (void)sendBridgeMessage:(IESBridgeMessage *)message;

@end

NS_ASSUME_NONNULL_END
