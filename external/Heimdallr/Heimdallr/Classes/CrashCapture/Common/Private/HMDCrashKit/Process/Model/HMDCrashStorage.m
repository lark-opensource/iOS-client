//
//  HMDCrashStorage.m
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/8/20.
//

#import "HMDCrashStorage.h"

@implementation HMDCrashStorage

- (void)updateWithDictionary:(NSDictionary *)dict
{
    [super updateWithDictionary:dict];
    self.free = [dict hmd_unsignedLongLongForKey:@"free"];
    self.total = [dict hmd_unsignedLongLongForKey:@"total"];
}

@end
