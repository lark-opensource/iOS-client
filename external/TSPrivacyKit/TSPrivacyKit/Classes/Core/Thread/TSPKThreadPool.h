//
//  TSPKThreadPool.h
//  TSPrivacyKit
//
//  Created by PengYan on 2021/3/27.
//

#import <Foundation/Foundation.h>



@interface TSPKThreadPool : NSObject

+ (instancetype _Nullable)shardPool;

- (dispatch_queue_t _Nullable)workQueue;

- (dispatch_queue_t _Nullable)networkWorkQueue;

- (dispatch_queue_t _Nullable)lowPriorityQueue;

@end


