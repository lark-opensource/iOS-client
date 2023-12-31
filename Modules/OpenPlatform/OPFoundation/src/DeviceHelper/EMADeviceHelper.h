//
//  EMADeviceHelper.h
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/1/4.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, OPSensitivityEntryToken);

typedef enum : NSUInteger {
    EMAWiFiStatusUnknown,   //未知状态
    EMAWiFiStatusOn,        //打开状态
    EMAWiFiStatusOff        //关闭状态
} EMAWiFiStatus;

@interface EMADeviceHelper : NSObject

@end

@interface EMADeviceHelper (EMADiskSpace)

//获取硬盘大小，单位Byte
+ (long long)getTotalDiskSpace;

//获取可用空间大小，单位Byte
+ (long long)getFreeDiskSpace;

/// 获取Wifi的开关状态（开不代表连接）
+ (EMAWiFiStatus)getWiFiStatusWithToken:(OPSensitivityEntryToken)token;

@end
