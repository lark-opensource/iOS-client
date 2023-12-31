//
//  HMDFMDBConditionHelper.h
//  Heimdallr
//
//  Created by joy on 2018/6/13.
//

#import <Foundation/Foundation.h>

@class HMDStoreCondition;

@interface HMDFMDBConditionHelper : NSObject

+ (NSString *_Nullable)totalFMDBConditionWithAndList:(NSArray<HMDStoreCondition *>*_Nullable)andConditions;

+ (NSString *_Nullable)totalFMDBConditionWithOrList:(NSArray<HMDStoreCondition *>*_Nullable)orConditions;

+ (NSString *_Nullable)totalFMDBConditionWithAndList:(NSArray<HMDStoreCondition *>*_Nullable)andConditions
                                              orList:(NSArray<HMDStoreCondition *>*_Nullable)orConditions;
@end
