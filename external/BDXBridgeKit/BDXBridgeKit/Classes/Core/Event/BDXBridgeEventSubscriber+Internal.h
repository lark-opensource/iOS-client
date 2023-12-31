//
//  BDXBridgeEventSubscriber+Internal.h
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/10/30.
//

#import "BDXBridgeEventSubscriber.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDXBridgeEventSubscriber (Internal)

- (BOOL)receiveEvent:(BDXBridgeEvent *)event;

@end

NS_ASSUME_NONNULL_END
