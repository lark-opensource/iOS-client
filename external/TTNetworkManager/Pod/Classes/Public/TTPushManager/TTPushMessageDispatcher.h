//
//  TTPushMessageDispatcher.h
//  TTPushManager
//
//  Created by gaohaidong on 7/10/16.
//  Copyright © 2016 bytedance. All rights reserved.
//

#ifdef __cplusplus

#import <Foundation/Foundation.h>
#import <string>
#import "TTPushMessageReceiver.hpp"
#import "TTPushManager.h"

@class PushMessageBaseObject;

@interface TTPushMessageDispatcher : NSObject

- (void)setCustomizedMessageReceiver:(TTPushMessageReceiver *)messageReceiver;

- (void)dispatchMessage:(const std::string &)message;

- (void)delegateMessage:(const std::string &)message pushManager:(TTPushManager *)pushManager;

- (void)setBroadcastingMessage:(BOOL)value;

+ (NSData *)serializeObject:(PushMessageBaseObject *)obj;

@end

#endif