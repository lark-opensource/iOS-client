//
//  OKConnection.h
//  OneKit
//
//  Created by bob on 2020/4/27.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 网络状态
typedef NS_ENUM(NSInteger, OKNetworkConnectionType) {
    /// 初始状态
    OKAutoTrackNetworkNone = -1,
    /// 无网络连接
    OKNetworkConnectionTypeNone = 0,
    /// 移动网络连接
    OKNetworkConnectionTypeMobile = 1,
    /// 2G网络连接
    OKNetworkConnectionType2G = 2,
    /// 3G网络连接
    OKNetworkConnectionType3G = 3,
    /// wifi网络连接
    OKNetworkConnectionTypeWiFi = 4,
    /// 4G网络连接
    OKNetworkConnectionType4G = 5,
    /// 5G网络连接
    OKNetworkConnectionType5G = 6,
};

@interface OKConnection : NSObject

@property (nonatomic, assign, readonly) OKNetworkConnectionType connection;
@property (nonatomic, copy, readonly, nullable) NSString *connectMethodName;

+ (instancetype)sharedInstance;

@end

NS_ASSUME_NONNULL_END
