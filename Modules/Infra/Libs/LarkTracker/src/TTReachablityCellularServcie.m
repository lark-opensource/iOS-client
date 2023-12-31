//
//  TTReachablityCellularServcie.m
//  Template_InHouse
//
//  Created by bytedance on 2021/9/30.
//

#import "TTReachablityCellularServcie.h"
#import <TTReachability/TTReachability.h>

@implementation TTReachablityCellularServcie

- (NSInteger)cellularConnectionTypeForService:(NSInteger)service
{
    if (service == 0) {
        return 0;
    }
    return [TTReachability currentCellularConnectionForService:service];
}

- (id)carrierForService:(NSInteger)service
{
    if (service == 0) {
        return nil;
    }
    return [TTReachability currentCellularProviderForService:service];
}

- (NSInteger)currentDataServiceType
{
    NSArray *servicesTypes = [TTReachability currentAvailableCellularServices];
    if (servicesTypes.count == 0) {
        return 0;
    }else if (servicesTypes.count == 1) {
        return [servicesTypes.firstObject intValue];
    }else{
        //TTReachablity未实现这个接口。所以这种情况下返回的不准确。
        return 1;
    }
}

@end
