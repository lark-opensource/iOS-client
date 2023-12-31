// Copyright 2013 The Flutter Authors. All rights reserved.
// Copyright 2022 The Lynx Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef THIRD_PARTY_FLUTTER_FML_CONCURRENT_MESSAGE_LOOP_H_
#define THIRD_PARTY_FLUTTER_FML_CONCURRENT_MESSAGE_LOOP_H_

#include <condition_variable>
#include <map>
#include <queue>
#include <thread>

#include "base/closure.h"
#include "third_party/fml/macros.h"
#include "third_party/fml/task_runner.h"

namespace lynx {
namespace fml {

class ConcurrentTaskRunner;

class ConcurrentMessageLoop
    : public std::enable_shared_from_this<ConcurrentMessageLoop> {
 public:
  static std::shared_ptr<ConcurrentMessageLoop> Create(
      size_t worker_count = std::thread::hardware_concurrency());

  ~ConcurrentMessageLoop();

  size_t GetWorkerCount() const;

  std::shared_ptr<ConcurrentTaskRunner> GetTaskRunner();

  void Terminate();

  void PostTaskToAllWorkers(base::closure task);

 private:
  friend ConcurrentTaskRunner;

  size_t worker_count_ = 0;
  std::vector<std::thread> workers_;
  std::mutex tasks_mutex_;
  std::condition_variable tasks_condition_;
  std::queue<base::closure> tasks_;
  std::vector<std::thread::id> worker_thread_ids_;
  std::map<std::thread::id, std::vector<base::closure>> thread_tasks_;
  bool shutdown_ = false;

  explicit ConcurrentMessageLoop(size_t worker_count);

  void WorkerMain();

  void PostTask(base::closure task);

  bool HasThreadTasksLocked() const;

  std::vector<base::closure> GetThreadTasksLocked();

  FML_DISALLOW_COPY_AND_ASSIGN(ConcurrentMessageLoop);
};

class ConcurrentTaskRunner : public BasicTaskRunner {
 public:
  explicit ConcurrentTaskRunner(std::weak_ptr<ConcurrentMessageLoop> weak_loop);

  virtual ~ConcurrentTaskRunner();

  void PostTask(base::closure task) override;

 private:
  friend ConcurrentMessageLoop;

  std::weak_ptr<ConcurrentMessageLoop> weak_loop_;

  FML_DISALLOW_COPY_AND_ASSIGN(ConcurrentTaskRunner);
};

}  // namespace fml
}  // namespace lynx

#endif  // THIRD_PARTY_FLUTTER_FML_CONCURRENT_MESSAGE_LOOP_H_
