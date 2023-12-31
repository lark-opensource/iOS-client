//
//  NSDictionary+ACCAdditions.h
//  CreativeKit-Pods-Aweme
//
//  Created by raomengyun on 2021/5/10.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDictionary<__covariant KeyType, __covariant ObjectType> (ACCAdditions)

- (NSArray *)acc_map:(id (^)(KeyType key, ObjectType value))transform;
- (NSDictionary *)acc_filter:(BOOL (^)(KeyType key, ObjectType value))condition;
- (NSArray *)acc_flatMap:(NSArray* (^)(KeyType key, ObjectType value))transform;
- (void)acc_forEach:(void (^)(KeyType key, ObjectType value))block;
- (id)acc_reduce:(id)initial reducer:(id (^)(id preValue, KeyType key, ObjectType value))reducer;
- (BOOL)acc_all:(BOOL (^)(KeyType key, ObjectType value))condition;
- (BOOL)acc_any:(BOOL (^)(KeyType key, ObjectType value))condition;
// return an tuple, first item is key, second item is value
- (nullable NSArray *)acc_match:(BOOL (^)(KeyType key, ObjectType value))condition;

@end

NS_ASSUME_NONNULL_END
