//
//  ACCState.m
//  Pods
//
//  Created by leo on 2019/12/11.
//

#import "ACCState.h"

@interface ACCState ()
@end

@implementation ACCState
+ (instancetype)createState
{
    return [[self alloc] init];
}
@end


@interface ACCSingleValueState ()
@property (nonatomic, strong) id realValue;
@end

@implementation ACCSingleValueState
+ (instancetype)createStateWithValue:(id)value
{
    ACCSingleValueState *state = [[self alloc] init];
    state.realValue = value;
    return state;
}

- (id)value
{
    return _realValue;
}
@end

@interface ACCCompositeState ()
@property (nonatomic, strong, readwrite) NSMutableDictionary *p_stateTree;
@end

@implementation ACCCompositeState
+ (instancetype)createStateWithDictionary:(NSDictionary *)states
{
    ACCCompositeState *state = [self new];
    state.p_stateTree = states.mutableCopy;
    
    return state;
}

- (id)objectForKeyedSubscript:(id)key
{
    return [self.p_stateTree objectForKey:key];
}

- (nullable id)valueForKey:(NSString *)key
{
    return [self.p_stateTree valueForKey:key];
}

- (NSArray *)allKeys
{
    return [self.p_stateTree allKeys];
}

- (void)addState:(id)state ForKey:(NSString *)key
{
    if (state && key.length > 0) {
        self.p_stateTree[key] = state;
    }
}

- (NSDictionary *)stateTree
{
    return [self.p_stateTree copy];
}

@end
