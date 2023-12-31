#include "jsb/runtime/js_runtime.h"
#include "jsb/runtime/napi_runtime_wraper.h"
#include "jsb/runtime/task_runner_manufacture.h"
#import "worker/iOS/js_worker_ios.h"
#include "worker/net/response_delegate.h"

@implementation ResponseIOS

- (instancetype _Nonnull)init:(NSInteger)statusCode
                          url:(NSString *_Nonnull)url
                     mimeType:(NSString *_Nonnull)mimeType
                      headers:(NSDictionary *_Nonnull)headers {
  self = [super init];
  _statusCode = statusCode;
  _ok = statusCode >= 200 && statusCode <= 299;
  _url = [NSURL URLWithString:url];
  _MIMEType = mimeType;
  _headers = headers;
  return self;
}

- (Napi::Value)jsObjectFromResponse:(Napi::Env)napiEnv
                               body:(NSData *_Nonnull)body
                             worker:(JsWorkerIOS *_Nonnull)worker {
  Napi::EscapableHandleScope scp(napiEnv);
  Napi::ContextScope contextScope(napiEnv);

  Napi::Object obj = Napi::Object::New(napiEnv);
  obj.Set("url", Napi::String::New(napiEnv, [[_url absoluteString] UTF8String]));
  obj.Set("status", Napi::Number::New(napiEnv, _statusCode));
  obj.Set("ok", Napi::Boolean::New(napiEnv, _ok));

  Napi::Object jsHeaders = Napi::Object::New(napiEnv);
  for (NSString *key in _headers) {
    jsHeaders.Set([key UTF8String], Napi::String::New(napiEnv, [_headers[key] UTF8String]));
  }
  obj.Set("headers", jsHeaders);

  obj.Set("body", Napi::ArrayBuffer::New(napiEnv, (void *)(body.bytes), body.length));
  obj.Set("json", Napi::Function::New(napiEnv, vmsdk::net::ResponseDelegate::json, "json",
                                      (void *)[worker getWorker]));
  obj.Set("text", Napi::Function::New(napiEnv, vmsdk::net::ResponseDelegate::text, "text",
                                      (void *)[worker getWorker]));
  return scp.Escape(obj);
}

- (void)Resolve:(JsWorkerIOS *_Nonnull)worker
           body:(NSData *_Nonnull)body
         delPtr:(void *_Nonnull)delPtr {
  if (worker != nil && ![worker isRunning]) {
    return;
  }
  auto task_runner_manufacture_ =
      reinterpret_cast<vmsdk::runtime::TaskRunnerManufacture *>([worker getTaskRunnerManufacture]);
  auto js_task_runner = task_runner_manufacture_->GetJSTaskRunner();

  js_task_runner->PostTask(vmsdk::general::Bind([self, delPtr, body, worker] {
    auto resDel = reinterpret_cast<vmsdk::net::ResponseDelegate *>(delPtr);
    if (worker != nil && [worker isRunning]) {
      auto napiEnv = resDel->Env();
      Napi::HandleScope scp(napiEnv);
      Napi::ContextScope contextScope(napiEnv);
      Napi::Value jsResponse = [self jsObjectFromResponse:resDel->Env() body:body worker:worker];
      resDel->resolve(jsResponse);
    }
  }));
}
- (void)Reject:(JsWorkerIOS *_Nonnull)worker
         error:(NSError *_Nonnull)error
        delPtr:(void *_Nonnull)delPtr {
  if (worker != nil && ![worker isRunning]) {
    return;
  }
  auto task_runner_manufacture_ =
      reinterpret_cast<vmsdk::runtime::TaskRunnerManufacture *>([worker getTaskRunnerManufacture]);
  auto js_task_runner = task_runner_manufacture_->GetJSTaskRunner();

  js_task_runner->PostTask(vmsdk::general::Bind([delPtr, error, worker] {
    auto resDel = reinterpret_cast<vmsdk::net::ResponseDelegate *>(delPtr);
    if (worker != nil && [worker isRunning]) {
      auto napiEnv = resDel->Env();
      Napi::HandleScope scp(napiEnv);
      Napi::ContextScope contextScope(napiEnv);
      Napi::Value jsError = Napi::Error::New(napiEnv, [error.localizedDescription UTF8String]);
      resDel->reject(jsError);
    }
  }));
}
@end
