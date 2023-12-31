//
//  HMDCleanupConfig.h
//  Heimdallr
//
//  Created by fengyadong on 2018/2/11.
//

#import <Foundation/Foundation.h>



@class HMDStoreCondition;
@class HMDHermasCleanupSetting;

@interface HMDCleanupConfig : NSObject

@property (atomic, assign) NSTimeInterval outdatedTimestamp; // outdatedTimestamp = 0; 本来就是零 无需初始化
@property (nonatomic, assign) NSUInteger maxSessionCount;
@property (nonatomic, assign) NSTimeInterval maxRemainDays;
@property (atomic, strong, nullable) NSArray<HMDStoreCondition *> *andConditions;

#pragma mark - For Inspector Module
/// 期望DB大小，尽可能达到该数值
@property (nonatomic, assign) NSUInteger expectedDBSize;
/// 如果超过这个阈值，则强制清空所有数据
@property (nonatomic, assign) NSUInteger devastateDBSize;

@property (nonatomic, strong, nullable) HMDHermasCleanupSetting *hermasCleanupSetting;

@end
