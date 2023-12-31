//
//  ACCMiddleware.h
//  Pods
//
//  Created by leo on 2019/12/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class ACCAction;

typedef ACCAction* _Nullable (^ACCActionHandler)(ACCAction *action);
typedef id _Nullable (^ACCStateGetter)(void);

@protocol ACCMiddleware <NSObject>

- (ACCAction *)handleAction:(ACCAction *)action next:(ACCActionHandler)next;

@optional
- (BOOL)shouldHandleAction:(ACCAction *)action;

- (void)bindDispatcher:(ACCActionHandler)dispatcher;
- (void)bindStateGetter:(ACCStateGetter)stateGetter;
- (void)bindStateGetterKey:(NSString *)key;
@end

@interface ACCMiddleware : NSObject <ACCMiddleware>
@property (nonatomic, copy, readonly) ACCActionHandler dispatcher;
@property (nonatomic, copy, readonly) ACCStateGetter stateGetter;
@property (nonatomic, copy, readonly, nullable) NSString *stateGetterKey;

+ (instancetype)middleware;

- (ACCAction *)handleAction:(ACCAction *)action next:(nonnull ACCActionHandler)next; // Override Point

// 发起一个新的Action
- (ACCAction * _Nullable)dispatch:(ACCAction *)action NS_REQUIRES_SUPER;
- (id _Nullable)getState;
@end

@interface ACCCompositeMiddleware : ACCMiddleware
@property (nonatomic, strong, readonly) NSArray<ACCMiddleware *> *middlewares;
+ (instancetype)middlewareWithMiddleawares:(NSArray <ACCMiddleware *> *)middlewares;
@end

@interface ACCCompositeMiddleware (Private)
- (NSArray *)bindChildMiddlewares:(NSArray *)middlewares;
@end


NS_ASSUME_NONNULL_END
