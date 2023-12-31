#import "worker/iOS/js_worker_ios.h"

#include "worker/js_worker.h"
#include "worker_delegate_ios.h"

#include "VmsdkMonitor.h"
#include "VmsdkVersion.h"
#include "basic/iOS/cf_utils.h"
#include "basic/vmsdk_exception_common.h"
#include "jsb/iOS/vmsdk_module_manager_darwin.h"
#include "jsb/module/module_delegate_impl.h"
#include "jsb/runtime/js_runtime.h"
#include "jsb/runtime/napi_runtime_wraper.h"
#include "jsb/runtime/task_runner_manufacture.h"

@implementation JsWorkerIOS {
  std::atomic_bool is_running_;
  bool use_jscore_;
  bool is_multi_thread_;
  NSString *cache_path_;
  NSString *biz_name_;
  std::shared_ptr<vmsdk::worker::WorkerDelegateIOS> worker_delegate_;
  std::shared_ptr<vmsdk::worker::Worker> worker_;
  std::shared_ptr<vmsdk::piper::ModuleManagerDarwin> module_manager_;
  std::shared_ptr<vmsdk::piper::ModuleDelegateImpl> module_delegate_;
  std::shared_ptr<vmsdk::runtime::TaskRunnerManufacture> task_runner_manufacture_;
  std::shared_ptr<vmsdk::runtime::JSRuntime> js_runtime_;
  // Owner JsWorkerIOS self, promise JsWorkerIOS release at last on JSThread.
  JsWorkerIOS *js_worker_ios_;
}

- (instancetype)init {
  return [self init:false];
}

- (instancetype)init:(Boolean)useJSCore {
  return [self init:useJSCore param:nil];
}

- (instancetype _Nonnull)init:(Boolean)useJSCore param:(NSString *_Nullable)path {
  return [self init:useJSCore param:path isMutiThread:false];
}

- (instancetype _Nonnull)init:(Boolean)useJSCore
                        param:(NSString *_Nullable)path
                 isMutiThread:(Boolean)isMutiThread {
  return [self init:useJSCore param:path isMutiThread:isMutiThread biz_name:@"unknown_ios"];
}
- (void *_Nonnull)getTaskRunnerManufacture {
  return (void *)task_runner_manufacture_.get();
}
- (void *_Nonnull)getWorker {
  return (void *)worker_.get();
}

- (instancetype _Nonnull)init:(Boolean)useJSCore
                        param:(NSString *_Nullable)path
                 isMutiThread:(Boolean)isMutiThread
                     biz_name:(NSString *_Nullable)biz_name {
  self = [super init];
  is_running_ = false;
  js_worker_ios_ = self;
  if (isMutiThread) {
    // MutiThread Mode
    task_runner_manufacture_ = std::make_shared<vmsdk::runtime::TaskRunnerMultiThread>();
  } else {
    // SingleThread Mode
    task_runner_manufacture_ = vmsdk::runtime::TaskRunnerSingleton::GetInstance();
  }
  use_jscore_ = useJSCore;
  is_multi_thread_ = isMutiThread;

  biz_name_ = biz_name;
  module_manager_ = std::make_shared<vmsdk::piper::ModuleManagerDarwin>();
  if (path) cache_path_ = [path stringByAppendingString:@"/worker_code_cache.bin"];
  NSString *vmsdk_version = [VmsdkVersion versionString];
  [VmsdkMonitor monitorEventStatic:@"JsWorker"
                            metric:nil
                          category:@{
                            @"biz_name" : biz_name,
                            @"init_worker" : @true,
                            @"vmsdk_version" : vmsdk_version
                          }
                             extra:@{@"log" : @"jsworker init successfully"}];

  NSLog(@"JsWorker init success, vmsdk_version: %@ ", vmsdk_version);
  return self;
}

- (void)evaluateJavaScript:(NSString *)script {
  if (is_running_) {
    std::string src([script UTF8String]);
    worker_->evaluateJavaScript(src);
    NSLog(@"evaluate javascript going...");
  }
}

// Task will run & cancel at MessageLoop
// The un-runned Task will be removed before Worker terminate
// Can ensure thread safety
- (void)postOnJSRunner:(void (^)())runnable {
  if (is_running_ && js_runtime_) {
    js_runtime_->RunNowOrPostTask(vmsdk::general::Bind(
        [cb = runnable]() {
          @try {
            cb();
          } @catch (NSException *exception) {
            std::string msg(exception.reason ? [exception.reason UTF8String] : "unkonw");
          }
        },
        (uintptr_t)self));
  }
}

