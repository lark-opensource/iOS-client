//
//  HMDCrashStackAnalysis.m
//  AWECloudCommand-iOS13.0
//
//  Created by yuanzhangjing on 2019/12/1.
//

#import "HMDCrashStackAnalysis.h"

@implementation HMDCrashStackAnalysis

+ (NSArray * _Nullable)objectsWithDicts:(NSArray<NSDictionary *> *)dicts {
    
    NSArray * _Nullable result;
    
    @autoreleasepool {
        result = [super objectsWithDicts:dicts];
    }
    return result;
}

- (void)updateWithDictionary:(NSDictionary *)dict {
    [super updateWithDictionary:dict];
    self.stack_address = (uintptr_t)[dict hmd_unsignedLongLongForKey:@"address"];
}

- (NSDictionary *)postDict {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict hmd_setObject:@(self.stack_address) forKey:@"address"];
    NSDictionary *superDict = [super postDict];
    if (superDict.count) {
        [dict addEntriesFromDictionary:superDict];
    }
    return dict;
}

@end
