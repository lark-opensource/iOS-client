//
//  BDPJSONRequestSerializer.h
//  Timor
//
//  Created by 维旭光 on 2019/3/4.
//

#import <TTNetworkManager/TTDefaultHTTPRequestSerializer.h>

NS_ASSUME_NONNULL_BEGIN
#define BDPParamBodyKey @"BDPParamBodyKey"

@interface BDPHTTPRequestSerializer : TTDefaultHTTPRequestSerializer

+ (void)setTimeoutInterval:(NSTimeInterval)timeoutInterval;

+ (NSTimeInterval)timeoutInterval;
@end

NS_ASSUME_NONNULL_END
