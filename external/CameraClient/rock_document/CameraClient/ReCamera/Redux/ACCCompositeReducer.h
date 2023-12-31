//
//  ACCCompositeReducer.h
//  Pods
//
//  Created by leo on 2019/12/11.
//

#import <Foundation/Foundation.h>
#import "ACCReducer.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ACCCompositeState;
@interface ACCCompositeReducer<__covariant KeyType> : ACCReducer
@property (nonatomic, strong, readonly) NSDictionary *reducersMap;

+ (instancetype)reducerWithReducers:(NSDictionary *)reducers;
- (id<ACCCompositeState>)stateWithAction:(ACCAction *)action andState:(id<ACCCompositeState>)state;
@end

NS_ASSUME_NONNULL_END
