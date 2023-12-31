//
//  BridgeHost.h
//  FlutterIntergation
//
//  Created by bytedance on 2020/4/3.
//  Copyright © 2020 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "BDBridgeHost.h"

NS_ASSUME_NONNULL_BEGIN

@protocol BDBridgeHost <NSObject>

/// 消息传递的载体（Flutter:id<FlutterPluginRegistrar> JS:webview）
- (NSObject *)channelCarrier;

/// 发送消息事件
/// @param name         事件名称
/// @param data         事件传参
- (void)sendEvent:(NSString *)name data:(NSDictionary *)data;

@end



@interface BDBridgeHost : NSObject <BDBridgeHost>

/// 根据消息载体生成一个Bridge
/// @param carrier      bridge中的消息载体
- (instancetype)initWithChannelCarrier:(NSObject *)carrier;


/// 将bridge加入到moduleManager中
/// @param host         特定的bridgeHost
+ (void)addHost:(id<BDBridgeHost>)host;


/// 根据消息载体获取bridgeHost
/// @param carrier      消息载体
+ (id<BDBridgeHost>)getHostByCarrier:(NSObject *)carrier;


/// 向特定的消息载体中发送消息
/// @param name         事件名称
/// @param data         事件参数
/// @param carrier      消息载体
+ (void)sendEvent:(NSString *)name data:(NSDictionary *)data forCarrie:(NSObject *)carrier;

@end

NS_ASSUME_NONNULL_END
