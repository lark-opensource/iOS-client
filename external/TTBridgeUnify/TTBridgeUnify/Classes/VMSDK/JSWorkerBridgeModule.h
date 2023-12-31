//
//  JSWorkerBridgeModule.h
//  TTBridgeUnify
//
//  Created by bytedance on 2021/10/14.
//

#import <Foundation/Foundation.h>
#import <vmsdk/jsb/iOS/framework/JSModule.h>
#import <vmsdk/worker/iOS/js_worker_ios.h>

NS_ASSUME_NONNULL_BEGIN

@class JSWorkerBridge;

@interface JsWorkerIOS (Bridge)

@property (nonatomic, strong, readonly)JSWorkerBridge *bridge;

@end

@interface JSWorkerBridgeModule : NSObject <JSModule>

@end

NS_ASSUME_NONNULL_END
