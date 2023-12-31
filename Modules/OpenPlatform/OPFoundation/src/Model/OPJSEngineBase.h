//
//  OPJSEngineBase.h
//  OPJSEngine
//
//  Created by yi on 2021/12/24.
//

#import <Foundation/Foundation.h>
#import "OPAppType.h"

#pragma mark - BDPlatformJSBridge MethodType
/* ------- 开放平台 JSBridge 方法类型 ------- */
typedef NS_OPTIONS(NSInteger, BDPJSBridgeMethodType) {
    BDPJSBridgeMethodTypeUnknown    = (1 << OPAppTypeUnknown),    //  方法类型 - 未知类型
    BDPJSBridgeMethodTypeNativeApp  = (1 << OPAppTypeGadget),  //  方法类型 - 仅原生小程序使用
    BDPJSBridgeMethodTypeWebApp     = (1 << OPAppTypeWebApp),     //  方法类型 - 仅 H5 Web应用使用
    BDPJSBridgeMethodTypeCard       = (1 << OPAppTypeWidget), //  方法类型 - 仅 Card 使用
    BDPJSBridgeMethodTypeBlock      = (1 << OPAppTypeBlock),      //  方法类型 - 仅 Block 使用
    BDPJSBridgeMethodTypeDynamicComponent     = (1 << OPAppTypeDynamicComponent),     //  方法类型 - 仅 动态组件使用
    // 便捷类型选择
    BDPJSBridgeMethodTypeHTML5All = (BDPJSBridgeMethodTypeWebApp),
    BDPJSBridgeMethodTypeAll = (BDPJSBridgeMethodTypeNativeApp | BDPJSBridgeMethodTypeHTML5All)
};
