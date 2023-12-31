//
//  TTBridgeCommand.h
//  TTBridgeUnify
//
//  Modified from TTRexxar of muhuai.
//  Created by lizhuopeng on 2018/10/30.
//

#import <Foundation/Foundation.h>
#import "TTBridgeDefines.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, TTBridgeType) {
    TTBridgeTypeCall= 0,
    TTBridgeTypeOn,
};

typedef NS_ENUM(NSUInteger, TTPiperProtocolType) {
    TTPiperProtocolUnknown= 0,
    TTPiperProtocolSchemaInterception = 1,//1.0 protocol，rexxar
    TTPiperProtocolInjection,//2.0 or 3.0 protocol，inject js.
};

@interface TTBridgeCommand : NSObject

@property (nonatomic, assign) TTBridgeType bridgeType;

@property(nonatomic, copy, nullable) NSString *messageType;

@property(nonatomic, copy, nullable) NSString *eventID;

@property(nonatomic, copy, nullable) NSString *callbackID;

@property(nonatomic, copy, nullable) NSDictionary *params;

@property(nonatomic, copy, nullable) NSDictionary *extraInfo;

@property(nonatomic, assign) TTBridgeMsg bridgeMsg;
/**
 BridgeName from the front-end. Format: "Namespace.method".
 */
@property(nonatomic, copy, nullable) TTBridgeName bridgeName;

/**
 Format："Class.method".
 */
@property(nonatomic, copy, nullable) NSString *pluginName;

/**
 Class name of the plugin.
 */
@property(nonatomic, copy, nullable) NSString *className;

/**
 Method name of the plugin.
 */
@property(nonatomic, copy, nullable) NSString *methodName;

/**
 No use.
 */
@property(nonatomic, copy, nullable) NSString *JSSDKVersion;

/**
 The time when receive the request from the front-end.
 */
@property (nonatomic, copy, nullable) NSString *startTime;

/**
 The time when submit the callback to the front-end.
 */
@property (nonatomic, copy, nullable) NSString *endTime;


/// Protocol type of Piper.
@property(nonatomic, assign) TTPiperProtocolType protocolType;

- (instancetype)initWithDictonary:(NSDictionary *)dic;

- (NSString *)toJSONString;
- (NSDictionary *)rawDictionary;

@property(nonatomic, strong, readonly) NSString *wrappedParamsString;

@end

NS_ASSUME_NONNULL_END
