//
//  BDXBridgeEngineProtocol.h
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/6/24.
//

#import <Foundation/Foundation.h>
#import "BDXBridgeDefinitions.h"

NS_ASSUME_NONNULL_BEGIN

@protocol BDXBridgeContainerProtocol;

typedef void(^BDXBridgeEngineCompletionHandler)(BDXBridgeStatusCode statusCode, NSDictionary * _Nullable result, NSString * _Nullable message);
typedef void(^BDXBridgeEngineCallHandler)(id<BDXBridgeContainerProtocol> _Nullable container, NSDictionary * _Nullable params, BDXBridgeEngineCompletionHandler completionHandler);

@protocol BDXBridgeEngineProtocol <NSObject>

- (instancetype)initWithContainer:(id<BDXBridgeContainerProtocol>)container;

+ (void)registerGlobalMethodWithMethodName:(NSString *)methodName authType:(BDXBridgeAuthType)authType engineTypes:(BDXBridgeEngineType)engineTypes callHandler:(BDXBridgeEngineCallHandler)callHandler;
+ (void)deregisterGlobalMethodWithMethodName:(NSString *)methodName;

- (void)registerLocalMethodWithMethodName:(NSString *)methodName authType:(BDXBridgeAuthType)authType engineTypes:(BDXBridgeEngineType)engineTypes callHandler:(BDXBridgeEngineCallHandler)callHandler;
- (void)deregisterLocalMethodWithMethodName:(NSString *)methodName;

- (void)fireEventWithEventName:(NSString *)eventName params:(NSDictionary *)params;

@end

NS_ASSUME_NONNULL_END
