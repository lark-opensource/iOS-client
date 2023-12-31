// Copyright 2013 The Flutter Authors. All rights reserved.
// Copyright 2022 The Lynx Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef THIRD_PARTY_FLUTTER_FML_THREAD_H_
#define THIRD_PARTY_FLUTTER_FML_THREAD_H_

#include <atomic>
#include <functional>
#include <memory>
#include <string>
#include <thread>

#include "base/base_export.h"
#include "third_party/fml/macros.h"
#include "third_party/fml/task_runner.h"

namespace lynx {
namespace fml {

class Thread {
 public:
  /// Valid values for priority of Thread.
  enum class ThreadPriority : int {
    /// Suitable for threads that shouldn't disrupt high priority work.
    LOW,
    /// Default priority level.
    NORMAL,
    /// Suitable for threads which execute for runtime engine、layout
    /// engine、template render.
    HIGH,
  };

  /// The ThreadConfig is the thread info include thread name, thread priority.
  struct ThreadConfig {
    ThreadConfig(const std::string& name, ThreadPriority priority)
        : name(name), priority(priority) {}

    explicit ThreadConfig(const std::string& name)
        : ThreadConfig(name, ThreadPriority::NORMAL) {}

    ThreadConfig() : ThreadConfig("", ThreadPriority::NORMAL) {}

    std::string name;
    ThreadPriority priority;
  };

  using ThreadConfigSetter = std::function<void(const ThreadConfig&)>;

  BASE_EXPORT_FOR_DEVTOOL explicit Thread(const std::string& name = "");

  explicit Thread(const ThreadConfig& config);

  explicit Thread(const ThreadConfigSetter& setter,
                  const ThreadConfig& config = ThreadConfig());

  BASE_EXPORT_FOR_DEVTOOL ~Thread();

  BASE_EXPORT_FOR_DEVTOOL fml::RefPtr<fml::TaskRunner> GetTaskRunner() const;

  void Join();

  static void SetCurrentThreadName(const ThreadConfig& config);

 private:
  std::unique_ptr<std::thread> thread_;

  fml::RefPtr<fml::TaskRunner> task_runner_;

  std::atomic_bool joined_;

  FML_DISALLOW_COPY_AND_ASSIGN(Thread);
};

}  // namespace fml
}  // namespace lynx

#endif  // THIRD_PARTY_FLUTTER_FML_THREAD_H_
