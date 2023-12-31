//
//  BDPModuleEngineType.h
//  Timor
//
//  Created by houjihu on 2020/1/20.
//  Copyright © 2020 houjihu. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OPAppType.h"

typedef OPAppType BDPType;

#define BDPTypeUnknown OPAppTypeUnknown
#define BDPTypeNativeApp OPAppTypeGadget
#define BDPTypeWebApp OPAppTypeWebApp
#define BDPTypeNativeCard OPAppTypeWidget
#define BDPTypeBlock OPAppTypeBlock
#define BDPTypeDynamicComponent OPAppTypeDynamicComponent
#define BDPTypeSDKMsgCard OPAppTypeSDKMsgCard
#define BDPTypeThirdNativeApp OPAppTypeThirdNativeApp


//NS_ASSUME_NONNULL_BEGIN
//
///// 应用类型枚举
//typedef NS_ENUM(NSInteger, BDPType) {
//    /// 未知类型
//    BDPTypeUnknown = 0,
//    /// Native 小程序
//    BDPTypeNativeApp = 1,
//    /// H5 小程序
//    BDPTypeHTML5App = 3,
//    /// H5 web应用
//    BDPTypeWebApp  = 5,
//    /// Native卡片
//    BDPTypeNativeCard = 6,
//    /// Block
//    BDPTypeBlock = 7
//};// 未来增加枚举后, 务必修改下方的BDPTypeMaxValue, Meta请求响应数据返回后会校验
///** BDPType的最大值, 最小有效值默认为1 */
//#define kBDPTypeMaxValue BDPTypeBlock
//
//NS_ASSUME_NONNULL_END
