//
//  BDLynxBridge.h
//
//  Created by li keliang on 2020/2/9.
//  Copyright © 2020 Lynx. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BDLynxBridgeExecutor.h"
#import "BDLynxBridgeMessage.h"
#import "BDLynxBridgeMethod.h"
#import "LynxTemplateData.h"
#import "LynxView+Bridge.h"

NS_ASSUME_NONNULL_BEGIN
@class BDLynxBridgeMessage;
@class LynxView;

@interface BDLynxBridge : NSObject

@property(nonatomic, readonly, strong) NSMutableArray<BDLynxBridgeMethod *> *methods;

@property(nonatomic, readonly, weak) LynxView *lynxView;

@property(nonatomic, nullable, copy) NSDictionary<NSString *, id> *globalProps;

@property(nonatomic, nullable, strong) LynxTemplateData *globalPropsData;

@property(nonatomic, nullable, copy) NSSet<NSString *> *directPerformMethods;

- (instancetype)initWithLynxView:(LynxView *)lynxView NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithoutLynxView;
- (void)attachLynxView:(nonnull LynxView *)lynxView;

- (void)registerHandler:(BDLynxBridgeHandler)handler forMethod:(NSString *)method;
- (void)registerHandler:(BDLynxBridgeHandler)handler
              forMethod:(NSString *)method
              namescope:(nullable NSString *)namescope;
- (void)registerSessionHandler:(BDLynxBridgeSessionHandler)handler
                     forMethod:(NSString *)method
                     namescope:(nullable NSString *)namescope;
- (void)callEvent:(NSString *)event params:(nullable NSDictionary *)params;
- (void)callEvent:(NSString *)event
           params:(nullable NSDictionary *)params
             code:(BDLynxBridgeStatusCode)code;

+ (void)registerGlobalHandler:(BDLynxBridgeHandler)handler forMethod:(NSString *)method;
+ (void)registerGlobalHandler:(BDLynxBridgeHandler)handler
                    forMethod:(NSString *)method
                    namescope:(nullable NSString *)namescope;
+ (void)registerGlobalSessionHandler:(BDLynxBridgeSessionHandler)handler
                           forMethod:(NSString *)method
                           namescope:(nullable NSString *)namescope;
+ (void)callEvent:(NSString *)event
      containerID:(nullable NSString *)containerID
           params:(nullable NSDictionary *)params;
+ (void)callEvent:(NSString *)event
      containerID:(nullable NSString *)containerID
           params:(nullable NSDictionary *)params
             code:(BDLynxBridgeStatusCode)code;

- (void)addExecutor:(id<BDLynxBridgeExecutor>)executor;

@end

NS_ASSUME_NONNULL_END
