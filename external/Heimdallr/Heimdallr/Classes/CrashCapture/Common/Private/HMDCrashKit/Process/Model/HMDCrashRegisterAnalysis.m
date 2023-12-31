//
//  HMDCrashRegisterAnalysis.m
//  AWECloudCommand-iOS13.0
//
//  Created by yuanzhangjing on 2019/12/1.
//

#import "HMDCrashRegisterAnalysis.h"

@implementation HMDCrashRegisterAnalysis

+ (NSArray * _Nullable)objectsWithDicts:(NSArray<NSDictionary *> *)dicts {
    NSArray * _Nullable result;
    
    @autoreleasepool {
        result = [super objectsWithDicts:dicts];
    }
    return result;
}

- (void)updateWithDictionary:(NSDictionary *)dict {
    [super updateWithDictionary:dict];
    self.registerName = [dict hmd_stringForKey:@"name"];
}

- (NSDictionary *)postDict {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict hmd_setObject:self.registerName forKey:@"name"];
    
    NSDictionary *superDict = [super postDict];
    if (superDict.count) {
        [dict addEntriesFromDictionary:superDict];
    }
    return dict;
}

@end
