//
//  HMDURLHelper.h
//  Pods
//
//  Created by ByteDance on 2023/9/6.
//

#import <Foundation/Foundation.h>

@interface HMDURLHelper : NSObject

/// 拼接 Host & Path，自动添加 Protocol
///
/// 优先判断 Path 是否能单独构成 URL，如不能再考虑拼接
/// - Parameters:
///   - host: 主机
///   - path: 路径
+ (NSString * _Nullable)URLWithHost:(NSString * _Nullable)host path:(NSString * _Nullable)path;

/// 自动添加 Protocol
/// - Parameter string: 已确认包含 Host & Path 的 URLString
+ (NSString * _Nullable)URLWithString:(NSString * _Nullable)string;

@end
