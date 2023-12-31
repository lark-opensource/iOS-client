#ifndef VMSDK_BASE_THREAD_COMPLETION_EVENT_H_
#define VMSDK_BASE_THREAD_COMPLETION_EVENT_H_

#include "basic/threading/condition.h"
#include "basic/threading/lock.h"

namespace vmsdk {
namespace general {
class CompletionEvent {
 public:
  CompletionEvent() : condition_(), lock_(), signaled_(false) {
    pthread_cond_init(&condition_, NULL);
  }
  ~CompletionEvent() { pthread_cond_destroy(&condition_); }

  void Wait() {
    AutoLock lock(lock_);
    if (!signaled_) {
      pthread_cond_wait(&condition_, &lock_.mutex_);
    }
  }

  void Signal() {
    AutoLock lock(lock_);
    signaled_ = true;
    pthread_cond_signal(&condition_);
  }

 private:
  pthread_cond_t condition_;
  Lock lock_;
  bool signaled_;
};
}  // namespace general
}  // namespace vmsdk

#endif
