//
//  BDPTracker+Private.h
//  Timor
//
//  Created by 傅翔 on 2019/7/24.
//

#import "BDPTracker.h"



NS_ASSUME_NONNULL_BEGIN

@interface BDPTracker ()

@property (strong, nonatomic) dispatch_queue_t taskQueue;
@property (nonatomic, strong) NSMutableDictionary<BDPUniqueID *, NSString *> *lifecycleIdsDict;

- (void)executeBlkInTaskQueue:(dispatch_block_t)blk;

@end

NS_ASSUME_NONNULL_END
