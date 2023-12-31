//
//  TSPKCallStackFilterFunc.m
//  TSPrivacyKit
//
//  Created by bytedance on 2022/7/27.
//

#import "TSPKCallStackFilterFunc.h"
#import "TSPKCallStackFilter.h"
#import <BytedanceKit/NSDictionary+BTDAdditions.h>

@implementation TSPKCallStackFilterFunc

- (NSString *)symbol {
    return @"call_stack_filter";
}

- (id)execute:(NSMutableArray *)params {
    if (params.count >= 1) {
        NSArray *dataTypes = params[0];
        NSString *dataType = dataTypes.firstObject;

        if (dataType.length == 0) {
            return @NO;
        }

        BOOL allowCall = [[TSPKCallStackFilter shared] checkAllowCallWithDataType:dataType];

        return @(!allowCall);

    } else {
        return @NO;
    }
}

@end
