//
//  TSPKStatisticEvent.h
//  Indexer
//
//  Created by admin on 2022/2/14.
//

#import <Foundation/Foundation.h>
#import "TSPKBaseEvent.h"

extern NSString *_Nonnull const TSPKEventTagStatistic;

@interface TSPKStatisticEvent : TSPKBaseEvent

@property (nonatomic, copy, nullable) NSString *serviceName;
@property (nonatomic, copy, nullable) NSDictionary *metric;
@property (nonatomic, copy, nullable) NSDictionary *category;
@property (nonatomic, copy, nullable) NSDictionary *attributes;

+ (nonnull instancetype)initWithService:(NSString *_Nonnull)serviceName metric:(NSDictionary *_Nullable)metric category:(NSDictionary *_Nullable)category attributes:(NSDictionary *_Nullable)attributes;

+ (nonnull instancetype)initWithMethodName:(nonnull NSString *)methodName startedTime:(CFAbsoluteTime)startedTime;

@end
