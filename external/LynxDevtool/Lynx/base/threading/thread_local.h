#ifndef LYNX_BASE_THREADING_THREAD_LOCAL_H_
#define LYNX_BASE_THREADING_THREAD_LOCAL_H_

#if !defined(OS_WIN)
#include <pthread.h>
#endif

#if defined(OS_IOS) && defined(__i386__)
#include <cstddef>
#endif

namespace lynx {

#if defined(OS_IOS) && defined(__i386__)
// just use for ios i386 which not support thread_local
#define lynx_thread_local(T) lynx::base::ThreadLocal<T>
#else
#define lynx_thread_local(T) thread_local T
#endif

namespace base {

// iOS i386 not support thread_local,
// need implement instead
#if defined(OS_IOS) && defined(__i386__)
template <typename T>
class ThreadLocal {
  using Constructor = T* (*)();

  using Destructor = void (*)(void*);

 public:
  explicit ThreadLocal(
      Constructor constructor = [] { return new T; },
      Destructor destructor = [](void* impl) { delete static_cast<T*>(impl); })
      : constructor_(constructor), destructor_(destructor) {
    pthread_key_create(&key_, destructor_);
    pthread_setspecific(key_, constructor());
  }

  ~ThreadLocal() { pthread_key_delete(key_); }

  // need support ThreadLocal<> var = nullptr,
  // cannot add explicit, just like char* constructor
  // for std::string
  ThreadLocal(std::nullptr_t ptr) {
    constructor_ = [] { return new T; };
    destructor_ = [](void* impl) { delete static_cast<T*>(impl); };
    pthread_key_create(&key_, destructor_);
    pthread_setspecific(key_, new T(nullptr));
  }

  operator T&() { return *Get(); };

  T& operator->() { return *Get(); }

  ThreadLocal& operator=(const T& value) {
    auto impl = pthread_getspecific(key_);
    if (impl != nullptr) {
      destructor_(static_cast<T*>(impl));
    }
    pthread_setspecific(key_, new T(value));
    return *this;
  }

 private:
  T* Get() {
    auto impl = pthread_getspecific(key_);
    if (impl == nullptr) {
      impl = constructor_();
      pthread_setspecific(key_, impl);
    }
    return static_cast<T*>(impl);
  };

  Constructor constructor_;

  Destructor destructor_;

  pthread_key_t key_;
};
#endif

}  // namespace base
}  // namespace lynx

#endif  // LYNX_BASE_THREADING_THREAD_LOCAL_H_
