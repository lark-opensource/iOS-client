//
//  HMDCrashRuntimeInfo.m
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/9/18.
//

#import "HMDCrashRuntimeInfo.h"
#import "NSString+HMDCrash.h"

@implementation HMDCrashRuntimeInfo

- (void)updateWithDictionary:(NSDictionary *)dict
{
    [super updateWithDictionary:dict];
    
    self.selector = [dict hmd_stringForKey:@"sel"];
    
    NSArray *crash_info_strings = [dict hmd_arrayForKey:@"crash_infos"];
    if (crash_info_strings.count > 0) {
        NSMutableArray *crashInfos = [NSMutableArray array];
        [crash_info_strings enumerateObjectsUsingBlock:^(NSString *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:NSString.class]) {
                NSString *str = [obj hmdcrash_stringWithHex];
                if (str) {
                    [crashInfos addObject:str];
                }
            }
        }];
        if (crashInfos.count) {
            self.crashInfos = crashInfos;
        }
    }
}

@end