// DelayedTask will run & cancel at TimerTaskloop
// The un-runned DelayedTask will be removed before Worker terminate
// Cannot ensure the delayed_milliseconds accurate
// But can ensure thread safety
- (void)postOnJSRunnerDelay:(void (^)(void))runnable delayMilliseconds:(long)delayMilliseconds {
  if (is_running_ && js_runtime_ && worker_) {
    worker_->PostDelayedTask(
        vmsdk::general::Bind([cb = runnable]() {
          @try {
            cb();
          } @catch (NSException *exception) {
            std::string msg(exception.reason ? [exception.reason UTF8String] : "unkonw");
          }
        }),
        delayMilliseconds);
  }
}

- (void)setGlobalProperties:(NSDictionary *)props {
  if (is_running_ && js_runtime_) {
    js_runtime_->RunNowOrPostTask(vmsdk::general::Bind(
        [props = props, weak_runtime = std::weak_ptr<vmsdk::runtime::JSRuntime>(js_runtime_)]() {
          auto runtime_ptr = weak_runtime.lock();
          if (runtime_ptr && runtime_ptr->getRuntime()) {
            Napi::Env napi_env = runtime_ptr->getRuntime()->Env();
            Napi::HandleScope scp(napi_env);
            Napi::ContextScope contextScope(napi_env);
            Napi::Object global_obj = napi_env.Global();
            for (NSString *k in props) {
              global_obj.Set([k UTF8String],
                             vmsdk::piper::convertObjCObjectToJSIValue(napi_env, props[k]));
            }
          }
        },
        (uintptr_t)self));
  }
}

- (void)setContextName:(NSString *)name {
  if (is_running_ && js_runtime_) {
    js_runtime_->RunNowOrPostTask(vmsdk::general::Bind(
        [nameStr = std::string([name UTF8String]),
         weak_runtime = std::weak_ptr<vmsdk::runtime::JSRuntime>(js_runtime_)]() {
          auto runtime_ptr = weak_runtime.lock();
          if (runtime_ptr && runtime_ptr->getRuntime()) {
            runtime_ptr->getRuntime()->SetRtInfo(nameStr.c_str());
          }
        }));
  }
}

- (void)invokeJavaScriptModule:(NSString *_Nonnull)moduleName
                    methodName:(NSString *_Nonnull)methodName
                        params:(NSArray *_Nullable)params {
  [self postOnJSRunner:^{
    [self invokeJavaScriptModuleSync:moduleName methodName:methodName params:params];
  }];
}

- (id)invokeJavaScriptModuleSync:(NSString *_Nonnull)moduleName
                      methodName:(NSString *_Nonnull)methodName
                          params:(NSArray *_Nullable)params {
  if (is_running_ && js_runtime_ && js_runtime_->getRuntime()) {
    try {
      auto napi_env = js_runtime_->getRuntime()->Env();
      auto js_module = napi_env.Global().Get([moduleName UTF8String]);
      if (!js_module.IsUndefined() && js_module.IsObject()) {
        auto js_function = js_module.As<Napi::Object>().Get([methodName UTF8String]);
        if (!js_function.IsUndefined() && js_function.IsFunction()) {
          auto js_fun = js_function.As<Napi::Function>();
          size_t args_size = params == nil ? 0 : [params count];
          Napi::Array arr = vmsdk::piper::convertNSArrayToJSIArray(napi_env, params);
          std::vector<napi_value> values;
          for (size_t index = 0; index < args_size; index++) {
            values.push_back(arr.Get(index));
          }
          auto js_result = js_fun.Call(values);
          return vmsdk::piper::convertJSIValueToObjCObject(napi_env, js_result);
        } else {
          std::string msg = js_function.IsUndefined()
                                ? std::string([moduleName UTF8String]) + "." +
                                      [methodName UTF8String] + " undefined"
                                : std::string([moduleName UTF8String]) + "." +
                                      [methodName UTF8String] + " is no a function";
        }
      } else {
        std::string msg = js_module.IsUndefined()
                              ? std::string([moduleName UTF8String]) + " undefined"
                              : std::string([moduleName UTF8String]) + " is no an object";
      }
    } catch (NSException *exception) {  // TODO expose napi_exception
      std::string msg(exception.reason ? [exception.reason UTF8String] : "unkonw");
    }
  }
  return nil;
}

