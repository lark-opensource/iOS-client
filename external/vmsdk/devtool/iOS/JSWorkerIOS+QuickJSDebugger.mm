//
//  JSWorkerIOS+QuickJSDebugger.m
//  vmsdk
//
//  Created by Huang Zongshan on 2022/9/27.
//

#import "JSWorkerIOS+QuickJSDebugger.h"
#include "ObjcVMSDKDebugIC.h"  // for use vmsdk::devtool::VMSDKDebugICBase
#import "devtool/iOS/inspector_protocol.h"
#import "devtool/inspector_factory_impl.h"
#include "worker/js_worker.h"  // Worker

@implementation JsWorkerIOS (QuickJSDebugger)
id<VMSDKDebugInspectorClient> debug_client_;

- (void)registerDevtoolInspector:(id<VMSDKDebugInspectorClient>)client {
  NSLog(@"JSWorker registerDevtoolInspector start");
  static dispatch_once_t token;
  dispatch_once(&token, ^{
    auto *instance = vmsdk::devtool::InspectorFactoryImpl::GetInstance();
    vmsdk::devtool::InspectorFactory::SetInstance(instance);
  });

  debug_client_ = client;
  vmsdk::worker::Worker *jsWorker = static_cast<vmsdk::worker::Worker *>([self getWorker]);
  jsWorker->InitInspector(std::make_shared<vmsdk::devtool::iOS::VMSDKDebugIC>(client));
}

- (void)onWorkerDestroy {
  [debug_client_ destroy];
}

@end
