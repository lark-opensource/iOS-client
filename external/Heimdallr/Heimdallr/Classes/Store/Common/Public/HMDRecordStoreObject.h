//
//  HMDRecordStoreObject.h
//  Heimdallr
//
//  Created by 刘诗彬 on 2018/1/2.
//

#import <Foundation/Foundation.h>

@protocol HMDRecordStoreObject <NSObject>

+ (NSString * _Nonnull)tableName;

@optional
+ (NSArray <NSDictionary *>* _Nullable)reportDataForRecords:(NSArray * _Nullable)records;

+ (NSArray <NSDictionary *>* _Nullable)aggregateDataForRecords:(NSArray * _Nullable)records;

// 与 HMDInspector 数据库监控有关
// 取值范围为[0, 100] 默认值为 20
// 0 意味着不清理
// 100 意味着完全清理
+ (NSUInteger)cleanupWeight;

///  HMDRecordMonitor 的实现问题
+ (NSArray <NSDictionary *>* _Nullable)aggregateDataWithRecords:(NSArray * _Nullable)records;

@end
