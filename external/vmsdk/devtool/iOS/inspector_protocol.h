//
//  inspector_protocol.h
//  TikTok
//
//  Created by zhaoyusong on 2022/6/23.
//

#ifndef inspector_protocol_h
#define inspector_protocol_h

#import <Foundation/Foundation.h>

@protocol VMSDKDebugInspector <NSObject>

/**
 * Dispatch a cdp message to the engine.
 * @param message the cdp message.
 */
- (void)dispatchMessage:(NSString *)message;

@end

@protocol VMSDKDebugInspectorClient <NSObject>

/**
 * Bind the inspector of engine to the bridge, after that we can dispatch cdp message to the
 * target engine by the InspectorBridge.
 * @param inspector the inspector of engine
 */
- (void)bindInspector:(id<VMSDKDebugInspector>)inspector;

/**
 * Send cdp message from engines to devtool.
 * @param message the cdp message
 */
- (void)sendResponseMessage:(NSString *)message;

/**
 * Destroy the inspector client.
 * */
- (void)destroy;

@end

#endif /* inspector_protocol_h */
