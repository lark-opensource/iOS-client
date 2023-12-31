// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef KRYPTON_EFFECT_EXCUTOR_H
#define KRYPTON_EFFECT_EXCUTOR_H

#include <condition_variable>
#include <functional>
#include <future>
#include <memory>
#include <mutex>
#include <queue>
#include <stdexcept>
#include <thread>
#include <vector>

namespace lynx {
namespace canvas {

class EffectExecutor {
 public:
  EffectExecutor(size_t num_threads = 1);

  template <class F, class... Args>
  auto enqueue(F &&f, Args &&...args)
      -> std::future<typename std::result_of<F(Args...)>::type>;

  ~EffectExecutor();

  // stop the executor and unstarted task will be cancelled
  std::queue<std::function<void()>> shutdownNow();

 private:
  // need to keep track of threads so we can join them
  std::vector<std::thread> workers;
  // the task queue
  std::queue<std::function<void()>> tasks;

  // synchronization
  std::mutex queue_mutex;
  std::condition_variable condition;
  bool stop;
};

// the constructor just launches some amount of workers
inline EffectExecutor::EffectExecutor(size_t num_threads) : stop(false) {
  for (size_t i = 0; i < num_threads; ++i)
    workers.emplace_back([this] {
      for (;;) {
        std::function<void()> task;

        {
          std::unique_lock<std::mutex> lock(this->queue_mutex);
          this->condition.wait(
              lock, [this] { return this->stop || !this->tasks.empty(); });
          if (this->stop && this->tasks.empty()) return;
          task = std::move(this->tasks.front());
          this->tasks.pop();
        }

        task();
      }
    });
}

// add new work item to the pool
template <class F, class... Args>
auto EffectExecutor::enqueue(F &&f, Args &&...args)
    -> std::future<typename std::result_of<F(Args...)>::type> {
  using return_type = typename std::result_of<F(Args...)>::type;

  auto task = std::make_shared<std::packaged_task<return_type()>>(
      std::bind(std::forward<F>(f), std::forward<Args>(args)...));

  std::future<return_type> res = task->get_future();
  {
    std::unique_lock<std::mutex> lock(queue_mutex);
    // don't allow enqueueing after stopping the pool
    if (stop) return std::future<void>();
    tasks.emplace([task]() { (*task)(); });
  }
  condition.notify_one();
  return res;
}

// the destructor joins all threads
inline EffectExecutor::~EffectExecutor() {
  {
    std::lock_guard<std::mutex> lock(queue_mutex);
    stop = true;
  }
  condition.notify_all();
  for (std::thread &worker : workers) worker.join();
}

inline std::queue<std::function<void()>> EffectExecutor::shutdownNow() {
  std::lock_guard<std::mutex> lock(queue_mutex);
  stop = true;
  std::queue<std::function<void()>> empty;
  std::swap(tasks, empty);
  return empty;
}

}  // namespace canvas
}  // namespace lynx

#endif  // KRYPTON_EFFECT_EXCUTOR_H
