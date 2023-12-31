//
//  DYOpenNetworkService+Internal.h
//  DouyinOpenPlatformSDK
//
//  Created by arvitwu on 2022/12/14.
//

#import "DYOpenNetworkService.h"

NS_ASSUME_NONNULL_BEGIN

@interface DYOpenNetworkService (Internal)

/// 添加泳道
+ (void)dyopen_addLaneHeaderIfNeeded:(NSMutableURLRequest *)request;

@end

NS_ASSUME_NONNULL_END
