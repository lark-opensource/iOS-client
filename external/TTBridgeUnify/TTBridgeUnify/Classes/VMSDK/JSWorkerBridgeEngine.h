//
//  JSWorkerBridgeEngine.h
//  TTBridgeUnify
//
//  Created by bytedance on 2021/10/14.
//

#import <Foundation/Foundation.h>
#import <TTBridgeUnify/TTBridgeEngine.h>
#import <vmsdk/worker/iOS/js_worker_ios.h>

NS_ASSUME_NONNULL_BEGIN

@class IESBridgeEngine;

@class JSWorkerBridgeEngine;

@interface JsWorkerIOS (TTBridge)

@property (nonatomic, strong, readonly) JSWorkerBridgeEngine *tt_engine;

- (void)tt_installBridgeEngine:(JSWorkerBridgeEngine *)bridge;
- (void)tt_installIESBridgeEngine:(IESBridgeEngine *)bridge;

@end

@interface JSWorkerBridgeEngine : NSObject <TTBridgeEngine>

@property (nonatomic, strong)IESBridgeEngine *iesBridgeEngine;

- (instancetype)initWithWebViewBridgeCompatibility:(BOOL)compatibility;

- (void)installOnWorker:(JsWorkerIOS *)worker;

@end

NS_ASSUME_NONNULL_END
