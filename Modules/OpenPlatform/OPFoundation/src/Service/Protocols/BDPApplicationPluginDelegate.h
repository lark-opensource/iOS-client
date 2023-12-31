//
//  BDPApplicationPluginDelegate.h
//  Pods
//
//  Created by MacPu on 2018/11/4.
//  Copyright © 2018 Bytedance.com. All rights reserved.
//

#ifndef BDPApplicationPluginDelegate_h
#define BDPApplicationPluginDelegate_h

#import "BDPBasePluginDelegate.h"

/**
 * 获取宿主信息的接口
 */
@protocol BDPApplicationPluginDelegate <BDPBasePluginDelegate>

@required
/**
 @brief     注册宿主信息的接口
 @return    宿主信息, 需要返回的字段有：'appName'，‘appVersion’, etc,.
 */
- (NSDictionary *)bdp_registerApplicationInfo;

/**
 @brief     注册宿主场景值的接口
 @return    场景值信息，格式: {NSString * : NSNumber *}，示例：{@"share_qq" : @(014003)}
 */
- (NSDictionary *)bdp_registerSceneInfo;

@end

#endif /* BDPApplicationPluginDelegate_h */
