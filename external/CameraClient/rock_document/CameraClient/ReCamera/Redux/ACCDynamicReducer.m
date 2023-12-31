//
//  ACCDynamicReducer.m
//  CameraClient
//
//  Created by leo on 2019/12/19.
//

#import "ACCDynamicReducer.h"

@interface ACCDynamicReducer ()
@property (nonatomic, strong) NSMutableDictionary *mutableReducerMap;
@end

@implementation ACCDynamicReducer
+ (instancetype)reducer
{
    return [self reducerWithReducers:@{}];
}

+ (instancetype)reducerWithReducers:(NSDictionary *)reducers
{
    NSMutableDictionary *mutableReducerMap = [reducers mutableCopy];
    ACCDynamicReducer *reducer = [[self alloc] init];
    reducer.mutableReducerMap = mutableReducerMap;
    return reducer;
}

// TODO: Lock ?
- (void)addReducer:(ACCReducer *)reducer withKey:(nonnull NSString *)key
{
    [_mutableReducerMap setObject:reducer forKey:key];
}

- (void)addReducers:(NSDictionary *)reducerMap
{
    for (id key in reducerMap) {
        ACCReducer *reducerToAdd = reducerMap[key];
        [_mutableReducerMap setObject:reducerToAdd forKey:key];
    }
}

- (NSDictionary *)reducersMap
{
    // 这个实现稍微有点tricky, 依赖于CompositeReducer的内部实现，等有空了再改改
    return self.mutableReducerMap;
}
@end