- (void)invokeJavaScriptFunction:(NSString *)methodName params:(NSArray *)params {
  [self postOnJSRunner:^{
    [self invokeJavaScriptFunctionSync:methodName params:params];
  }];
}

- (id)invokeJavaScriptFunctionSync:(NSString *)methodName params:(NSArray *)params {
  if (is_running_ && js_runtime_ && js_runtime_->getRuntime()) {
    try {
      auto napi_env = js_runtime_->getRuntime()->Env();
      auto js_function = napi_env.Global().Get([methodName UTF8String]);
      if (!js_function.IsUndefined() && js_function.IsFunction()) {
        auto js_fun = js_function.As<Napi::Function>();
        size_t args_size = params == nil ? 0 : [params count];
        Napi::Array arr = vmsdk::piper::convertNSArrayToJSIArray(napi_env, params);
        std::vector<napi_value> values;
        for (size_t index = 0; index < args_size; index++) {
          values.push_back(arr.Get(index));
        }
        auto js_result = js_fun.Call(values);
        return vmsdk::piper::convertJSIValueToObjCObject(napi_env, js_result);
      } else {
        std::string msg = js_function.IsUndefined()
                              ? std::string([methodName UTF8String]) + " undefined"
                              : std::string([methodName UTF8String]) + " is no a function";
      }
    } catch (NSException *exception) {  // TODO expose napi_exception
      std::string msg(exception.reason ? [exception.reason UTF8String] : "unkonw");
    }
  }
  return nil;
}

- (void)evaluateJavaScript:(NSString *_Nonnull)script param:(NSString *_Nullable)filename {
  if (is_running_) {
    std::string src([script UTF8String]);
    if (filename) {
      std::string name_([filename UTF8String]);
      worker_->evaluateJavaScript(src, name_);
    } else {
      worker_->evaluateJavaScript(src);
    }
  }
}

- (void)terminate {
  if (is_running_) {
    is_running_ = false;
    worker_->Terminate();

    if (js_runtime_) {
      js_runtime_->PostTask(vmsdk::general::Bind([self] {
        if (self) {
          self->module_delegate_->Terminate();
          self->module_delegate_ = nullptr;
          self->module_manager_ = nullptr;
          self->js_runtime_->RemoveTaskByGroupId((uintptr_t)self);
          self->js_runtime_ = nullptr;
          self->worker_ = nullptr;
          self->task_runner_manufacture_ = nullptr;
          self->worker_delegate_ = nullptr;
          // js_worker_ios_ should be released last
          self->js_worker_ios_ = nullptr;
        }
      }));
    }
  }
}

- (void)postMessage:(NSString *)msg {
  if (is_running_) {
    std::string message([msg UTF8String]);
    worker_->PostMessage(message);
    NSLog(@"posting message");
  }
}

- (void)onMessage:(NSString *)msg {
  // execute onMessage callback
  if (_onMessageCallback != NULL) {
    [_onMessageCallback handleMessage:msg];
  }
  NSLog(@"JsWorkerIOS onMessage was called.");
}

- (void)onError:(NSString *)msg {
  // execute onError callback
  if (_onErrorCallback != NULL) {
    [_onErrorCallback handleError:msg];
  }
  NSLog(@"JsWorkerIOS onError was called.");
}

#ifndef LARK_MINIAPP
- (void)setWorkerDelegate:(id<WorkerDelegate>)workerDelegate {
  _workerDelegate = workerDelegate;
  if (is_running_ && _workerDelegate != NULL) {
    worker_->registerDelegateFunction();
  }
}
#endif

- (NSString *)FetchJsWithUrlSync:(NSString *)url {
#ifndef LARK_MINIAPP
  if (_workerDelegate != NULL) {
    return [_workerDelegate fetchWithUrlSync:url];
  }
  NSLog(@"JsWorkerIOS FetchJsWithUrlSync was called url: %s",
        [url cStringUsingEncoding:[NSString defaultCStringEncoding]]);
#endif
  return @"";
}

