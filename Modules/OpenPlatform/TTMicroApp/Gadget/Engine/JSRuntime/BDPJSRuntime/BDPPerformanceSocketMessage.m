//
//  BDPPerformanceSocketMessage.m
//  TTMicroApp
//
//  Created by ChenMengqi on 2022/12/12.
//

#import "BDPPerformanceSocketMessage.h"
#import <ECOInfra/JSONValue+BDPExtension.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <ECOInfra/OPMacroUtils.h>
#import <ECOInfra/BDPUtils.h>

@implementation BDPPerformanceSocketMessage

+ (instancetype)messageWithString:(NSString *)string {
    NSDictionary *dict = [string stringToDic];
    if (BDPIsEmptyDictionary(dict)) {
        return nil;
    }
    BDPPerformanceSocketMessage *message = [BDPPerformanceSocketMessage new];
    message.event = [dict bdp_stringValueForKey:@"event"];
    message.code = [dict bdp_stringValueForKey:@"code"];
    message.message = [dict bdp_stringValueForKey:@"message"];
    message.data = [dict bdp_objectForKey:@"data"];

    return message;
}

- (NSString *)string {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    if (!BDPIsEmptyString(self.code)) {
        [dict setValue:self.code forKey:@"code"];
    }
    if (!BDPIsEmptyString(self.event)) {
        [dict setValue:self.event forKey:@"event"];
    }
    if (!BDPIsEmptyString(self.message)) {
        [dict setValue:self.message forKey:@"message"];
    }
    if (!BDPIsEmptyDictionary(self.data)) {
        [dict setValue:self.data forKey:@"data"];
    }

    return [dict JSONRepresentation];
}


@end
