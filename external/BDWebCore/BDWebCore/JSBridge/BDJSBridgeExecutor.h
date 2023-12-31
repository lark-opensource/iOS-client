//
//  BDJSBridgeExecutor.h
//  BDJSBridgeCore
//
//  Created by 李琢鹏 on 2020/1/5.
//

#import "BDJSBridgeMessage.h"
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NSInteger BDJSBridgeExecutorPriority;

static const BDJSBridgeExecutorPriority BDJSBridgeExecutorPriorityHigh = 1000;
static const BDJSBridgeExecutorPriority BDJSBridgeExecutorPriorityDefault = 100;
static const BDJSBridgeExecutorPriority BDJSBridgeExecutorPriorityLow = 0;

typedef BOOL BDJSBridgeExecutorFlowShouldContinue;


@protocol BDJSBridgeExecutor <NSObject>


@required
@property(nonatomic, weak) WKWebView *sourceWebView;

@optional
- (BDJSBridgeExecutorFlowShouldContinue)invokeBridgeWithMessage:(BDJSBridgeMessage *)message callback:(BDJSBridgeCallback)callback isForced:(BOOL)isForced;
- (BDJSBridgeExecutorFlowShouldContinue)willCallbackBridgeWithMessage:(BDJSBridgeMessage *)message callback:(BDJSBridgeCallback)callback;
- (BDJSBridgeExecutorPriority)priority;


@end

NS_ASSUME_NONNULL_END
