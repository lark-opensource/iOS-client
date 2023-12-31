//
//  HMDNetTrafficUsageModel.h
//  Pods
//
//  Created by zhangxiao on 2020/8/17.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, HMDNetTrafficSourceNetType) {
    HMDNetTrafficSourceNetTypeWiFiFront,
    HMDNetTrafficSourceNetTypeWiFiBack,
    HMDNetTrafficSourceNetTypeMobileFront,
    HMDNetTrafficSourceNetTypeMobileBack,
    HMDNetTrafficSourceNetTypeAll
};

extern NSString *const kHMDTrafficBizUsageReportKeyBiz;
extern NSString *const kHMDTrafficBizUsageReportKeyPath;
extern NSString *const kHMDTrafficBizUsageReportKeyUsage;
extern NSString *const kHMDTrafficBizUsageReportKeyFreq;
extern NSString *const kHMDTrafficBizUsageReportKeySourceId;
extern NSString *const kHMDTrafficBizUsageReportKeyDetail;

#pragma mark --- HMDNetTrafficUsageModel
@interface HMDNetTrafficSourceUsageModel : NSObject

@property (nonatomic, copy) NSString *souceId;
// 相同 source_id 执行的次数,以网络请求为例 可能是相同 path 的网络请求发起次数
@property (nonatomic, assign) NSInteger executeCount;
@property (nonatomic, assign) long long resetTimestamp;
@property (nonatomic, assign) unsigned long long usageBytes;
@property (nonatomic, copy, nullable) NSString *business;
@property (nonatomic, assign) unsigned long long totalUsage;
@property (nonatomic, assign) unsigned long long wifiBackUsage;
@property (nonatomic, assign) unsigned long long wifiFrontUsage;
@property (nonatomic, assign) unsigned long long mobileBackUsage;
@property (nonatomic, assign) unsigned long long mobileFrontUsage;

- (instancetype)initWithSourceId:(NSString *)sourceId business:(NSString *)business;
- (void)addTrafficUsage:(unsigned long long)usage netType:(HMDNetTrafficSourceNetType)netType;
- (unsigned long long)trafficUsageWithNetType:(HMDNetTrafficSourceNetType)netType;

- (nonnull id)init __attribute__((unavailable("please use initWithSourceId:business:")));
+ (nonnull instancetype)new __attribute__((unavailable("please use initWithSourceId:business:")));

@end

#pragma mark --- HMDNetTrafficBizUsageModel
@interface HMDNetTrafficBizUsageModel : NSObject

@property (nonatomic, copy) NSString *bizName;
@property (nonatomic, assign) unsigned long long totalUsage;
@property (nonatomic, assign) unsigned long long wifiBackUsage;
@property (nonatomic, assign) unsigned long long wifiFrontUsage;
@property (nonatomic, assign) unsigned long long mobileBackUsage;
@property (nonatomic, assign) unsigned long long mobileFrontUsage;
@property (nonatomic, strong, nullable) NSMutableDictionary <NSString *, HMDNetTrafficSourceUsageModel *> *detailMap;

- (NSDictionary *)formatSourceDetailForNetType:(HMDNetTrafficSourceNetType)netType;

@end

#pragma mark --- HMDNetTrafficNetTypeUsageModel
@interface HMDNetTrafficNetTypeUsageModel : NSObject

@property (nonatomic, assign) HMDNetTrafficSourceNetType netType;
@property (nonatomic, assign) long long totalUsage;
/// not thread safe
@property (nonatomic, strong, readonly) NSMutableArray<NSDictionary *> *bizUsage;
@property (nonatomic, copy, readonly) NSString *netTypeName;

+ (instancetype)newModelWithNetType:(HMDNetTrafficSourceNetType)netType;

@end

#pragma mark --- HMDNetTrafficIntervalUsageModel
@interface HMDNetTrafficIntervalUsageModel : NSObject

@property (nonatomic, strong, nullable) NSArray<HMDNetTrafficSourceUsageModel *> *largeRequest;
@property (nonatomic, strong, nullable) NSArray<HMDNetTrafficSourceUsageModel *> *highFrequencyRequest;
@property (nonatomic, strong, nullable) NSArray<HMDNetTrafficSourceUsageModel *> *largeImage;
@property (nonatomic, strong, nullable) NSArray<HMDNetTrafficBizUsageModel *> *businessUsage;

- (NSArray<HMDNetTrafficNetTypeUsageModel *> *)groupByNetType;

@end




NS_ASSUME_NONNULL_END
