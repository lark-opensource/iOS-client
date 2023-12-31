//
//  CTTelephonyNetworkInfo+AWEDataService.m
//  IESFoundation
//
//  Created by Wangmin on 2021/1/25.
//

#import "CTTelephonyNetworkInfo+AWEDataService.h"
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <TTReachability/TTReachability.h>

@implementation CTTelephonyNetworkInfo (AWEDataService)

static NSString *lastRadioAccessTechnology = nil;
static NSString *currentRadioAccess = nil;

+ (NSString *)currentRaidoAccess
{
    NSString *currentRadioAccessTechnology = nil;
    if (@available(iOS 13.0, *)) {
        currentRadioAccessTechnology = [TTReachability currentRadioAccessTechnologyForDataService];
    } else {
        currentRadioAccessTechnology = [TTReachability currentRadioAccessTechnologyForService:TTCellularServiceTypePrimary];
    }
    if (lastRadioAccessTechnology && [currentRadioAccessTechnology isEqualToString:lastRadioAccessTechnology]) {
    } else if (currentRadioAccessTechnology.length > 23 && [currentRadioAccessTechnology containsString:@"CTRadioAccessTechnology"]) {
        lastRadioAccessTechnology = currentRadioAccessTechnology;
        currentRadioAccess = [[currentRadioAccessTechnology substringFromIndex:23] lowercaseString];
    }
    return currentRadioAccess;
}

@end
