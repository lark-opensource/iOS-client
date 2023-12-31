//
//  OPAppVersionType.h
//  OPSDK
//  (本文件保持使用 OC 便于在旧的 OC代码头文件中被引用)
//
//  Created by yinyuan on 2020/12/16.
//

#import <Foundation/Foundation.h>

/// 应用版本类型
typedef NS_ENUM(NSUInteger, OPAppVersionType) {
    
    /// 正常版
    OPAppVersionTypeCurrent = 0,
    
    /// 预览版
    OPAppVersionTypePreview = 1,
    
};

/// OPAppVersionType 转为字符串，仅用于日志、埋点等场景，不允许用于逻辑判断
FOUNDATION_EXPORT NSString * _Nonnull OPAppVersionTypeToString(OPAppVersionType versionType);

/// OPAppVersionTypeString 转为 OPAppVersionType 枚举
FOUNDATION_EXPORT OPAppVersionType OPAppVersionTypeFromString(NSString * _Nullable versionTypeString);
