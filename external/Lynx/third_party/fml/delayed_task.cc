// Copyright 2013 The Flutter Authors. All rights reserved.
// Copyright 2022 The Lynx Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include "third_party/fml/delayed_task.h"

namespace lynx {
namespace fml {

DelayedTask::DelayedTask(size_t order, base::closure task,
                         fml::TimePoint target_time,
                         fml::TaskSourceGrade task_source_grade)
    : order_(order),
      task_(std::move(task)),
      target_time_(target_time),
      task_source_grade_(task_source_grade) {}

DelayedTask::~DelayedTask() = default;

base::closure DelayedTask::GetTask() const { return std::move(task_); }

fml::TimePoint DelayedTask::GetTargetTime() const { return target_time_; }

fml::TaskSourceGrade DelayedTask::GetTaskSourceGrade() const {
  return task_source_grade_;
}

bool DelayedTask::operator>(const DelayedTask& other) const {
  if (target_time_ == other.target_time_) {
    return order_ > other.order_;
  }
  return target_time_ > other.target_time_;
}

}  // namespace fml
}  // namespace lynx
