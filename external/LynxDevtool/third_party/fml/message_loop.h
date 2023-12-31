// Copyright 2013 The Flutter Authors. All rights reserved.
// Copyright 2022 The Lynx Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef THIRD_PARTY_FLUTTER_FML_MESSAGE_LOOP_H_
#define THIRD_PARTY_FLUTTER_FML_MESSAGE_LOOP_H_

#include "third_party/fml/macros.h"
#include "third_party/fml/task_runner.h"

namespace lynx {
namespace fml {

class TaskRunner;
class MessageLoopImpl;

/// An event loop associated with a thread.
///
/// This class is the generic front-end to the MessageLoop, differences in
/// implementation based on the running platform are in the subclasses of
/// flutter::MessageLoopImpl (ex flutter::MessageLoopAndroid).
///
/// For scheduling events on the message loop see flutter::TaskRunner.
///
/// \see fml::TaskRunner
/// \see fml::MessageLoopImpl
/// \see fml::MessageLoopTaskQueues
/// \see fml::Wakeable
class MessageLoop {
 public:
  static MessageLoop& GetCurrent();

  void Run();

  void Terminate();

  fml::RefPtr<fml::TaskRunner> GetTaskRunner() const;

  // Exposed for the embedder shell which allows clients to poll for events
  // instead of dedicating a thread to the message loop.
  void RunExpiredTasksNow();

  static void EnsureInitializedForCurrentThread();

  /// Returns true if \p EnsureInitializedForCurrentThread has been called on
  /// this thread already.
  static bool IsInitializedForCurrentThread();

  ~MessageLoop();

  /// Gets the unique identifier for the TaskQueue associated with the current
  /// thread.
  /// \see fml::MessageLoopTaskQueues
  static TaskQueueId GetCurrentTaskQueueId();

 private:
  friend class TaskRunner;
  friend class MessageLoopImpl;

  fml::RefPtr<MessageLoopImpl> loop_;
  fml::RefPtr<fml::TaskRunner> task_runner_;

  MessageLoop();

  fml::RefPtr<MessageLoopImpl> GetLoopImpl() const;

  FML_DISALLOW_COPY_AND_ASSIGN(MessageLoop);
};

}  // namespace fml
}  // namespace lynx

#endif  // THIRD_PARTY_FLUTTER_FML_MESSAGE_LOOP_H_
