//
//  BDXBridgeMethod.h
//  BDXBridge
//
//  Created by Lizhen Hu on 2020/5/28.
//

#import <Foundation/Foundation.h>
#import "BDXBridgeModel.h"
#import "BDXBridgeStatus.h"
#import "BDXBridgeMacros.h"
#import "BDXBridgeContext.h"
#import "BDXBridgeDefinitions.h"
#import "BDXBridgeContainerProtocol.h"

NS_ASSUME_NONNULL_BEGIN

/// The completion handler to be invoked once the bridge method done executing.
/// @param resultModel A result model passed by the bridge method implementor.
/// @param status An status object indicating the bridge method executing status, passing nil indicates success. Note that the status object should be created with `+[BDXBridgeStatus statusWithStatusCode:message:]`.
typedef void(^BDXBridgeMethodCompletionHandler)(BDXBridgeModel * _Nullable resultModel, BDXBridgeStatus * _Nullable status);

@interface BDXBridgeMethod : NSObject

/// A set of engine types ORed by multiple `BDXBridgeEngineType`s.
@property (nonatomic, assign, readonly) BDXBridgeEngineType engineTypes;

/// The name of bridge method.
@property (nonatomic, copy, readonly) NSString *methodName;

/// The auth type of bridge method, callers in a lower auth group are not allowed to call this bridge method.
@property (nonatomic, assign, readonly) BDXBridgeAuthType authType;

/// A development method will only be registered in development mode.
@property (nonatomic, assign, readonly) BOOL isDevelopmentMethod;

/// Arbitrary data which can be accessed by each invocation of the call method.
@property (nonatomic, strong, readonly) BDXBridgeContext *context;

/// The class of the param model.
@property (nonatomic, strong, readonly, nullable) Class paramModelClass;

/// The class of the result model.
@property (nonatomic, strong, readonly, nullable) Class resultModelClass;

- (instancetype)initWithContext:(BDXBridgeContext *)context;

/// Invoked by the bridge engine, this is the place where the method's implementation code lives.
/// @param paramModel A param model passed by the caller.
/// @param completionHandler A completion handler that should be invoked explicitly after executing the bridge method.
/// @note If the completionHandler is retained by the implementor, it should be released once done executing. Since internally we check whether the completionHandler is invoked once and only once when it is released.
- (void)callWithParamModel:(nullable BDXBridgeModel *)paramModel completionHandler:(BDXBridgeMethodCompletionHandler)completionHandler;

@end

NS_ASSUME_NONNULL_END
