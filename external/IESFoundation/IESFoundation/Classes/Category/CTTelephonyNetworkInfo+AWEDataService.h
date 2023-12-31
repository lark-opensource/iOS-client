//
//  CTTelephonyNetworkInfo+AWEDataService.h
//  IESFoundation
//
//  Created by Wangmin on 2021/1/25.
//

#import <CoreTelephony/CTTelephonyNetworkInfo.h>

NS_ASSUME_NONNULL_BEGIN

@interface CTTelephonyNetworkInfo (AWEDataService)

+ (nullable NSString *)currentRaidoAccess;

@end

NS_ASSUME_NONNULL_END
