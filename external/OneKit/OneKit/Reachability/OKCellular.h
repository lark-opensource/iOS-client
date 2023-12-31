//
//  OKCellular.h
//  OneKit
//
//  Created by bob on 2020/4/27.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CTTelephonyNetworkInfo, CTCarrier, CTCellularData;

/// SIM网络状态
typedef NS_ENUM(NSInteger, OKCellularConnectionType) {
    /// 无网络连接
    OKCellularConnectionTypeNone = 0,
    /// 未知移动网络
    OKCellularConnectionTypeUnknown,
    /// 2G网络连接
    OKCellularConnectionType2G,
    /// 3G网络连接
    OKCellularConnectionType3G,
    /// 4G网络连接
    OKCellularConnectionType4G,
    /// 5G网络连接
    OKCellularConnectionType5G,
};

typedef NS_ENUM(NSInteger, OKCellularServiceType) {
    OKCellularServiceTypeNone = 0,         /// 无卡
    OKCellularServiceTypePrimary = 1,      /// 主卡状态
    OKCellularServiceTypeSecondary = 2,    /// 副卡状态
};

@interface OKCellular : NSObject

@property (class ,nonatomic, strong, readonly) CTCellularData *cellularData;

+ (instancetype)sharedInstance;

+ (CTTelephonyNetworkInfo *)telephoneInfo;

/// 返回指定卡信息
/// 如果指定副卡不存在，返回主卡信息
- (OKCellularConnectionType)cellularConnectionTypeForService:(OKCellularServiceType)service;
- (CTCarrier *)carrierForService:(OKCellularServiceType)service;
- (OKCellularServiceType)currentDataServiceType;/// 返回当前流量卡类型

@end

NS_ASSUME_NONNULL_END
