//
//  HMDNetTrafficUsageModel.m
//  Pods
//
//  Created by zhangxiao on 2020/8/17.
//

#import "HMDNetTrafficSourceUsageModel.h"
#import "NSArray+HMDSafe.h"

NSString *const kHMDTrafficBizUsageReportKeyBiz = @"biz";
NSString *const kHMDTrafficBizUsageReportKeyPath = @"path";
NSString *const kHMDTrafficBizUsageReportKeyUsage = @"usage";
NSString *const kHMDTrafficBizUsageReportKeyFreq = @"freq";
NSString *const kHMDTrafficBizUsageReportKeySourceId = @"source_id";
NSString *const kHMDTrafficBizUsageReportKeyDetail = @"detail";

#pragma mark --- HMDNetTrafficUsageModel
@implementation HMDNetTrafficSourceUsageModel

- (instancetype)initWithSourceId:(NSString *)sourceId business:(NSString *)business {
    self = [super init];
    if (self) {
        self.souceId = sourceId;
        self.business = business;
    }
    return self;
}

- (void)addTrafficUsage:(unsigned long long)usage netType:(HMDNetTrafficSourceNetType)netType {
    switch (netType) {
        case HMDNetTrafficSourceNetTypeAll:
            self.totalUsage += usage;
            break;
        case HMDNetTrafficSourceNetTypeMobileFront:
            self.mobileFrontUsage += usage;
            break;
        case HMDNetTrafficSourceNetTypeMobileBack:
            self.mobileBackUsage += usage;
            break;
        case HMDNetTrafficSourceNetTypeWiFiFront:
            self.wifiFrontUsage += usage;
            break;
        case HMDNetTrafficSourceNetTypeWiFiBack:
            self.wifiBackUsage += usage;
        default:
            break;
    }
}

- (unsigned long long)trafficUsageWithNetType:(HMDNetTrafficSourceNetType)netType {
    unsigned long long usage = 0;
    switch (netType) {
        case HMDNetTrafficSourceNetTypeAll:
            usage = self.totalUsage;
            break;
        case HMDNetTrafficSourceNetTypeMobileFront:
            usage = self.mobileFrontUsage;
            break;
        case HMDNetTrafficSourceNetTypeMobileBack:
            usage = self.mobileBackUsage;
            break;
        case HMDNetTrafficSourceNetTypeWiFiFront:
            usage = self.wifiFrontUsage;
            break;
        case HMDNetTrafficSourceNetTypeWiFiBack:
            usage = self.wifiBackUsage;
        default:
            break;
    }
    return usage;
}

@end

#pragma mark --- HMDNetTrafficBizUsageModel
@implementation HMDNetTrafficBizUsageModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.detailMap = [NSMutableDictionary dictionary];
    }
    return self;
}

- (NSDictionary *)formatSourceDetailForNetType:(HMDNetTrafficSourceNetType)netType {
    long long usage = 0;
    switch (netType) {
        case HMDNetTrafficSourceNetTypeWiFiBack:
            usage = self.wifiBackUsage;
            break;
        case HMDNetTrafficSourceNetTypeWiFiFront:
            usage = self.wifiFrontUsage;
            break;
        case HMDNetTrafficSourceNetTypeMobileBack:
            usage = self.mobileBackUsage;
            break;
        case HMDNetTrafficSourceNetTypeMobileFront:
            usage = self.mobileFrontUsage;
            break;
        case HMDNetTrafficSourceNetTypeAll:
            usage = self.totalUsage;
            break;
        default:
            break;
    }

    if (usage > 0 && self.detailMap.count > 0) { // if there are biz's sourceId traffic usage info
        NSMutableArray *detailArray = [NSMutableArray array];
        for (HMDNetTrafficSourceUsageModel *bizSourceUsage in self.detailMap.allValues) {
            unsigned long long usageByte = [bizSourceUsage trafficUsageWithNetType:netType];
            if (usageByte == 0) {  continue; }
            NSDictionary *sourceInfo = @{
                kHMDTrafficBizUsageReportKeySourceId: bizSourceUsage.souceId ?: @"unknown",
                kHMDTrafficBizUsageReportKeyUsage: @(bizSourceUsage.usageBytes)
            };
            [detailArray hmd_addObject:sourceInfo];
        };
        NSDictionary *bizInfo = @{
            kHMDTrafficBizUsageReportKeyBiz: self.bizName ?: @"unknown",
            kHMDTrafficBizUsageReportKeyUsage: @(usage),
            kHMDTrafficBizUsageReportKeyDetail: detailArray
        };
        return bizInfo;
    } else if (usage > 0) { // 普通业务只需要上报使用量
         NSDictionary *bizInfo = @{
            kHMDTrafficBizUsageReportKeyBiz: self.bizName ?: @"unknown",
            kHMDTrafficBizUsageReportKeyUsage: @(usage),
        };
        return bizInfo;
    }

    return @{};
}

@end


#pragma mark --- HMDNetTrafficNetTypeUsageModel

@interface HMDNetTrafficNetTypeUsageModel ()

@property (nonatomic, strong, readwrite) NSMutableArray<NSDictionary *> *bizUsage;
@property (nonatomic, copy, readwrite) NSString *netTypeName;

