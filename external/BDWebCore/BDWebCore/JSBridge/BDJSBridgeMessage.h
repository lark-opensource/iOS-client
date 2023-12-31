//
//  BDJSBridgeMessage.h
//  BDJSBridgeCore
//
//  Created by 李琢鹏 on 2020/1/14.
//

#import <Foundation/Foundation.h>
#import "BDJSBridgeCoreDefines.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN NSString *const BDJSBridgeMessageTypeEvent;
FOUNDATION_EXTERN NSString *const BDJSBridgeMessageTypeCall;
FOUNDATION_EXTERN NSString *const BDJSBridgeMessageTypeCallback;

@interface BDJSBridgeMessage : NSObject

@property (nonatomic, copy) NSString *messageType;
@property (nonatomic, copy, readonly) NSString *eventID;
@property (nonatomic, copy) NSString *callbackID;
@property (nonatomic, copy) NSDictionary *params;
@property (nonatomic, copy, readonly) NSString *bridgeName;
@property (nonatomic, copy, readonly) NSString *JSSDKVersion;
@property (nonatomic, copy) NSString *beginTime;
@property (nonatomic, copy) NSString *endTime;
@property (nonatomic, assign) BDJSBridgeStatus status;
@property (nonatomic, strong, readonly) NSString *statusDescription;
@property(nonatomic, copy) NSString *namespace;
@property(nonatomic, class, readonly) NSString *defaultNamespace;
@property(nonatomic, copy) NSDictionary *rawData;
@property(nonatomic, copy) NSString *protocolVersion;

- (instancetype)initWithDictionary:(NSDictionary *)dict;

- (NSString *)wrappedParamsString;
+ (NSString *)statusDescriptionWithStatusCode:(BDJSBridgeStatus)status;
- (NSString *)statusDescription;
- (void)updateStatusWithParams:(NSDictionary *)params;
@end

NS_ASSUME_NONNULL_END
