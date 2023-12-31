// Copyright 2020 The Lynx Authors. All rights reserved.

#ifndef LYNX_JSBRIDGE_APPBRAND_JS_THREAD_PROVIDER_H_
#define LYNX_JSBRIDGE_APPBRAND_JS_THREAD_PROVIDER_H_

#include <stdint.h>

#include <memory>

#ifndef PROVIDER_EXPORT
#ifdef NO_EXPORT
#define PROVIDER_EXPORT
#else
#define PROVIDER_EXPORT __attribute__((visibility("default")))
#endif
#endif

namespace provider {
namespace piper {

class PROVIDER_EXPORT Task {
 public:
  virtual ~Task() = default;
  virtual void Run() = 0;
  virtual int64_t Id() = 0;

 protected:
  Task() = default;
};

class PROVIDER_EXPORT JSThreadProvider {
 public:
  virtual ~JSThreadProvider() = default;
  virtual void OnAttachThread(const char* group_id) = 0;
  virtual void OnDetachThread(const char* group_id) = 0;
  /**
   * you should delete task after call Run() method
   */
  virtual bool OnPostTaskDelay(Task* task, int delayed_time,
                               const char* group_id) = 0;
  /**
   * you should delete task after call Run() method
   */
  virtual bool OnPostTask(Task* task, const char* group_id) = 0;
  /**
   * id: js task id
   */
  virtual bool OnRemoveTask(int64_t id, const char* group_id) = 0;

 protected:
  JSThreadProvider() {}
};

class PROVIDER_EXPORT JSThreadProviderGenerator {
 public:
  JSThreadProviderGenerator() = delete;

  static JSThreadProvider& Provider();
  static void SetProvider(JSThreadProvider* provider);

 protected:
  // Fixme(chenpeihan): set provider when lynx env init (avoid multithreading
  // get/set)
  static JSThreadProvider* provider_;
};
}  // namespace piper
}  // namespace provider

#undef PROVIDER_EXPORT
#endif  // LYNX_JSBRIDGE_APPBRAND_JS_THREAD_PROVIDER_H_
