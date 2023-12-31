//
//  BDPAppLoadManager.h
//  Timor
//
//  Created by lixiaorui on 2020/7/26.
//

#import <OPFoundation/BDPPkgFileReadHandleProtocol.h>
#import "BDPAppLoadContext.h"
#import "BDPAppPreloadInfo.h"
#import <OPFoundation/BDPModel.h>
NS_ASSUME_NONNULL_BEGIN

/// 返回飞书冷启动开始时间
FOUNDATION_EXTERN NSTimeInterval BDPLarkColdLaunchTime(void);

/**
 meta请求、包加载对外服务
 */
// BDPAppLoadManager及相关分类为新版meta/包管理流程接入适配文件
@interface BDPAppLoadManager : NSObject

- (instancetype _Nonnull)init NS_UNAVAILABLE;
+ (instancetype _Nonnull)new NS_UNAVAILABLE;

+ (instancetype)shareService;

@end

NS_ASSUME_NONNULL_END