- (void)Fetch:(NSString *_Nonnull)url
         param:(NSString *_Nonnull)param
      bodyData:(const void *_Nullable)bodyData
    bodyLength:(int)bodyLength
        delPtr:(void *_Nonnull)delPtr {
#ifndef LARK_MINIAPP
  NSLog(@"JsWorkerIOS Fetch was called url: %@, params: %@", url, param);
  NSDictionary *paramJson;
  if (!param.length) {
    paramJson = [[NSDictionary alloc] init];
  } else {
    NSData *paramData = [param dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    paramJson = [NSJSONSerialization JSONObjectWithData:paramData
                                                options:NSJSONReadingMutableContainers
                                                  error:&err];
    if (err) {
      NSLog(@"JsWorkerIOS fetch params convert to json failed");
      return;
    }
  }
  NSString *method = [paramJson objectForKey:@"method"] ? paramJson[@"method"] : @"GET";
  NSDictionary *_Nullable headers =
      [paramJson objectForKey:@"headers"] ? paramJson[@"headers"] : nil;
  NSData *_Nullable body = nil;
  if (bodyData) {
    body = [[NSData alloc] initWithBytes:bodyData length:bodyLength];
  } else {
    body = [paramJson objectForKey:@"body"]
               ? [paramJson[@"body"] dataUsingEncoding:NSUTF8StringEncoding]
               : nil;
  }

  RequestIOS *request = [[RequestIOS alloc] init:url method:method headers:headers body:body];
  if (_workerDelegate != NULL) {
    NetCallbackBlock netCallback =
        ^(NSError *_Nullable error, NSData *_Nullable body, ResponseIOS *_Nonnull response) {
          if (!self || ![self isRunning]) {
            return;
          }
          if (error) {
            [response Reject:self error:error delPtr:delPtr];
            return;
          }

          if (body) {
            [response Resolve:self body:body delPtr:delPtr];
            return;
          }

          // error and body both nil,default use error
          error = [NSError errorWithDomain:@"com.bytedance.vmsdk" code:-1 userInfo:nil];
          [response Reject:self error:error delPtr:delPtr];
        };

    [_workerDelegate loadAsync:request completion:netCallback];
  }
#endif
}

- (bool)isRunning {
  return is_running_;
}

- (void)initJSBridge {
  auto js_task_runner = task_runner_manufacture_->GetJSTaskRunner();
  // how to make an Objective-C object as an argument of c++ function.

  js_runtime_ =
      std::shared_ptr<vmsdk::runtime::JSRuntime>(new vmsdk::runtime::JSRuntime(js_task_runner));
  auto type = use_jscore_ ? vmsdk::runtime::JSCore : vmsdk::runtime::QuickJS;

  worker_delegate_ = std::make_shared<vmsdk::worker::WorkerDelegateIOS>(self, js_runtime_);
  module_delegate_ = std::make_shared<vmsdk::piper::ModuleDelegateImpl>(worker_delegate_);

  // create worker
  worker_ = std::make_shared<vmsdk::worker::Worker>(js_task_runner, js_runtime_, worker_delegate_,
                                                    [biz_name_ UTF8String]);

  is_running_ = true;  // must after create worker

  js_runtime_->RunNowOrPostTask(vmsdk::general::Bind([self, type] {
    if (self && self->is_running_ && self->module_manager_ && self->worker_ &&
        self->module_delegate_ && self->js_runtime_) {
      self->js_runtime_->Init(self->module_manager_, type, self->is_multi_thread_);
      self->worker_->setRunning(true);

      self->module_manager_->initBindingPtr(self->module_manager_, self->module_delegate_);
      self->js_runtime_->RegisterNativeModuleProxy();
    }
  }));

  worker_->Init();

#ifdef ENABLE_CODECACHE
  if (cache_path_) {
    std::string path([cache_path_ UTF8String]);
    NSLog(@"JsWorker trying to initCodeCache at: %s", path.c_str());
    worker_->InitCodeCache(std::move(path));
  }
#endif  // ENABLE_CODECACHE
  NSLog(@"JsWorker initJSBridge success, useJSCore: %d ", use_jscore_);
}

- (void)registerModule:(Class<JSModule>)module {
  module_manager_->registerModule(module);
  NSLog(@"JsWorker registerModule success");
}

- (void)registerModule:(Class<JSModule>)module param:(id)param {
  module_manager_->registerModule(module, param);
}

- (NSString *_Nullable)getCacheFilePath {
  return cache_path_;
}

- (void)dealloc {
  is_running_ = false;
  NSLog(@"-------- deleting JsWorkerIOS --------");
}

@end
