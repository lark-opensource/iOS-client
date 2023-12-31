//
//  IESBridgeEngine_Deprecated.h
//  IESWebKit
//
//  Created by li keliang on 2019/4/8.
//

#import "IESBridgeEngine.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - IESBridgeEngine_Deprecated

@protocol IESBridgeEngineDelegate_Deprecated;

@interface IESBridgeEngine_Deprecated : NSObject

+ (void)addGlobalMethod:(IESBridgeMethod *)method;

- (instancetype)init NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readwrite, weak) id<IESBridgeExecutor> executor;
@property (nonatomic, weak) id<IESBridgeEngineDelegate_Deprecated> delegate;

- (void)addMethod:(IESBridgeMethod *)method;

- (void)removeAllMethods;

@property (nonatomic, readonly, copy) NSArray<IESBridgeMethod *> *methods;

- (void)sendEvent:(NSString*)event params:(NSDictionary * __nullable)params;

@end


#pragma mark - IESBridgeEngineDelegate_Deprecated

@protocol IESBridgeEngineDelegate_Deprecated <NSObject>

- (void)bridgeEngine:(IESBridgeEngine_Deprecated *)engine didExcuteMethod:(IESBridgeMethod *)method;
- (void)bridgeEngine:(IESBridgeEngine_Deprecated *)engine didReceiveUnauthorizedMethod:(IESBridgeMethod *)method;
- (void)bridgeEngine:(IESBridgeEngine_Deprecated *)engine didReceiveUnregisteredMessage:(IESBridgeMessage *)message;

@end


NS_ASSUME_NONNULL_END
