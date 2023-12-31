//
//  NSError+BDPExtension.h
//  Timor
//
//  Created by yinyuan on 2020/3/5.
//

#import <Foundation/Foundation.h>

#ifndef NSError_BDPExtension_h
#define NSError_BDPExtension_h

@class OPMonitorCode, OPError;
@interface NSError (BDPExtension)

/// 构建OPError
/// - Parameters:
///   - error: NSError对象
///   - monitorCode: monitorCode
///   - useCustomDescription: 是否使用自定义的信息替换userInfo中的NSLocalizedDescriptionKey
///   - userInfo: 自定义userInfo
+ (OPError *)configOPError:(NSError *)error
               monitorCode:(OPMonitorCode *)monitorCode
      useCustomDescription:(BOOL)useCustomDescription
                  userInfo:(NSDictionary *)userInfo;

/// 构建OPError
/// - Parameters:
///   - error: NSError对象
///   - monitorCode: monitorCode
///   - appendUserInfo: 是否添加userInfo到OPError中
///   - userInfo: 自定义userInfo
+ (OPError *)configOPError:(NSError *)error
               monitorCode:(OPMonitorCode *)monitorCode
            appendUserInfo:(BOOL)appendUserInfo
                  userInfo:(NSDictionary *)userInfo;
@end

#endif
