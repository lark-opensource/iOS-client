//
//  BDLynxBridgeReceivedMessage+Timestamp.h
//  IESWebViewMonitor
//
//  Created by Paklun Cheng on 2020/9/15.
//

#import <Lynx/BDLynxBridgeMessage.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDLynxBridgeReceivedMessage (Timestamp)
@property (nonatomic, assign) long long bdwm_invokeTS;
@end

@interface BDLynxBridgeSendMessage (Timestamp)
@property (nonatomic, assign) long long bdwm_callbackTS;
@property (nonatomic, assign) long long bdwm_fireEventTS;
@property (nonatomic, assign) long long bdwm_endTS;
@end

NS_ASSUME_NONNULL_END
