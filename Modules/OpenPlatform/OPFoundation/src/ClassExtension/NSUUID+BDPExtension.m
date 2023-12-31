//
//  NSUUID+BDPExtension.m
//  Timor
//
//  Created by 傅翔 on 2019/9/5.
//

#import "NSUUID+BDPExtension.h"

@implementation NSUUID (BDPExtension)

+ (NSString *)bdp_timestampUUIDString {
    int64_t timestamp = [[NSDate date] timeIntervalSince1970] * 100000.0;
    return [NSString stringWithFormat:@"%@%lld", [[NSUUID UUID].UUIDString substringToIndex:8], (int64_t)timestamp];
}

@end
