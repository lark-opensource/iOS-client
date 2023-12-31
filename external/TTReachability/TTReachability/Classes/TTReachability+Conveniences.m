//
//  TTReachability+Conveniences.m
//  TTReachability
//
//  Created by 李卓立 on 2019/10/22.
//

#import "TTReachability+Conveniences.h"

#if TARGET_OS_IOS
@implementation TTReachability (Conveniences)

+ (nonnull NSArray<CTCarrier *> *)currentPrioritizedCellularProviders {
    // 使用获取CTCarrier的接口，而不是基于CTRadioAccessTechnology的数量判断接口
    NSArray<CTCarrier *> *services = [self currentAvailableCellularProviders];
    // 规则4
    if (services.count == 0) {
        return services;
    }
    // 规则1
    if (services.count == 1) {
        return services;
    }
    NSMutableArray *carriers = [NSMutableArray array];
    CTCarrier *primaryCarrier = services.firstObject;
    CTCarrier *secondaryCarrier = services.lastObject;
    CTCarrier *dataCarrier = [self currentCellularProviderForDataService];
    if (dataCarrier) {
        // 规则2
        [carriers addObject:dataCarrier];
        // 不使用isEqual，CTCarrier会比较所有公开属性，但是可能存在主副卡是两个同样提供商的SIM卡
        if (dataCarrier == primaryCarrier) {
            if (secondaryCarrier) {
                [carriers addObject:secondaryCarrier];
            }
        } else {
            if (primaryCarrier) {
                [carriers addObject:primaryCarrier];
            }
        }
    } else {
        // 规则3
        if (primaryCarrier) {
            [carriers addObject:primaryCarrier];
        }
        if (secondaryCarrier) {
            [carriers addObject:secondaryCarrier];
        }
    }
    return [carriers copy];
}

+ (nonnull NSArray<NSString *> *)currentPrioritizedRadioAccessTechnologies {
    NSArray<NSNumber *> *services = [self currentAvailableCellularServices];
    // 规则4
    if (services.count == 0) {
        return @[];
    }
    NSMutableArray *technologies = [NSMutableArray array];
    // 规则1
    if (services.count == 1) {
        TTCellularServiceType type = services.firstObject.integerValue;
        NSString *technology = [self currentRadioAccessTechnologyForService:type];
        if (technology) {
            [technologies addObject:technology];
        }
        return [technologies copy];
    }
    NSString *primaryTechnology = [self currentRadioAccessTechnologyForService:TTCellularServiceTypePrimary];
    NSString *secondaryTechnology = [self currentRadioAccessTechnologyForService:TTCellularServiceTypeSecondary];
    NSString *dataTechnology = [self currentRadioAccessTechnologyForDataService];
    if (dataTechnology) {
        // 规则2
        [technologies addObject:dataTechnology];
        if (dataTechnology == primaryTechnology) {
            if (secondaryTechnology) {
                [technologies addObject:secondaryTechnology];
            }
        } else {
            if (primaryTechnology) {
                [technologies addObject:primaryTechnology];
            }
        }
    } else {
        // 规则3
        if (primaryTechnology) {
            [technologies addObject:primaryTechnology];
        }
        if (secondaryTechnology) {
            [technologies addObject:secondaryTechnology];
        }
    }
    return [technologies copy];
}

+ (nonnull NSString *)currentConnectionMethodName {
    NSString *methodName;
    NetworkStatus status = [[TTReachability reachabilityForInternetConnection] currentReachabilityStatus];
    if (status == ReachableViaWiFi) {
        methodName = @"WIFI";
    } else if (status == ReachableViaWWAN) {
        // 先检查数据流量卡（iOS 13+有效）
        TTCellularNetworkConnectionType connectiontype = [TTReachability currentCellularConnectionForDataService];
        if (connectiontype == TTCellularNetworkConnectionNone) {
            // 再检查主卡
            connectiontype = [TTReachability currentCellularConnectionForService:TTCellularServiceTypePrimary];
        }
        switch (connectiontype) {
            case TTCellularNetworkConnection5G:
                methodName = @"5G";
                break;
            case TTCellularNetworkConnection4G:
                methodName = @"4G";
                break;
            case TTCellularNetworkConnection3G:
                methodName = @"3G";
                break;
            case TTCellularNetworkConnection2G:
                methodName = @"2G";
                break;
            case TTCellularNetworkConnectionUnknown:
                methodName = @"mobile";
                break;
            case TTCellularNetworkConnectionNone:
                methodName = @"";
                break;
        }
    } else {
        methodName = @"";
    }
    return methodName;
}

@end
#endif
