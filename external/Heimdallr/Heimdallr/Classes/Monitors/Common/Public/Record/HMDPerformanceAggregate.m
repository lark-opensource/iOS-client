//
//  HMDPerformanceAggregate.m
//  Heimdallr
//
//  Created by joy on 2018/4/17.
//

#import "HMDPerformanceAggregate.h"
#import "NSDictionary+HMDSafe.h"

@interface HMDPerformanceAggregate ()

@property (nonatomic, strong) NSMutableDictionary *indexKeys;

@end

@implementation HMDPerformanceAggregate
- (instancetype)init {
    if (self = [super init]) {
        self.tracksDictionary = [NSMutableDictionary new];
    }
    return self;
}
- (NSArray *)aggregateWithSessionID:(NSString *)sessionID aggregateKeys:(NSDictionary *)keys needAggregateDictionary:(NSDictionary *)needAggregateDictionary normalDictionary:(NSDictionary *)normalDictionary listDictionary:(NSDictionary<NSString*, NSArray<NSDictionary *>*> *)listDictionary currentecordIndex:(NSInteger)currentecordIndex {
/* Protect the exception case whose seesionID is null */
    if (!sessionID) {
        return nil;
    }
    
    NSMutableString *aggregateKey = [[NSMutableString alloc] initWithString:sessionID];
    [keys enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull value, BOOL * _Nonnull stop) {
        NSString *re = nil;
        if ([value isKindOfClass:[NSString class]]) {
            re = value;
        } else if ([value isKindOfClass:[NSNumber class]]) {
            re = [value stringValue];
        }
        if (re && [re isKindOfClass:[NSString class]]) {
            [aggregateKey appendFormat:@"_%@",re];
        }
    }];
    
    NSMutableDictionary *dict = [self.tracksDictionary valueForKey:aggregateKey];
    NSMutableDictionary *indexKeys = [NSMutableDictionary new];
    
    if (dict && [dict isKindOfClass:[NSMutableDictionary class]]) {
        [normalDictionary enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull value, BOOL * _Nonnull stop) {
            if ([value isKindOfClass:[NSNumber class]]) {
                if ([value doubleValue] > [[dict valueForKey:key] doubleValue]) {
                    [dict setValue:value forKey:key];
                }
            }
        }];
        
        [needAggregateDictionary enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull value, BOOL * _Nonnull stop) {
            NSString *keyString = (NSString*)key;
            if ([keyString isEqualToString:@"extra_values"]) {
                NSMutableDictionary *extra_valuesDictionary = [dict valueForKey:@"extra_values"];
                NSMutableDictionary *needAggregateExtraValuesDictionary = [needAggregateDictionary valueForKey:@"extra_values"];
                if (extra_valuesDictionary && [extra_valuesDictionary isKindOfClass:[NSMutableDictionary class]]) {
                    [needAggregateExtraValuesDictionary enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull extraValuesKey, id  _Nonnull extraValue, BOOL * _Nonnull stop) {
                        if ([extraValue isKindOfClass:[NSNumber class]]) {
                            NSString *indexKey = [NSString stringWithFormat:@"%@_%@",aggregateKey,extraValuesKey];
                            NSInteger originlIndex = 0;
                            if ([indexKeys.allKeys containsObject:indexKey]) {
                                originlIndex = [[indexKeys objectForKey:indexKey] integerValue];
                                [indexKeys setValue:@(originlIndex+1) forKey:indexKey];
                            } else {
                                [indexKeys setValue:@(1) forKey:indexKey];
                            }
                            double re = [[extra_valuesDictionary valueForKey:extraValuesKey] doubleValue];
                            re = ((re * originlIndex) + [extraValue doubleValue]) / (originlIndex + 1);
                            [extra_valuesDictionary setValue:@(re) forKey:extraValuesKey];
                        }
                    }];
                }
            } else {
                if ([value isKindOfClass:[NSNumber class]]) {
                    double result = [[dict valueForKey:key] doubleValue];
                    result = ((result * currentecordIndex) + [value doubleValue]) / (currentecordIndex + 1);
                    [dict setValue:@(result) forKey:key];
                }
            }
        }];
        
        [listDictionary enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSArray<NSMutableDictionary *> * _Nonnull obj1, BOOL * _Nonnull stop1) {
            NSMutableArray<NSMutableDictionary *> *existingLists = [dict objectForKey:key];
            NSMutableArray<NSString *> *existingKeyLists = [existingLists valueForKey:@"name"];
            [obj1 enumerateObjectsUsingBlock:^(NSMutableDictionary * _Nonnull obj2, NSUInteger idx, BOOL * _Nonnull stop2) {
                NSString *uniqueKey = [obj2 objectForKey:@"name"];
                if ([existingKeyLists containsObject:uniqueKey]) {
                    NSUInteger index = [existingKeyLists indexOfObject:uniqueKey];
                    if (index < existingKeyLists.count) {
                        [obj2 enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull value, BOOL * _Nonnull stop) {
                            if ([value isKindOfClass:[NSNumber class]]) {
                                NSMutableDictionary *dict = [existingLists objectAtIndex:index];
                                if ([dict objectForKey:key]) {
                                    double result = [[dict valueForKey:key] doubleValue];
                                    result = ((result * currentecordIndex) + [value doubleValue]) / (currentecordIndex + 1);
                                    [dict setValue:@(result) forKey:key];
                                } else {
                                    [dict setValue:value forKey:key];
                                }
                            }
                        }];
                    }
                } else {
                    [existingLists addObject:obj2];
                }
            }];
        }];
    } else {

        NSMutableDictionary *fullDictionary = [[NSMutableDictionary alloc] initWithDictionary:normalDictionary];
        [fullDictionary setValue:sessionID forKey:@"session_id"];
        [needAggregateDictionary enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull value, BOOL * _Nonnull stop) {
            [fullDictionary setValue:value forKey:key];
            NSString *keyString = (NSString*)key;
            if ([keyString isEqualToString:@"extra_values"]) {
                NSDictionary *extraValues = value;
                [extraValues enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                    NSString *indexKey = [NSString stringWithFormat:@"%@_%@",aggregateKey,key];
                    [indexKeys setObject:@(1) forKey:indexKey];
                }];
            }
        }];
        NSDictionary *extra_status = [NSMutableDictionary new];
        [keys enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull value, BOOL * _Nonnull stop) {
            [extra_status setValue:value forKey:key];
        }];
        if (extra_status.count > 0) {
            [fullDictionary setValue:extra_status forKey:@"extra_status"];
        }

        [listDictionary enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSArray<NSDictionary *> * _Nonnull lists, BOOL * _Nonnull stop) {
            [fullDictionary setValue:[lists mutableCopy] forKey:key];
        }];
        
        [self.tracksDictionary setValue:fullDictionary forKey:aggregateKey];
    }
    return nil;
}

- (NSArray *)getAggregateRecords {
    NSMutableArray *records = [[NSMutableArray alloc] init];
    [self.tracksDictionary enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull value, BOOL * _Nonnull stop) {
        if (value) {
            [records addObject:value];
        }
    }];
    
    return records;
}
@end
