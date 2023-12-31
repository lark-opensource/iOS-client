//
//  ACCModuleStore.h
//  Pods
//
//  Created by leo on 2019/12/18.
//

#import <Foundation/Foundation.h>
#import "ACCMiddleware.h"
#import "ACCReducer.h"
#import "ACCAction.h"
#import "ACCState.h"

NS_ASSUME_NONNULL_BEGIN

// refer: https://github.com/microsoft/redux-dynamic-modules

typedef NS_ENUM(int, ACCReduxModuleActionType) {
    ACCReduxModuleActionTypeSeed, // 可以用来进行State的初始化
};
@interface ACCReduxModuleAction : ACCAction
@end

@interface ACCReduxModule : NSObject
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *key;
@property (nonatomic, strong) NSObject *state;
@property (nonatomic, strong) NSDictionary <NSString *,ACCReducer *>*reducerMap;
@property (nonatomic, strong) NSArray <id<ACCMiddleware>>*middlewares;
@end

NS_ASSUME_NONNULL_END