@end

@implementation HMDNetTrafficNetTypeUsageModel

- (NSMutableArray <NSDictionary *> *)bizUsage {
    if (!_bizUsage) {
        _bizUsage = [NSMutableArray array];
    }
    return _bizUsage;
}

+ (instancetype)newModelWithNetType:(HMDNetTrafficSourceNetType)netType {
    HMDNetTrafficNetTypeUsageModel *model = [[HMDNetTrafficNetTypeUsageModel alloc] init];
    model.netType = netType;
    switch (netType) {
        case HMDNetTrafficSourceNetTypeAll:
            model.netTypeName = @"total";
            break;
        case HMDNetTrafficSourceNetTypeWiFiFront:
            model.netTypeName = @"wifi_front";
            break;
        case HMDNetTrafficSourceNetTypeMobileFront:
            model.netTypeName = @"mobile_front";
            break;
        case HMDNetTrafficSourceNetTypeWiFiBack:
            model.netTypeName = @"wifi_back";
            break;
        case HMDNetTrafficSourceNetTypeMobileBack:
            model.netTypeName = @"mobile_back";
        default:
            break;
    }

    return model;
}

@end

#pragma mark --- HMDNetTrafficIntervalUsageModel

@implementation HMDNetTrafficIntervalUsageModel

- (NSArray<HMDNetTrafficNetTypeUsageModel *> *)groupByNetType {
    NSMutableArray *group = [NSMutableArray array];
    HMDNetTrafficNetTypeUsageModel *allUsage = [HMDNetTrafficNetTypeUsageModel newModelWithNetType:HMDNetTrafficSourceNetTypeAll];

    HMDNetTrafficNetTypeUsageModel *wifiFrontUsage = [HMDNetTrafficNetTypeUsageModel newModelWithNetType:HMDNetTrafficSourceNetTypeWiFiFront];
    HMDNetTrafficNetTypeUsageModel *mobileFrontUsage = [HMDNetTrafficNetTypeUsageModel newModelWithNetType:HMDNetTrafficSourceNetTypeMobileFront];
    HMDNetTrafficNetTypeUsageModel *wifiBackUsage = [HMDNetTrafficNetTypeUsageModel newModelWithNetType:HMDNetTrafficSourceNetTypeWiFiBack];
    HMDNetTrafficNetTypeUsageModel *mobileBackUsage = [HMDNetTrafficNetTypeUsageModel newModelWithNetType:HMDNetTrafficSourceNetTypeMobileBack];

    for (HMDNetTrafficBizUsageModel *bizUsageModel in self.businessUsage) {
        if (![bizUsageModel isKindOfClass: [HMDNetTrafficBizUsageModel class]]) {
            NSAssert(NO, @"HMDNetTrafficBizUsageModel class type error");
            continue;
        }
        @autoreleasepool {
            if (bizUsageModel.totalUsage) {
                NSDictionary *total = [bizUsageModel formatSourceDetailForNetType:HMDNetTrafficSourceNetTypeAll];
                allUsage.totalUsage += bizUsageModel.totalUsage;
                [allUsage.bizUsage hmd_addObject:total];
            }
            if (bizUsageModel.wifiFrontUsage > 0) {
                NSDictionary *wifiFront = [bizUsageModel formatSourceDetailForNetType:HMDNetTrafficSourceNetTypeWiFiFront];
                wifiFrontUsage.totalUsage += bizUsageModel.wifiFrontUsage;
                [wifiFrontUsage.bizUsage hmd_addObject:wifiFront];
            }
            if (bizUsageModel.mobileFrontUsage > 0) {
                NSDictionary *mobileFront = [bizUsageModel formatSourceDetailForNetType: HMDNetTrafficSourceNetTypeMobileFront];
                mobileFrontUsage.totalUsage += bizUsageModel.mobileFrontUsage;
                [mobileFrontUsage.bizUsage hmd_addObject:mobileFront];
            }
            if (bizUsageModel.wifiBackUsage > 0) {
                NSDictionary *wifiBack = [bizUsageModel formatSourceDetailForNetType:HMDNetTrafficSourceNetTypeWiFiBack];
                wifiBackUsage.totalUsage += bizUsageModel.wifiBackUsage;
                [wifiBackUsage.bizUsage hmd_addObject:wifiBack];
            }
            if (bizUsageModel.mobileBackUsage > 0) {
                NSDictionary *cellularBack = [bizUsageModel formatSourceDetailForNetType:HMDNetTrafficSourceNetTypeMobileBack];
                mobileBackUsage.totalUsage += bizUsageModel.mobileBackUsage;
                [mobileBackUsage.bizUsage hmd_addObject:cellularBack];
            }
        }
    }

    if (allUsage) {
        [group hmd_addObject:allUsage];
    }
    if (wifiFrontUsage) {
        [group hmd_addObject:wifiFrontUsage];
    }
    if (mobileFrontUsage) {
        [group hmd_addObject:mobileFrontUsage];
    }
    if (wifiBackUsage) {
        [group hmd_addObject:wifiBackUsage];
    }
    if (mobileBackUsage) {
        [group hmd_addObject:mobileBackUsage];
    }

    return [group copy];
}

@end
