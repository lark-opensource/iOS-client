//
//  UIDevice+SGMSafeGuard.h
//  SecSDK
//
//  Created by renfeng.zhang on 2018/1/19.
//  Copyright © 2018年 Zhi Lee. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 *  'SGMSafeGuard'类别用来进行设备数据采集
 */
@interface UIDevice (SGMSafeGuard)

#ifdef IS_KA_HZ
/* 获取设备的vendor标识符(IDFV) */
+ (NSString *)sgm_data_acquisition_vendorid;

/* 获取设备的广告表示符(IDFA) */
+ (NSString *)sgm_data_acquisition_advertising;
#endif
/* 系统版本, 如: 8.1 */
+ (NSString *)sgm_data_acquisition_systemVersion;

/* 系统版本, 如: iOS */
+ (NSString *)sgm_data_acquisition_systemName;

/* 设备的机器型号, 如: "iPhone6,1" "iPad4,6" */
+ (NSString *)sgm_data_acquisition_machineModel;

/* 设备的机器型号名称, 如: "iPhone 5s" "iPad mini 2" */
+ (NSString *)sgm_data_acquisition_machineModelName;

/* '设置' -- '通用' -- '关于本机' -- '名称' */
+ (NSString *)sgm_data_acquisition_machineName;

/* 当前设备的wifi IP地址, 可能为nil */
+ (NSString *)sgm_data_acquisition_wifiIPAddress;

#if IS_KA_HZ
+ (NSDictionary *)sgm_data_acquisition_activeIpv4;
#endif
@end //UIDevice (SGMSafeGuard)
