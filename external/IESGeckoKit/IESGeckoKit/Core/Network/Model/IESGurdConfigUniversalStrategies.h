//
//  IESGurdConfigUniversalStrategies.h
//  IESGeckoKit
//
//  Created by 陈煜钏 on 2020/10/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, IESGurdSpecifiedCleanType) {
    IESGurdSpecifiedCleanTypeUnknown = 0,
    IESGurdSpecifiedCleanTypeMatch,             //本地packageId与下发packageId完全匹配 则清理
    IESGurdSpecifiedCleanTypeLessThan,          //本地packageId小于下发packageId 则清理
    IESGurdSpecifiedCleanTypeNoMatter           //直接清理
};

@interface IESGurdConfigSpecifiedClean : NSObject

@property (nonatomic, assign) IESGurdSpecifiedCleanType cleanType;

@property (nonatomic, copy) NSString *channel;

@property (nonatomic, copy) NSArray<NSNumber *> *versions;

- (BOOL)shouldCleanWithVersion:(int64_t)version;

@end

@interface IESGurdConfigGroupClean : NSObject

@property (nonatomic, assign) NSInteger rule;   // 1- "channel_num_limit" 2-"file_size_limit"

@property (nonatomic, assign) NSInteger policy; // 1-FIFO 2-LFU 3-LRU

@property (nonatomic, assign) NSInteger limit;  // rule为1时代表channel个数；rule为2时代表文件大小

@end

@interface IESGurdConfigUniversalStrategies : NSObject
// 指定删除channels
@property (nonatomic, copy) NSArray<IESGurdConfigSpecifiedClean *> *specifiedCleanArray;

@property (nonatomic, strong) IESGurdConfigGroupClean *groupClean;

+ (instancetype _Nullable)strategiesWithDictionary:(NSDictionary *)dictionary;

+ (instancetype _Nullable)strategiesWithPackageDictionary:(NSDictionary *)dictionary;

@end

NS_ASSUME_NONNULL_END
