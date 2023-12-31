//
//  EMALocationManagerV2.h
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/3/28.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <OPFoundation/BDPLocationPluginDelegate.h>

NS_ASSUME_NONNULL_BEGIN
/// LocationErrorCode
/// 其余errorCode 可参考 CLError.h
typedef NS_ENUM(NSInteger, EMALocationErrorCode) {
    /// iOS系统定位权限问题
    EMALocationErrorSystemAuthoriztion = -1,
    /// lark 级别gps关闭
    EMALocationErrorLarkGPSDisabled = -2,
};

/**
 * 定位管理器 支持持续定位回调的定位机制
 */
@interface EMALocationManagerV2 : NSObject

- (instancetype _Nonnull)init NS_UNAVAILABLE;
+ (instancetype _Nonnull)new NS_UNAVAILABLE;

+ (instancetype)sharedInstance;

/// 请求定位
/// @param desiredAccuracy 面向小程序的精度
/// @param baseAccuracy 面向引擎的精度 通常这个高一些
/// @param coordinateSystemType 坐标系系统
/// @param timeout 超时时间
/// @param cacheTimeout 缓存超时时间
/// @param updateCallback 定位更新回调
/// @param completion 结果回调
- (void)reqeustLocationWithDesiredAccuracy:(CLLocationAccuracy)desiredAccuracy
                              baseAccuracy:(CLLocationAccuracy)baseAccuracy
                      coordinateSystemType:(BDPCoordinateSystemType)coordinateSystemType
                                   timeout:(NSTimeInterval)timeout
                              cacheTimeout:(NSTimeInterval)cacheTimeout
                                   appType:(NSString * _Nullable)appType
                                     appID:(NSString * _Nullable)appID
                            updateCallback:(void(^ _Nullable)(CLLocation * _Nullable, NSArray<CLLocation *> * _Nullable))updateCallback
                                completion:(void(^ _Nullable)(CLLocation * _Nullable, BDPAccuracyAuthorization, NSError * _Nullable))completion;
/// 请求定位
/// @param isNeedRequestAuthoriztion 当用户未决策app定位权限的时候是否需要请求定位权限
/// @param desiredAccuracy 面向小程序的精度
/// @param baseAccuracy 面向引擎的精度 通常这个高一些
/// @param coordinateSystemType 坐标系系统
/// @param timeout 超时时间
/// @param cacheTimeout 缓存超时时间
/// @param updateCallback 定位更新回调
/// @param completion 结果回调
- (BOOL)reqeustLocationWithIsNeedRequestAuthoriztion:(BOOL)isNeedRequestAuthoriztion
                                 desiredAccuracy:(CLLocationAccuracy)desiredAccuracy
                              baseAccuracy:(CLLocationAccuracy)baseAccuracy
                      coordinateSystemType:(BDPCoordinateSystemType)coordinateSystemType
                                   timeout:(NSTimeInterval)timeout
                              cacheTimeout:(NSTimeInterval)cacheTimeout
                                   appType:(NSString *)appType
                                     appID:(NSString *)appID
                            updateCallback:(void(^)(CLLocation *, NSArray *))updateCallback
                                          completion:(void(^)(CLLocation *, BDPAccuracyAuthorization, NSError *))completion;

@end

NS_ASSUME_NONNULL_END
