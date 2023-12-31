//
//  ACCStore.h
//  Pods
//
//  Created by leo on 2019/12/11.
//

#import <Foundation/Foundation.h>
#import "ACCState.h"
#import "ACCAction.h"
#import "ACCReducer.h"
#import "ACCMiddleware.h"
#import "ACCDisposable.h"
#import "ACCSubscription.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCStore<__covariant StateType> : NSObject
@property (nonatomic, strong, readonly) StateType state;
@property (nonatomic, strong, readonly) ACCReducer *reducer;

@property (nonatomic, strong) ACCMiddleware *middleware;

- (instancetype)initWithState:(StateType)state andReducer:(ACCReducer *)reducer;
- (ACCAction *)dispatch:(ACCAction *)action;

- (ACCDisposable *)subscribe:(void (^)(StateType current))stateChanged;

- (ACCDisposable *)subscribe:(void (^)(id current))stateChanged byKeypath:(NSString *)keypath;
@end

NS_ASSUME_NONNULL_END
