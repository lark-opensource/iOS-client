//
//  BDImageMonitor.h
//  BDWebImage
//
//  Created by fengyadong on 2017/12/6.
//

#import <Foundation/Foundation.h>

@interface BDImageMonitor : NSObject

/**
 记录事件开始时间

 @param name 事件标示
 */
- (void)start:(NSString *)name;

/**
 记录时间结束时间

 @param name 事件标示
 @return 事件耗时
 */
- (NSTimeInterval)stop:(NSString *)name;

- (BOOL)ifExist:(NSString *)name;

/**
 记录数值类型

 @param number 数值
 @param name 事件标示，为空的话则默认为action
 @return 累加值，如果需要的话
 */
- (NSNumber *)recordValue:(NSNumber *)number forName:(NSString *)name;

- (void)storeData:(NSDictionary *) data forKey:(NSString *)key;
- (NSDictionary *)removeDataForKey:(NSString *)key;

/**
 清空操作，包括内存和磁盘的缓存
 */
- (void)reset;

@end
