//
//  BDPJSContext.h
//  Timor
//
//  Created by CsoWhy on 2018/10/14.
//

#import <Foundation/Foundation.h>

#import <OPFoundation/BDPUtils.h>
#import <OPFoundation/BDPUniqueID.h>
#import <OPPluginManagerAdapter/BDPJSBridge.h>
#import <OPJSEngine/BDPMultiDelegateProxy.h>
#import <OPJSEngine/BDPJSRunningThread.h>
#import <OPJSEngine/BDPJSRunningThreadAsyncDispatchQueue.h>
#import "OPMicroAppJSRuntimeDelegate.h"
#import "OPMicroAppJSRuntimeProtocol.h"

#define kBDPArrayBufferParam @"_bdp_arraybuffer_param_"


#pragma mark - BDPJSRuntime

/**
 * 小程序逻辑层执行所在JS虚拟机、JSContext及相应调用方法的封装。2.10.0中会实现JSContext异步分线程执行，目前版本在主线程执行。
 * 1.对js提供调用native的基本接口，通过向jscontext注入ttJSCore对象，提供invoke、publish等方法。2.invoke用于调用native端静态插件和动态插件。
 * 3.publish用于向每个BDPAppPage轮流发一遍消息。
 * 4.fireEvent接口用于Native向JSC层发消息，当isFireEventReady标志位未设置时，native的调用都会先排入队列，JSC和Webview的js基础库都加载成功后再循环执行。
 *
 * 具体加载时序图见：https://bytedance.feishu.cn/space/doc/doccnUnYJ4KNWZd6rjqjXd#
 */
