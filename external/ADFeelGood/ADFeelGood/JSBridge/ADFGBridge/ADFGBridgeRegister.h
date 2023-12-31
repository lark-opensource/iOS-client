//
//  BridgeRegister.h
//  Pods
//
//  Created by renpeng on 2020/04/9.
//

#import <Foundation/Foundation.h>
#import "ADFGBridgePlugin.h"
#import "ADFGBridgeDefines.h"
#import "ADFGBridgeCommand.h"
#import "ADFGBridgeEngine.h"

NS_ASSUME_NONNULL_BEGIN

/**
 全局注册 bridge
 @param pluginName 对应的 plugin 方法名
 @param bridgeName bridge 名
 */
FOUNDATION_EXTERN void ADFGRegisterBridge(NSString *pluginName,
                             ADFGBridgeName bridgeName);


@interface ADFGBridgeMethodInfo : NSObject
@end


typedef void(^ADFGBridgeHandler)(NSDictionary * _Nullable params, ADFGBridgeCallback callback, id<ADFGBridgeEngine> engine, UIViewController * _Nullable controller);
@interface ADFGBridgeRegisterMaker : NSObject

@property (nonatomic, copy, readonly, nullable) ADFGBridgeRegisterMaker *(^pluginName)(NSString *pluginName);//全局注册方法用
@property (nonatomic, copy, readonly, nullable) ADFGBridgeRegisterMaker *(^handler)(ADFGBridgeHandler handler);//局部注册方法用
@property (nonatomic, copy, readonly, nullable) ADFGBridgeRegisterMaker *(^bridgeName)(NSString *bridgeName);
@end


@interface ADFGBridgeRegister : NSObject

+ (instancetype)sharedRegister;

- (void)registerBridge:(void(^)(ADFGBridgeRegisterMaker *maker))block;

- (void)unregisterBridge:(ADFGBridgeName)bridgeName;

- (BOOL)respondsToBridge:(ADFGBridgeName)bridgeName;

- (void)executeCommand:(ADFGBridgeCommand *)command engine:(id<ADFGBridgeEngine>)engine completion:(ADFGBridgeCallback)completion;


@end



NS_ASSUME_NONNULL_END
