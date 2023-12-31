//
//  BDPAppLoadManager+Private.h
//  Timor
//
//  Created by lixiaorui on 2020/7/26.
//

#import "BDPAppLoadManager.h"

NS_ASSUME_NONNULL_BEGIN
/**
 meta请求、包加载对外服务
 */
@interface BDPAppLoadManager ()

@property (nonatomic, strong) dispatch_queue_t serialQueue;
@property (nonatomic, assign) BOOL adpationChecked;

// 真正meta和包管理通用的CommonAppLoader
@property (nonatomic, strong) id loader;

@end

NS_ASSUME_NONNULL_END
