//
//  BDPLocationPluginDelegate.h
//  Pods
//
//  Created by MacPu on 2018/11/3.
//  Copyright © 2018 Bytedance.com. All rights reserved.
//

#ifndef BDPLocationPluginDelegate_h
#define BDPLocationPluginDelegate_h

#import "BDPBasePluginDelegate.h"
#import "BDPJSBridgeProtocol.h"
#import "BDPLocationPluginModel.h"

/// 坐标系系统
typedef enum : NSUInteger {
    EMACoordinateSystemTypeWGS84,   // WGS84坐标系
    EMACoordinateSystemTypeGCJ02    // GCJ-02坐标
} BDPCoordinateSystemType;

// 定义一个location精度级别枚举 「unknown、full、reduced」
typedef NS_ENUM(NSInteger, BDPAccuracyAuthorization){
    BDPAccuracyAuthorizationUnknown = -1,       //表示当前iOS版本非iOS14，没有CLAccuracyAuthorization选项
    BDPAccuracyAuthorizationFullAccuracy = 0,   //表示当前为iOS14+，且地图精度为CLAccuracyAuthorizationFullAccuracy
    BDPAccuracyAuthorizationReducedAccuracy = 1 //表示当前为iOS14+，且地图精度为CLAccuracyAuthorizationReducedAccuracy
};

/**
 * 跟location相关的回调方法
 */
@protocol BDPLocationPluginDelegate <BDPBasePluginDelegate>

/// 请求宿主定位服务
/// @param param 请求参数
/// @param context 应用上下文
/// @param completion 回调
- (void)bdp_reqeustLocationWithParam:(NSDictionary * _Nullable)param
                             context:(BDPPluginContext _Nullable)context
                          completion:(void(^ _Nullable)(CLLocation * _Nullable, BDPAccuracyAuthorization, NSError * _Nullable))completion;

@end

#endif /* BDPLocationPluginDelegate_h */
