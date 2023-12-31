//
//  BDLynxBridge+Internal.h
//
//  Created by li keliang on 2020/2/9.
//  Copyright © 2020 Lynx. All rights reserved.
//

#import "BDLynxBridge.h"
#import "BDLynxBridgeMessage.h"
#import "BDLynxBridgesPool.h"
#import "LynxView.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString *const BDLynxBridgeDefaultNamescope;

@interface BDLynxBridge (Internal)

- (void)_executeMethodWithMessage:(BDLynxBridgeReceivedMessage *)message
                         callback:(LynxCallbackBlock)callback;
- (void)setNamescope:(NSString *)namescope;

@end

NS_ASSUME_NONNULL_END
