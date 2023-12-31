//
//  BDPTrackerHelper.h
//  Timor
//
//  Created by 维旭光 on 2019/7/4.
//

#import <Foundation/Foundation.h>
#import "BDPDefineBase.h"
#import <OPFoundation/BDPTracker.h>

// 埋点辅助接口

NS_ASSUME_NONNULL_BEGIN

@interface BDPTrackerHelper : NSObject

+ (void)setLoadState:(nullable NSString *)loadState forUniqueID:(BDPUniqueID *)uniqueID;
+ (NSString *)getLoadStateByUniqueID:(BDPUniqueID *)uniqueID;

@end

NS_ASSUME_NONNULL_END
