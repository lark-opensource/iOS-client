//
//  BDLynxBridgeMessage.h
//
//  Created by li keliang on 2020/2/9.
//  Copyright © 2020 Lynx. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BDLynxBridgeDefines.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDLynxBridgeReceivedMessage : NSObject

@property(nonatomic, copy, readonly) NSString *methodName;
@property(nonatomic, copy, readonly) NSDictionary *rawData;
@property(nonatomic, copy, readonly) NSString *protocolVersion;

@property(nonatomic, copy, readonly, nullable) NSString *containerID;
@property(nonatomic, copy, readonly, nullable) NSString *namescope;
@property(nonatomic, copy, readonly, nullable) NSDictionary *data;
/**
 * If useUIThread is No, bridge run on current thread
 * If useUIThread is Yes, bridge run  on main thread
 */
@property(nonatomic, assign, readonly) BOOL useUIThread;
@property(nonatomic, assign, readonly) BOOL isDefaultOfUseUIThread;

- (instancetype)initWithMethodName:(NSString *)method rawData:(NSDictionary *)rawData;

- (void)useUIThreadDisable;

@end

@interface BDLynxBridgeSendMessage : NSObject

@property(nonatomic, copy) NSString *containerID;
@property(nonatomic, copy, nullable) id data;

@property(nonatomic, assign) BDLynxBridgeStatusCode code;
@property(nonatomic, copy, readonly) NSString *protocolVersion;

@property(nonatomic, copy) NSString *statusDescription;

@property(nonatomic, strong) BDLynxBridgeReceivedMessage *invokeMessage;

+ (instancetype)messageWithContainerID:(NSString *)containerID;

- (id)encodedMessage;

@end

@interface BDLynxBridgeReceivedMessage (Error)

- (NSDictionary *)noHandlerError;
+ (BDLynxBridgeSendMessage *)noHandleErrorMessage:(NSString *)containerID;

- (NSDictionary *)paramsError:(NSString *_Nullable)message;
+ (BDLynxBridgeSendMessage *)errorSendMessageWith:(NSString *)errorMessage
                                      containerID:(NSString *)containerID;

@end

NS_ASSUME_NONNULL_END
