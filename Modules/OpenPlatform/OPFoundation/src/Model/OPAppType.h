//
//  OPAppType.h
//  OPSDK
//  (本文件保持使用 OC 便于在旧的 OC代码头文件中被引用)
//
//  Created by yinyuan on 2020/12/16.
//


#import <Foundation/Foundation.h>

/// 应用形态
typedef NS_ENUM(NSUInteger, OPAppType) {
    
    /// 未知类型
    OPAppTypeUnknown = 0,
    
    /// 小程序
    OPAppTypeGadget = 1,
    
    /// 网页应用
    OPAppTypeWebApp = 5,
    
    /// widget 卡片
    OPAppTypeWidget = 6,
    
    /// block
    OPAppTypeBlock = 7,
    
    OPAppTypeDynamicComponent = 8,
     ///thirdNativeApp
    OPAppTypeThirdNativeApp = 9,
    
    ///仅SDK类型，开放平台 open.feishu.cn 无对应应用形态
    OPAppTypeSDKMsgCard = 11
};

/// OPAppType 转为字符串，仅用于日志、埋点等场景，不允许用于逻辑判断
FOUNDATION_EXPORT NSString * _Nonnull OPAppTypeToString(OPAppType appType);

FOUNDATION_EXPORT OPAppType OPAppTypeFromString(NSString * _Nullable appTypeString);
