//
//  HMDFMDBConditionHelper.m
//  Heimdallr
//
//  Created by joy on 2018/6/13.
//

#import "HMDFMDBConditionHelper.h"
#import "HMDStoreCondition.h"

@implementation HMDFMDBConditionHelper

+ (NSString *)totalFMDBConditionWithAndList:(NSArray<HMDStoreCondition *>*)andConditions {
    if (andConditions.count < 1) {
        return nil;
    }
    NSMutableString *conditionString = [[NSMutableString alloc] init];
    
    // 添加 AND
    [andConditions enumerateObjectsUsingBlock:^(HMDStoreCondition * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.stringValue) {
            if (conditionString.length > 1 && idx > 0) {
                [conditionString appendString:@" AND "];
            }
            if (obj.judgeType == HMDConditionJudgeEqual) {
                [conditionString appendFormat:@"%@ = '%@'",obj.key ,obj.stringValue];
            }
        } else {
            if (conditionString.length > 1 && idx > 0) {
                [conditionString appendString:@" AND "];
            }
            
            if (obj.judgeType == HMDConditionJudgeLess) {
                [conditionString appendFormat:@"%@ < %f",obj.key ,obj.threshold];
            }
            if (obj.judgeType == HMDConditionJudgeEqual) {
                [conditionString appendFormat:@"%@ = %f",obj.key ,obj.threshold];
            }
            if (obj.judgeType == HMDConditionJudgeGreater) {
                [conditionString appendFormat:@"%@ > %f",obj.key ,obj.threshold];
            }
            if (obj.judgeType == HMDConditionJudgeIsNULL) { // 筛选 stringValue 为 NULL 的表项
                [conditionString appendFormat:@"%@ IS NULL",obj.key];
            }
        }
        
    }];
    
    return conditionString;
}
+ (NSString *)totalFMDBConditionWithOrList:(NSArray<HMDStoreCondition *>*)orConditions {
    if (orConditions.count < 1) {
        return nil;
    }
    NSMutableString *conditionString = [[NSMutableString alloc] init];
    
    // 添加 OR
    [orConditions enumerateObjectsUsingBlock:^(HMDStoreCondition * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.stringValue) {
            if (conditionString.length > 1 && idx > 0) {
                [conditionString appendString:@" OR "];
            }
            if (obj.judgeType == HMDConditionJudgeEqual) {
                [conditionString appendFormat:@"%@ = '%@'",obj.key ,obj.stringValue];
            }
        } else {
            if (conditionString.length > 1 && idx > 0) {
                [conditionString appendString:@" OR "];
            }
            if (obj.judgeType == HMDConditionJudgeLess) {
                [conditionString appendFormat:@"%@ < %f",obj.key ,obj.threshold];
            }
            if (obj.judgeType == HMDConditionJudgeEqual) {
                [conditionString appendFormat:@"%@ = %f",obj.key ,obj.threshold];
            }
            if (obj.judgeType == HMDConditionJudgeGreater) {
                [conditionString appendFormat:@"%@ > %f",obj.key ,obj.threshold];
            }
        }
    }];
    
    return conditionString;
}
+ (NSString *)totalFMDBConditionWithAndList:(NSArray<HMDStoreCondition *>*)andConditions
                                     orList:(NSArray<HMDStoreCondition *>*)orConditions {
    NSString *totalAndConditionString = [[NSString alloc] initWithFormat:@"(%@)",[self totalFMDBConditionWithAndList:andConditions]];
    NSString *totalOrConditionString = [[NSString alloc] initWithFormat:@"(%@)",[self totalFMDBConditionWithOrList:orConditions]];

    if (orConditions.count > 0 && andConditions.count > 0) {
        NSMutableString *total = [NSMutableString stringWithFormat:@"(%@ AND %@)",totalAndConditionString, totalOrConditionString];
        return total;
    }
    if ((andConditions.count > 0) && !(orConditions.count > 0)) {
        return totalAndConditionString;
    }
    if (!(andConditions.count > 0) && (orConditions.count > 0)) {
        return totalOrConditionString;
    }

    return nil;
}
@end

