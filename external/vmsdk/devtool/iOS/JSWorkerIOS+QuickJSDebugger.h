//
//  JSWorkerIOS+QuickJSDebugger.h
//  vmsdk
//
//  Created by Huang Zongshan on 2022/9/27.
//
#ifndef VMSDKJSWORKERIOSQUICKJSDEBUGGER_HEADER_H
#define VMSDKJSWORKERIOSQUICKJSDEBUGGER_HEADER_H
#import "worker/iOS/js_worker_ios.h"

#define JS_ENGINE_QJS

@protocol VMSDKDebugInspectorClient;

@interface JsWorkerIOS (QuickJSDebugger)

- (void)registerDevtoolInspector:(id<VMSDKDebugInspectorClient>)client;
- (void)onWorkerDestroy;

@end

#endif  // VMSDKJSWORKERIOSQUICKJSDEBUGGER_HEADER_H
