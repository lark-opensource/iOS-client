//
//  ACCSubscription.h
//  Pods
//
//  Created by leo on 2019/12/27.
//

#import <Foundation/Foundation.h>
#import "ACCSubscriber.h"
#import "ACCDisposable.h"

NS_ASSUME_NONNULL_BEGIN

typedef id _Nullable (^StateSelector)(id _Nullable state, id _Nullable oldState, BOOL *hasChange);

@interface ACCSubscription : NSObject
@property (nonatomic, copy, readonly) StateSelector stateSelector;
- (instancetype)initWithTopic:(NSString *)topic;
- (instancetype)initWithTopic:(NSString *)topic stateSelector:(StateSelector)selector;

- (ACCDisposable *)addSubscriber:(id<ACCSubscriber>)subscriber;

- (void)stateChanged:(id)state previousState:(id)oldState;
@end

NS_ASSUME_NONNULL_END
