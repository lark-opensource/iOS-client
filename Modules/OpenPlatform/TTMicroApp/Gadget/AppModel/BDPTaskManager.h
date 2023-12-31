//
//  BDPTaskManager.h
//  Timor
//
//  Created by 王浩宇 on 2019/5/23.
//

#import <Foundation/Foundation.h>
#import "BDPTask.h"
#import <OPFoundation/BDPUniqueID.h>

#define BDPTaskFromUniqueID(uniqueID) [[BDPTaskManager sharedManager] getTaskWithUniqueID:uniqueID]
#define BDPCurrentTask BDPTaskFromUniqueID(self.uniqueID)

@interface BDPTaskManager : NSObject

+ (instancetype)sharedManager;

// 外部调用方避免多线程问题
- (void)addTask:(BDPTask *)task uniqueID:(BDPUniqueID *)uniqueID;
- (void)removeTaskWithUniqueID:(BDPUniqueID *)uniqueID;

- (BDPTask *)getTaskWithUniqueID:(BDPUniqueID *)ID;

@end
