//
//  HMDRecordStore+DeleteRecord.m
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/8/19.
//

#import "HMDRecordStore+DeleteRecord.h"
#import "HMDStoreCondition.h"
#import "HMDStoreIMP.h"

@implementation HMDRecordStore (DeleteRecord)

- (BOOL)cleanupRecordsWithRange:(HMDRecordLocalIDRange)range
                  andConditions:(NSArray *)andConditions
                     storeClass:(Class<HMDRecordStoreObject>)storeClass
{
    NSMutableArray *conditions = [self andConditionsWithLocalIDRange:range andConditions:andConditions];
    return [self.database deleteObjectsFromTable:[storeClass tableName]
                                   andConditions:conditions
                                    orConditions:nil];
}

- (BOOL)logicalCleanupRecordsWithRange:(HMDRecordLocalIDRange)range
                         andConditions:(NSArray *)andConditions
                            storeClass:(Class<HMDRecordStoreObject>)storeClass
                                object:(id)object
{
    NSMutableArray *conditions = [self andConditionsWithLocalIDRange:range andConditions:andConditions];
    return [self.database updateRowsInTable:[storeClass tableName] onProperty:@"needUpload" propertyValue:@(0) withObject:object andConditions:conditions orConditions:nil];
}

+ (HMDRecordLocalIDRange)localIDRange:(NSArray *)records
{
    __block HMDRecordLocalIDRange range = {NSUIntegerMax,0};
    NSString *propertyName = @"localID";
    SEL sel = NSSelectorFromString(propertyName);
    [records enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:sel]) {
            NSUInteger localID = [[obj valueForKey:propertyName] unsignedIntegerValue];
            if (range.minLocalID > localID) {
                range.minLocalID = localID;
            }
            if (range.maxLocalID < localID) {
                range.maxLocalID = localID;
            }
        }
    }];
    return range;
}

- (NSMutableArray *)andConditionsWithLocalIDRange:(HMDRecordLocalIDRange)range
                                    andConditions:(NSArray *)andConditions
{
    NSMutableArray *conditions = [NSMutableArray array];
    if (andConditions.count) {
        [conditions addObjectsFromArray:andConditions];
    }
    
    if (range.minLocalID <= range.maxLocalID) {
        HMDStoreCondition *condition1 = [[HMDStoreCondition alloc] init];
        condition1.key = @"localID";
        double minThreshold = range.minLocalID - 0.5;
        condition1.threshold = minThreshold;
        condition1.judgeType = HMDConditionJudgeGreater;
        [conditions addObject:condition1];

        HMDStoreCondition *condition2 = [[HMDStoreCondition alloc] init];
        condition2.key = @"localID";
        double maxThreshold = range.maxLocalID + 0.5;
        condition2.threshold = maxThreshold;
        condition2.judgeType = HMDConditionJudgeLess;
        [conditions addObject:condition2];
    }
    
    return conditions;
}

@end
