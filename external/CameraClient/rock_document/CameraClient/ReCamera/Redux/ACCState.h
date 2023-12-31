//
//  ACCState.h
//  Pods
//
//  Created by leo on 2019/12/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCState : NSObject
+ (instancetype)createState;
@end

@interface ACCSingleValueState<__covariant ValueType> : ACCState
+ (instancetype)createStateWithValue:(ValueType)value;
- (ValueType)value;
@end

@protocol ACCCompositeState <NSObject>
+ (instancetype)createStateWithDictionary:(NSDictionary *)states;
- (nullable id)objectForKeyedSubscript:(NSString *)key;
- (nullable id)valueForKey:(NSString *)key;
- (NSArray *)allKeys;
@end

@interface ACCCompositeState: ACCState <ACCCompositeState>
@property (nonatomic, strong, readonly) NSDictionary *stateTree;
- (void)addState:(id)state ForKey:(NSString *)key;
@end

NS_ASSUME_NONNULL_END
