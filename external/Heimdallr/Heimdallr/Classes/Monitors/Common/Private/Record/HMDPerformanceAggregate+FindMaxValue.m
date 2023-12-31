//
//  HMDPerformanceAggregate+CPUAggregate.m
//  AWECloudCommand
//
//  Created by zhangxiao on 2020/8/31.
//

#import "HMDPerformanceAggregate+FindMaxValue.h"
#import "NSDictionary+HMDSafe.h"
#import "NSArray+HMDSafe.h"
#import "NSDictionary+HMDSafe.h"
#import <objc/runtime.h>

@implementation HMDPerformanceAggregate (FindMaxValue)

- (void)setIndexKeys:(NSMutableDictionary *)indexKeys {
    objc_setAssociatedObject(self, @selector(indexKeys), indexKeys, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSMutableDictionary *)indexKeys {
    NSMutableDictionary *indexKeys = objc_getAssociatedObject(self, _cmd);
    return indexKeys;
}

- (NSArray *)findMaxValueAggregateWithSessionID:(NSString *)sessionID
                                  aggregateKeys:(NSDictionary *)keys
                        needAggregateDictionary:(NSDictionary *)needAggregateDictionary
                               normalDictionary:(NSDictionary *)normalDictionary
                                 listDictionary:(NSDictionary<NSString *,NSArray<NSDictionary *> *> *)listDictionary
                              currentecordIndex:(NSInteger)currentecordIndex
                         findMaxValueDictionary:(NSDictionary<NSString *,NSDictionary *> *)findMaxValueDict {
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
    if (!self.indexKeys) {
        self.indexKeys = [NSMutableDictionary dictionary];
    }

    if (dict && [dict isKindOfClass:[NSMutableDictionary class]]) {
        [normalDictionary enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull value, BOOL * _Nonnull stop) {
            if ([value isKindOfClass:[NSNumber class]]) {
                if ([value doubleValue] > [dict hmd_doubleForKey:key]) {
                    [dict setValue:value forKey:key];
                }
            }
        }];

        [needAggregateDictionary enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull value, BOOL * _Nonnull stop) {
            NSString *keyString = (NSString*)key;
            if ([keyString isEqualToString:@"extra_values"]) {
                NSMutableDictionary *extraValuesDictionary = [dict valueForKey:@"extra_values"];
                NSMutableDictionary *needAggregateExtraValuesDictionary = [needAggregateDictionary valueForKey:@"extra_values"];
                [self aggregateExtraDictWithNeedAggregateDict:needAggregateExtraValuesDictionary targetCacheDict:extraValuesDictionary aggregateKey:aggregateKey depth:0];
            } else {
                if ([value isKindOfClass:[NSNumber class]]) {
                    double result = [dict hmd_doubleForKey:key];
                    result = ((result * ((double)currentecordIndex)) + [value doubleValue]) / ((double)(currentecordIndex + 1));
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
                                NSMutableDictionary *dict = [existingLists hmd_objectAtIndex:index];
                                if ([dict objectForKey:key]) {
                                    double result = [dict hmd_doubleForKey:key];
                                    result = ((result * ((double)currentecordIndex)) + [value doubleValue]) / ((double)(currentecordIndex + 1));
                                    [dict setValue:@(result) forKey:key];
                                } else {
                                    [dict setValue:value forKey:key];
                                }
                            }
                        }];
                    }
                } else {
                    [existingLists hmd_addObject:obj2];
                }
            }];
        }];

        [findMaxValueDict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull firstKey, id  _Nonnull willCompareValueDict, BOOL * _Nonnull stop) {
            id oriCompareValueDict = [dict valueForKey:firstKey];
            if ([oriCompareValueDict isKindOfClass:[NSDictionary class]] &&
                [willCompareValueDict isKindOfClass:[NSDictionary class]]) {
                [(NSDictionary *)willCompareValueDict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull itemKey, id  _Nonnull obj, BOOL * _Nonnull stop) {
                    double beforRes = [oriCompareValueDict hmd_doubleForKey:itemKey];
                    double currenRes = [(NSDictionary *)willCompareValueDict hmd_doubleForKey:itemKey];
                    if (currenRes > beforRes &&
                        [oriCompareValueDict isKindOfClass:[NSMutableDictionary class]]) {
                        [oriCompareValueDict setValue:obj forKey:itemKey];
                    } else if (currenRes > beforRes) {
                        NSMutableDictionary *mutableCopyDict = [oriCompareValueDict mutableCopy];
                        [mutableCopyDict setValue:obj forKey:itemKey];
                        [dict setValue:mutableCopyDict forKey:firstKey];
                    }
                }];
            }
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
                    if ([obj isKindOfClass:[NSDictionary class]]) {
                        [((NSDictionary *)obj) enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull subKey, id  _Nonnull subObj, BOOL * _Nonnull stop) {
                            NSString *indexKey = [NSString stringWithFormat:@"%@_%@_%@",aggregateKey, key, subKey];
                            [self.indexKeys hmd_setObject:@(1) forKey:indexKey];
                        }];
                    } else {
                        NSString *indexKey = [NSString stringWithFormat:@"%@_%@",aggregateKey,key];
                        [self.indexKeys hmd_setObject:@(1) forKey:indexKey];
                    }
                }];
            }
        }];

        NSDictionary *extraStatus = [NSMutableDictionary new];
        [keys enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull value, BOOL * _Nonnull stop) {
            [extraStatus setValue:value forKey:key];
        }];
        if (extraStatus.count > 0) {
            [fullDictionary setValue:extraStatus forKey:@"extra_status"];
        }

        [listDictionary enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSArray<NSDictionary *> * _Nonnull lists, BOOL * _Nonnull stop) {
            [fullDictionary setValue:[lists mutableCopy] forKey:key];
        }];

        // findMaxValueDict 是合并到 指定的 dict 里面去的;
        [findMaxValueDict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
           id willMergeDict = [fullDictionary valueForKey:key];
           if (willMergeDict &&
               [willMergeDict isKindOfClass:[NSDictionary class]] &&
               [obj isKindOfClass:[NSDictionary class]]) {
               NSMutableDictionary *mutableCopy = [(NSDictionary *)willMergeDict mutableCopy];
               [mutableCopy addEntriesFromDictionary:obj];
           } else if(willMergeDict == nil &&
           [obj isKindOfClass:[NSDictionary class]]) {
               [fullDictionary setValue:[(NSDictionary *)obj mutableCopy] forKey:key];
           }
        }];

        [self.tracksDictionary setValue:fullDictionary forKey:aggregateKey];
    }
    return nil;
}

