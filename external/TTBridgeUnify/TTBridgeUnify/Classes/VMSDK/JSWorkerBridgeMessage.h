//
//  JSWorkerBridgeMessage.h
//  TTBridgeUnify
//
//  Created by bytedance on 2021/10/14.
//

#import <Foundation/Foundation.h>
#import "JSWorkerBridgeDefines.h"

NS_ASSUME_NONNULL_BEGIN

@interface JSWorkerBridgeReceivedMessage : NSObject

@property(nonatomic, copy, readonly) NSString *methodName;
@property(nonatomic, copy, readonly) NSDictionary *rawData;
@property(nonatomic, copy, readonly) NSString *protocolVersion;

@property(nonatomic, copy, readonly, nullable) NSString *containerID;
@property(nonatomic, copy, readonly, nullable) NSString *namescope;
@property(nonatomic, copy, readonly, nullable) NSDictionary *data;

- (instancetype)initWithMethodName:(NSString *)methodName rawData:(NSDictionary *)rawData containerID:(NSString*)containerID;

@end

@interface JSWorkerBridgeSendMessage : NSObject

@property(nonatomic, copy) NSString *containerID;
@property(nonatomic, copy, nullable) id data;

@property(nonatomic, assign) JSWorkerBridgeStatusCode code;
@property(nonatomic, copy, readonly) NSString *protocolVersion;

@property(nonatomic, copy) NSString *statusDescription;

@property(nonatomic, strong) JSWorkerBridgeReceivedMessage *invokeMessage;

+ (instancetype)messageWithContainerID:(NSString *)containerID;

- (id)encodedMessage;

@end

NS_ASSUME_NONNULL_END
