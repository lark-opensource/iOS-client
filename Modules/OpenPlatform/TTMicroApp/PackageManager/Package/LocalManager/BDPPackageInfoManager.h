//
//  BDPPackageInfoManager.h
//  Timor
//
//  Created by houjihu on 2020/5/24.
//

#import <Foundation/Foundation.h>
#import "BDPPackageInfoManagerProtocol.h"
#import <OPFoundation/BDPModuleEngineType.h>

NS_ASSUME_NONNULL_BEGIN

/// 代码包下载信息管理类
@interface BDPPackageInfoManager: NSObject <BDPPackageInfoManagerProtocol>

- (instancetype)initWithAppType:(BDPType)appType;

/// NS_UNAVAILABLE
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
