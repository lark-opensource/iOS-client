//
//  BDTrackerUtility.m
//  RangersAppLog
//
//  Created by bytedance on 9/26/22.
//

#import "BDTrackerUtility.h"

@implementation BDTrackerUtility

+ (id)jsonFromData:(NSData *)data
{
    if (![data isKindOfClass:NSData.class]) {
        return nil;
    }
    if (data.length == 0) {
        return nil;
    }
    @try {
        return [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    }@catch(...){
        return nil;
    }
}


@end
