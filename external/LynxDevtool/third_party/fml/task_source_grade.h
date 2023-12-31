// Copyright 2013 The Flutter Authors. All rights reserved.
// Copyright 2022 The Lynx Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef THIRD_PARTY_FLUTTER_FML_TASK_SOURCE_GRADE_H_
#define THIRD_PARTY_FLUTTER_FML_TASK_SOURCE_GRADE_H_

namespace lynx {
namespace fml {

/**
 * Categories of work dispatched to `MessageLoopTaskQueues` dispatcher. By
 * specifying the `TaskSourceGrade`, you indicate the task's importance to the
 * dispatcher.
 */
enum class TaskSourceGrade {
  /// This `TaskSourceGrade` indicates that a task is critical to user
  /// interaction.
  kUserInteraction,
  /// The absence of a specialized `TaskSourceGrade`.
  kUnspecified,
  /// This `TaskSourceGrade` indicates that a task is urgent to execute.
  kEmergency,
  /// This `TaskSourceGrade` indicates that a task just executes when idle.
  kIdle,
};

}  // namespace fml
}  // namespace lynx

#endif  // THIRD_PARTY_FLUTTER_FML_TASK_SOURCE_GRADE_H_
