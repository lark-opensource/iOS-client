//
//  BDLGurdSyncResourcesManager.h
//  BDLynx
//
//  Created by  wanghanfeng on 2020/2/9.
//

#import <Foundation/Foundation.h>
#import "BDLGurdSyncResourcesTask.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDLGurdSyncResourcesManager : NSObject

+ (BDLGurdSyncResourcesManager *)sharedManager;

+ (void)enableGurd;

/**
加入同步资源任务队列;
如果对资源需求不是那么迫切，建议使用这个API
控制请求时机和频率：
1、如果是新用户，则立即发起请求；否则延迟请求
2、请求成功后，一定时间内不发请求
*/
+ (void)enqueueSyncResourcesTask:(BDLGurdSyncResourcesTask *)task;

+ (void)syncResourcesIfNeeded;

@end

NS_ASSUME_NONNULL_END