- (void)aggregateExtraDictWithNeedAggregateDict:(NSDictionary *)needAggregateDict
                                targetCacheDict:(NSMutableDictionary *)targetCacheDict
                                   aggregateKey:(NSString *)aggregateKey
                                          depth:(NSUInteger)depth; {
    if (depth > 2) { return; }
    if (![needAggregateDict isKindOfClass:[NSDictionary class]]) {
        return;
    }
    if (![targetCacheDict isKindOfClass:[NSMutableDictionary class]]) {
        return;;
    }

    if (targetCacheDict && [targetCacheDict isKindOfClass:[NSMutableDictionary class]]) {
        [needAggregateDict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull extraValuesKey, id  _Nonnull extraValue, BOOL * _Nonnull stop) {
            NSString *indexKey = [NSString stringWithFormat:@"%@_%@",aggregateKey,extraValuesKey];
            if ([extraValue isKindOfClass:[NSNumber class]]) {
                NSInteger originlIndex = 0;
                if ([self.indexKeys.allKeys containsObject:indexKey]) {
                    originlIndex = [self.indexKeys hmd_integerForKey:indexKey];
                    [self.indexKeys setValue:@(originlIndex+1) forKey:indexKey];
                } else {
                    [self.indexKeys setValue:@(1) forKey:indexKey];
                }
                double re = [targetCacheDict hmd_doubleForKey:extraValuesKey];
                re = ((re * ((double)originlIndex)) + [extraValue doubleValue]) / ((double)(originlIndex + 1));
                [targetCacheDict setValue:@(re) forKey:extraValuesKey];
            } else if ([extraValue isKindOfClass:[NSDictionary class]]) {
                NSMutableDictionary *subTargetExtraValue = [targetCacheDict valueForKey:extraValuesKey];
                if (!subTargetExtraValue) {
                    subTargetExtraValue = [NSMutableDictionary dictionary];
                } else if (![subTargetExtraValue isKindOfClass:[NSMutableDictionary class]]) {
                    subTargetExtraValue = [subTargetExtraValue mutableCopy];
                }
                [self aggregateExtraDictWithNeedAggregateDict:extraValue targetCacheDict:subTargetExtraValue aggregateKey:indexKey depth:depth+1];
                [targetCacheDict hmd_setObject:subTargetExtraValue forKey:extraValuesKey];
            }
        }];
    }
}


@end
