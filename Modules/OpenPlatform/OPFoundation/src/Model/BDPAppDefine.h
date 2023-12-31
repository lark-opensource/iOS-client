//
//  BDPAppDefine.h
//  OPFoundation
//
//  Created by justin on 2022/12/22.
//

#ifndef BDPAppDefine_h
#define BDPAppDefine_h

// FROM: TTMicroApp, BDPDefineBase.h 
#pragma mark - Enum
/* ------- 开放平台基础数据 - 枚举 ------- */

typedef NS_ENUM(NSUInteger, BDPAppStatus) {
    BDPAppStatusUnpublished = 0,                    // 小程序状态 - 未发布
    BDPAppStatusNormal = 1,                         // 小程序状态 - 已发布
    BDPAppStatusDisable = 2                         // 小程序状态 - 已下架
};

typedef NS_ENUM(NSUInteger, BDPAppVersionStatus) {
    BDPAppVersionStatusNormal = 0,                  //  小程序版本状态 - 正常状态
    BDPAppVersionStatusNoPermission = 1,            //  小程序版本状态 - 当前用户无权限访问小程序
    BDPAppVersionStatusIncompatible = 2,            //  小程序版本状态 - 小程序不支持当前宿主环境
    BDPAppVersionStatusPreviewExpired = 4           //  预览版二维码已过期（有效期1d）
};

typedef NS_ENUM(NSUInteger, BDPAppShareLevel) {
    BDPAppShareLevelUnknown = 0,                    // 小程序分享级别 - 未指定
    BDPAppShareLevelGrey = 1,                       // 小程序分享级别 - 灰名单
    BDPAppShareLevelWhite = 2,                      // 小程序分享级别 - 白名单
    BDPAppShareLevelBlack = 3                       // 小程序分享级别 - 黑名单
};


#endif /* BDPAppDefine_h */
