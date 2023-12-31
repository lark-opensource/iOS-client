//
//  HMDServerStateManager.h
//  Heimdallr
//
//  Created by wangyinhui on 2021/11/18.
//

#import <Foundation/Foundation.h>
#import "HMDServerStateChecker.h"

@interface HMDServerStateManager : NSObject

+ (instancetype _Nonnull)shared;

/// 通过 HMDReporter 查找上报模块对应 ServerChecker，不存在时创建
/// - Parameter reporter: 上报场景
- (HMDServerStateChecker * _Nullable)getServerChecker:(HMDReporter)reporter;

/// 通过 HMDReporter+AppID 查找上报模块对应 ServerChecker，不存在时创建；SDK 上报场景时使用
/// - Parameters:
///   - reporter: 上报场景
///   - aid: AppID / SDK aid
- (HMDServerStateChecker * _Nullable)getServerChecker:(HMDReporter)reporter forApp:(NSString * _Nullable)aid;

@end
